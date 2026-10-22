# The commands: ingest, list, done, assign, followup.

. (Join-Path $PSScriptRoot 'Dates.ps1')
. (Join-Path $PSScriptRoot 'Owners.ps1')
. (Join-Path $PSScriptRoot 'Parser.ps1')
. (Join-Path $PSScriptRoot 'Store.ps1')

$script:Usage = @'
actiontrack - track action items from meeting notes

  actiontrack ingest <folder>
  actiontrack list [--owner <name>] [--status open|done|overdue] [--due-before <yyyy-mm-dd>] [--today <yyyy-mm-dd>]
  actiontrack done <id>
  actiontrack assign <id> <owner>
  actiontrack followup <owner> [--dry-run] [--today <yyyy-mm-dd>]

"Today" comes from --today, else the ACTIONTRACK_TODAY variable, else the computer's date.
'@

function Write-Line([string]$Text = '', [string]$Color) {
    if ($Color -and -not $env:NO_COLOR) { Write-Host $Text -ForegroundColor $Color } else { Write-Host $Text }
}

# Splits "--owner Priya --dry-run x" into options and positional arguments.
function Get-CommandOptions([object[]]$ArgList, [string[]]$ValueOptions, [string[]]$FlagOptions) {
    $opts = @{}
    $positional = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $ArgList.Count; $i++) {
        $a = [string]$ArgList[$i]
        if ($a -match '^--([a-z-]+)(?:=(.*))?$') {
            $name = $Matches[1]; $inline = $Matches[2]
            if ($FlagOptions -contains $name) { $opts[$name] = $true }
            elseif ($ValueOptions -contains $name) {
                if ($null -ne $inline) { $opts[$name] = $inline }
                elseif ($i + 1 -lt $ArgList.Count) { $i++; $opts[$name] = [string]$ArgList[$i] }
                else { throw "--$name needs a value" }
            } else { throw "unknown option --$name" }
        } else { [void]$positional.Add($a) }
    }
    return @{ Options = $opts; Args = @($positional) }
}

function Get-Today($Options) {
    $text = $Options['today']
    if (-not $text) { $text = $env:ACTIONTRACK_TODAY }
    if (-not $text) { return (Get-Date).Date }
    $date = ConvertFrom-IsoDate $text
    if (-not $date) { throw "today must look like 2026-10-22, got '$text'" }
    return $date
}

function Invoke-Ingest([string[]]$Positional) {
    if ($Positional.Count -ne 1) { throw 'usage: actiontrack ingest <folder>' }
    $folder = $Positional[0]
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw "folder not found: $folder" }

    $notes = New-Object System.Collections.ArrayList
    $skipped = New-Object System.Collections.ArrayList
    $ignored = New-Object System.Collections.ArrayList
    foreach ($file in Get-ChildItem -LiteralPath $folder -File | Sort-Object Name) {
        if ($file.Extension -ne '.md') { [void]$ignored.Add($file.Name); continue }
        try { [void]$notes.Add((Read-NoteFile $file.FullName)) }
        catch { [void]$skipped.Add("$($file.Name): $($_.Exception.Message)") }
    }

    $everyone = @($notes | ForEach-Object { $_.Attendees } | Sort-Object -Unique)
    $store = Read-Store
    $counts = @{ new = 0; updated = 0; same = 0 }
    foreach ($note in $notes | Sort-Object Date, File) {
        $meetingDate = ConvertTo-IsoDate $note.Date
        $meeting = "$($note.Title), $meetingDate"
        foreach ($raw in $note.Items) {
            $split = Split-DueDate $raw.Text $note.Date
            foreach ($name in Split-OwnerText $raw.OwnerText) {
                $owner = Resolve-Owner $name $note.Attendees $everyone
                $result = Add-Mention $store $owner $split.Task $split.Due $split.DueRaw $raw.Done $meetingDate $meeting $note.File
                $counts[$result]++
            }
        }
    }
    Save-Store $store
    $needsFix = @($store.Items | Where-Object { Test-NeedsOwnerFix $_.owner } |
        ForEach-Object { "[$($_.id)] $($_.owner): $($_.task)  ($($_.sources[-1]))" } | Sort-Object)

    Write-Line "Read $($notes.Count) notes from $folder."
    Write-Line "Items: $($counts.new) new, $($counts.updated) updated, $($counts.same) unchanged. Total stored: $($store.Items.Count)."
    if ($skipped.Count) {
        Write-Line ''
        Write-Line "Skipped $($skipped.Count) file(s) that could not be read:" 'Yellow'
        $skipped | ForEach-Object { Write-Line "  - $_" 'Yellow' }
    }
    if ($ignored.Count) {
        Write-Line ''
        Write-Line "Ignored $($ignored.Count) file(s) that are not .md: $($ignored -join ', ')"
    }
    $warned = @($notes | Where-Object { $_.Warnings.Count })
    if ($warned.Count) {
        Write-Line ''
        Write-Line 'Warnings:' 'Yellow'
        foreach ($note in $warned) { foreach ($w in $note.Warnings) { Write-Line "  - $($note.File): $w" 'Yellow' } }
    }
    if ($needsFix.Count) {
        Write-Line ''
        Write-Line "$($needsFix.Count) item(s) have no clear owner and are never emailed (fix with: actiontrack assign <id> <owner>):" 'Yellow'
        $needsFix | ForEach-Object { Write-Line "  - $_" 'Yellow' }
    }
    return 0
}

