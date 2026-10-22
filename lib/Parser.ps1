# Reads one meeting note: title, date, attendees and raw action items.
# Throws with a plain-English reason when the note can't be used.

# "Priya to send the quote by Friday" -> owner "Priya", rest "send the quote by Friday"
function Split-ItemText([string]$Text) {
    if ($Text -match '^@([\w.]+):?\s+(.+)$') {
        return @{ OwnerText = $Matches[1]; Rest = $Matches[2] }
    }
    if ($Text -match '^(.{1,40}?)\s+to\s+(.+)$' -and @($Matches[1] -split '\s+').Count -le 5) {
        return @{ OwnerText = $Matches[1]; Rest = $Matches[2] }
    }
    return @{ OwnerText = ''; Rest = $Text }
}

function New-RawItem([string]$Text, [bool]$Done, [int]$Line) {
    $split = Split-ItemText $Text.Trim()
    return @{ OwnerText = $split.OwnerText; Text = $split.Rest; Done = $Done; Line = $Line }
}

function Get-TableCells([string]$Line) {
    $cells = @($Line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
    return $cells
}

function Read-NoteFile([string]$Path) {
    $name = [IO.Path]::GetFileName($Path)
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0) { throw 'file is empty' }
    if ($bytes -contains 0) { throw 'file contains binary data' }
    try {
        $text = (New-Object Text.UTF8Encoding($false, $true)).GetString($bytes)
    } catch {
        throw 'file is not readable text (binary data or unknown encoding)'
    }
    $text = $text.TrimStart([char]0xFEFF)
    if (-not $text.Trim()) { throw 'file is empty' }
    if ($text -match '[\x01-\x08\x0E-\x1F�]') { throw 'file contains garbled or binary characters' }

    # HTML comments are hidden text, never real actions.
    $text = [regex]::Replace($text, '(?s)<!--.*?-->', '')
    $lines = $text -split '\r?\n'

    $meta = @{}
    $start = 0
    # Optional front matter block: --- / date: ... / attendees: [...] / ---
    if ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---') {
        for ($j = 1; $j -lt $lines.Count; $j++) {
            if ($lines[$j].Trim() -eq '---') { $start = $j + 1; break }
            if ($lines[$j] -match '^\s*([A-Za-z]+)\s*:\s*(.*)$') { $meta[$Matches[1].ToLower()] = $Matches[2].Trim() }
        }
    }

    $items = New-Object System.Collections.ArrayList
    $inCode = $false
    $table = $null
    for ($i = $start; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        $lineNo = $i + 1
        if ($line -match '^\s*(```|~~~)') { $inCode = -not $inCode; continue }
        if ($inCode) { continue }
        if ($line -match '^\s*>') { continue }   # quoted text is someone else's words

        if (-not $meta.title -and $line -match '^#\s+(?:Meeting:\s*)?(.+)$') { $meta.title = $Matches[1].Trim(); continue }
        if (-not $meta.date -and $line -match '^\s*Date\s*:\s*(.+)$') { $meta.date = $Matches[1].Trim(); continue }
        if (-not $meta.attendees -and $line -match '^\s*Attendees\s*:\s*(.+)$') { $meta.attendees = $Matches[1].Trim(); continue }

        if ($line -match '^\s*[-*+]\s+\[([ xX])\]\s+(.+?)\s*$') {
            [void]$items.Add((New-RawItem $Matches[2] ($Matches[1] -ne ' ') $lineNo))
            continue
        }
        if ($line -match '^\s*ACTION\s*:\s*(.+?)\s*$') {
            [void]$items.Add((New-RawItem $Matches[1] $false $lineNo))
            continue
        }
        if ($line.Trim().StartsWith('|')) {
            $cells = Get-TableCells $line
            if (-not $table) {
                $owner = [array]::FindIndex([string[]]$cells, [Predicate[string]] { param($c) $c -match '^owner$' })
                $task = [array]::FindIndex([string[]]$cells, [Predicate[string]] { param($c) $c -match '^(action|task)' })
                $due = [array]::FindIndex([string[]]$cells, [Predicate[string]] { param($c) $c -match '^due' })
                if ($owner -ge 0 -and $task -ge 0) { $table = @{ Owner = $owner; Task = $task; Due = $due } }
            } elseif ($line -notmatch '^\s*\|[\s|:-]+\|?\s*$' -and $cells.Count -gt $table.Task) {
                $text = $cells[$table.Task]
                if ($table.Due -ge 0 -and $cells.Count -gt $table.Due -and $cells[$table.Due]) { $text += " by $($cells[$table.Due])" }
                [void]$items.Add(@{ OwnerText = $cells[$table.Owner]; Text = $text; Done = $false; Line = $lineNo })
            }
            continue
        }
        $table = $null
    }

    $warnings = New-Object System.Collections.ArrayList
    $date = ConvertFrom-MeetingDate $meta.date
    if (-not $date) {
        $what = 'no meeting date found'
        if ($meta.date) { $what = "meeting date '$($meta.date)' not understood" }
        if ($name -match '^(\d{4}-\d{2}-\d{2})' -and ($fromName = ConvertFrom-IsoDate $Matches[1])) {
            $date = $fromName
            [void]$warnings.Add("$what; used the date in the file name ($($Matches[1]))")
        } else {
            throw "$what, and the file name has no date"
        }
    }

    $attendees = @()
    if ($meta.attendees) {
        $attendees = @($meta.attendees.Trim('[', ']', ' ') -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    if ($attendees.Count -eq 0) { [void]$warnings.Add('no attendee list; first names matched against everyone in the other notes') }
    if ($items.Count -eq 0) { [void]$warnings.Add('no action items found') }

    $title = $meta.title
    if (-not $title) { $title = [IO.Path]::GetFileNameWithoutExtension($name) }

    return [pscustomobject]@{
        File      = $name
        Title     = $title
        Date      = $date
        Attendees = $attendees
        Items     = @($items)
        Warnings  = @($warnings)
    }
}