function Invoke-List([string[]]$Positional, $Options) {
    if ($Positional.Count) { throw "list takes no arguments, got: $($Positional -join ' ')" }
    $today = Get-Today $Options
    $status = $Options['status']
    if ($status -and $status -notin @('open', 'done', 'overdue')) { throw '--status must be open, done or overdue' }
    $dueBefore = $null
    if ($Options['due-before']) {
        $dueBefore = ConvertFrom-IsoDate $Options['due-before']
        if (-not $dueBefore) { throw "--due-before must look like 2026-10-22, got '$($Options['due-before'])'" }
    }

    $store = Read-Store
    $items = @($store.Items | Where-Object {
        $item = $_
        $keep = $true
        if ($Options['owner'] -and $item.owner -notlike "*$($Options['owner'])*") { $keep = $false }
        if ($status -eq 'open' -and $item.status -ne 'open') { $keep = $false }
        if ($status -eq 'done' -and $item.status -ne 'done') { $keep = $false }
        if ($status -eq 'overdue' -and -not (Test-Overdue $item $today)) { $keep = $false }
        if ($dueBefore -and (-not $item.due -or (ConvertFrom-IsoDate $item.due) -ge $dueBefore)) { $keep = $false }
        $keep
    } | Sort-Object @{ Expression = { if ($_.due) { $_.due } else { '9999' } } }, @{ Expression = { $_.id } })

    if (-not $items.Count) { Write-Line 'No items match.'; return 0 }
    $format = '{0,4}  {1,-8}  {2,-10}  {3,-18}  {4}'
    Write-Line ($format -f 'ID', 'STATUS', 'DUE', 'OWNER', 'TASK  [latest note]')
    $overdue = 0
    foreach ($item in $items) {
        $label = $item.status; $color = $null
        if (Test-Overdue $item $today) { $label = 'OVERDUE'; $color = 'Red'; $overdue++ }
        elseif ($item.status -eq 'done') { $color = 'DarkGray' }
        $due = $item.due; if (-not $due) { $due = '-' }
        $source = $item.sources[-1]
        if ($item.sources.Count -gt 1) { $source += " +$($item.sources.Count - 1) more" }
        Write-Line ($format -f $item.id, $label, $due, $item.owner, "$($item.task)  [$source]") $color
    }
    Write-Line ''
    Write-Line "$($items.Count) item(s), $overdue overdue as of $(ConvertTo-IsoDate $today)."
    return 0
}

function Invoke-Done([string[]]$Positional, $Options) {
    if ($Positional.Count -ne 1 -or $Positional[0] -notmatch '^\d+$') { throw 'usage: actiontrack done <id>  (id is a number from `actiontrack list`)' }
    $today = Get-Today $Options
    $store = Read-Store
    $item = Find-Item $store ([int]$Positional[0])
    if (-not $item) { throw "no item with id $($Positional[0])" }
    if ($item.status -eq 'done' -and $item.done_by -eq 'manual') {
        Write-Line "Item $($item.id) was already marked done."
        return 0
    }
    $item.status = 'done'; $item.done_by = 'manual'; $item.done_on = ConvertTo-IsoDate $today
    Save-Store $store
    Write-Line "Marked done: [$($item.id)] $($item.owner): $($item.task)" 'Green'
    return 0
}

function Invoke-Assign([string[]]$Positional) {
    if ($Positional.Count -ne 2 -or $Positional[0] -notmatch '^\d+$') { throw 'usage: actiontrack assign <id> "<owner full name>"' }
    $store = Read-Store
    $item = Find-Item $store ([int]$Positional[0])
    if (-not $item) { throw "no item with id $($Positional[0])" }
    $owner = Resolve-KnownOwner $store $Positional[1]
    $old = $item.owner
    Set-ItemOwner $store $item $owner
    Save-Store $store
    Write-Line "Assigned [$($item.id)] $($item.task): $old -> $owner" 'Green'
    return 0
}

# "Priya Nair", "priya nair" or "Priya" (if only one Priya has items).
function Resolve-KnownOwner($Store, [string]$Name) {
    $owners = @($Store.Items | ForEach-Object { $_.owner } | Where-Object { -not (Test-NeedsOwnerFix $_) } | Sort-Object -Unique)
    $exact = @($owners | Where-Object { $_ -ieq $Name })
    if ($exact.Count) { return $exact[0] }
    $byFirst = @($owners | Where-Object { ($_ -split '\s+')[0] -ieq $Name })
    if ($byFirst.Count -eq 1) { return $byFirst[0] }
    if ($byFirst.Count -gt 1) { throw "'$Name' matches $($byFirst -join ' and '). Use the full name in quotes." }
    throw "'$Name' is not a known owner. Owners: $($owners -join ', ')"
}

function Get-EmailAddress([string]$Owner) {
    $path = Join-Path (Get-Location) 'people.json'
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    try { $people = [IO.File]::ReadAllText($path, $script:Utf8NoBom) | ConvertFrom-Json }
    catch { throw "could not read people.json (is it valid JSON?): $($_.Exception.Message)" }
    foreach ($prop in $people.PSObject.Properties) { if ($prop.Name -ieq $Owner) { return [string]$prop.Value } }
    return $null
}

function Format-ItemLine($Item) {
    $task = $Item.task.Substring(0, 1).ToUpper() + $Item.task.Substring(1)
    $due = 'no due date set'
    if ($Item.due) { $due = 'due ' + (Format-FriendlyDate (ConvertFrom-IsoDate $Item.due)) }
    return "  - $task ($due; from $($Item.last_meeting))"
}

function Invoke-Followup([string[]]$Positional, $Options) {
    if ($Positional.Count -ne 1) { throw 'usage: actiontrack followup <owner> [--dry-run]   (quote names with spaces)' }
    $today = Get-Today $Options
    $store = Read-Store
    $owner = Resolve-KnownOwner $store $Positional[0]

    $open = @($store.Items | Where-Object { $_.owner -eq $owner -and $_.status -eq 'open' } |
        Sort-Object @{ Expression = { if ($_.due) { $_.due } else { '9999' } } }, @{ Expression = { $_.id } })
    $first = ($owner -split '\s+')[0]
    $unclear = @($store.Items | Where-Object { $_.owner -eq "$first (ambiguous)" -and $_.status -eq 'open' })
    if ($unclear.Count) {
        Write-Line "Note: $($unclear.Count) open item(s) belong to '$first (ambiguous)' and are not in this email." 'Yellow'
    }
    if (-not $open.Count) { Write-Line "$owner has no open items. No draft written."; return 0 }

    $overdue = @($open | Where-Object { Test-Overdue $_ $today })
    $pending = @($open | Where-Object { -not (Test-Overdue $_ $today) })
    $to = Get-EmailAddress $owner
    if (-not $to) { Write-Line "Note: no email for '$owner' in people.json; 'to' is left empty." 'Yellow'; $to = '' }

    $subject = "Follow-up: $($open.Count) open action item(s)"
    if ($overdue.Count) { $subject += ", $($overdue.Count) overdue" }
    $body = New-Object System.Collections.ArrayList
    [void]$body.Add("Hi $first,")
    [void]$body.Add('')
    [void]$body.Add('Following up on the action items from our recent meetings that are still open.')
    if ($overdue.Count) {
        [void]$body.Add(''); [void]$body.Add('Overdue:')
        $overdue | ForEach-Object { [void]$body.Add((Format-ItemLine $_)) }
    }
    if ($pending.Count) {
        [void]$body.Add(''); [void]$body.Add('Still open:')
        $pending | ForEach-Object { [void]$body.Add((Format-ItemLine $_)) }
    }
    [void]$body.Add('')
    [void]$body.Add('Could you reply with a quick status on each, or let me know if any are already done?')
    [void]$body.Add('')
    [void]$body.Add('Thanks')
    $bodyText = $body -join "`n"

    Write-Line "To:      $to"
    Write-Line "Subject: $subject"
    Write-Line ''
    Write-Line $bodyText
    Write-Line ''
    if ($Options['dry-run']) { Write-Line '(dry run: nothing written, nothing sent)'; return 0 }

    $draft = [ordered]@{
        owner = $owner; to = $to; subject = $subject; body = $bodyText
        item_ids = @($open | ForEach-Object { $_.id }); as_of = ConvertTo-IsoDate $today
    }
    $dir = Join-Path (Get-Location) 'drafts'
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir) }
    $slug = ($owner.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    $path = Join-Path $dir "$slug.json"
    [IO.File]::WriteAllText($path, (ConvertTo-Json -InputObject $draft -Depth 4), $script:Utf8NoBom)
    Write-Line "Draft saved to drafts/$slug.json. Nothing was sent." 'Green'
    Write-Line 'Next: ask Claude to create the Gmail draft from this file (Gmail "create draft" only).'
    return 0
}

# Runs one command and returns an exit code. Never throws.
function Invoke-ActionTrack([object[]]$ArgList) {
    try {
        if (-not $ArgList -or $ArgList.Count -eq 0 -or $ArgList[0] -in @('help', '--help', '-h')) {
            Write-Host $script:Usage
            return 0
        }
        $command = [string]$ArgList[0]
        $rest = @()
        if ($ArgList.Count -gt 1) { $rest = $ArgList[1..($ArgList.Count - 1)] }
        switch ($command) {
            'ingest' {
                $parsed = Get-CommandOptions $rest @() @()
                return Invoke-Ingest $parsed.Args
            }
            'list' {
                $parsed = Get-CommandOptions $rest @('owner', 'status', 'due-before', 'today') @()
                return Invoke-List $parsed.Args $parsed.Options
            }
            'done' {
                $parsed = Get-CommandOptions $rest @('today') @()
                return Invoke-Done $parsed.Args $parsed.Options
            }
            'assign' {
                $parsed = Get-CommandOptions $rest @() @()
                return Invoke-Assign $parsed.Args
            }
            'followup' {
                $parsed = Get-CommandOptions $rest @('today') @('dry-run')
                return Invoke-Followup $parsed.Args $parsed.Options
            }
            default { throw "unknown command '$command'. Run 'actiontrack help'." }
        }
    } catch {
        Write-Line "Error: $($_.Exception.Message)" 'Red'
        return 1
    }
}
