# Saves action items in data.json and merges repeats of the same item.
# Overdue is never stored: it is worked out from the due date each time.

$script:Utf8NoBom = New-Object Text.UTF8Encoding($false)

function Get-DataPath {
    if ($env:ACTIONTRACK_DATA) { return $env:ACTIONTRACK_DATA }
    return (Join-Path (Get-Location) 'data.json')
}

function Get-ItemKey([string]$Owner, [string]$TaskKey) { "$($Owner.ToLowerInvariant())|$TaskKey" }

function Read-Store {
    $path = Get-DataPath
    $store = @{ Path = $path; NextId = 1; Items = New-Object System.Collections.ArrayList; Index = @{} }
    if (-not (Test-Path -LiteralPath $path)) { return $store }
    try {
        $json = [IO.File]::ReadAllText($path, $script:Utf8NoBom) | ConvertFrom-Json
    } catch {
        throw "could not read $path (is it valid JSON?): $($_.Exception.Message)"
    }
    $store.NextId = [int]$json.next_id
    foreach ($obj in @($json.items)) {
        if (-not $obj) { continue }
        $item = [ordered]@{}
        foreach ($prop in $obj.PSObject.Properties) { $item[$prop.Name] = $prop.Value }
        $item.id = [int]$item.id
        $item.sources = @($item.sources)
        [void]$store.Items.Add($item)
        $store.Index[(Get-ItemKey $item.owner $item.task_key)] = $item
        # Reassigned items are still found under the owner the notes use.
        if ($item.original_owner) { $store.Index[(Get-ItemKey $item.original_owner $item.task_key)] = $item }
    }
    return $store
}

function Save-Store($Store) {
    $data = [ordered]@{ next_id = $Store.NextId; items = @($Store.Items) }
    $json = ConvertTo-Json -InputObject $data -Depth 6
    $tmp = "$($Store.Path).tmp"
    [IO.File]::WriteAllText($tmp, $json, $script:Utf8NoBom)
    Move-Item -LiteralPath $tmp -Destination $Store.Path -Force
}

function Find-Item($Store, [int]$Id) {
    foreach ($item in $Store.Items) { if ($item.id -eq $Id) { return $item } }
    return $null
}

# Records one mention of an item in one meeting. Notes must be fed in date order.
# Rules: latest stated due date wins; a [x] closes the item; a later open mention
# reopens an item closed by an older note; a manual `done` is never reopened.
# Returns 'new', 'updated' or 'same'.
function Add-Mention($Store, [string]$Owner, [string]$Task, $Due, [string]$DueRaw,
        [bool]$Done, [string]$MeetingDate, [string]$Meeting, [string]$Source) {
    $taskKey = Get-TaskKey $Task
    $key = Get-ItemKey $Owner $taskKey
    $dueIso = $null
    if ($Due) { $dueIso = ConvertTo-IsoDate $Due }

    $item = $Store.Index[$key]
    if (-not $item) {
        $item = [ordered]@{
            id = $Store.NextId; owner = $Owner; task = $Task; task_key = $taskKey
            due = $dueIso; due_raw = $DueRaw; due_set_on = $null
            status = 'open'; done_by = $null; done_on = $null
            sources = @($Source); first_seen = $MeetingDate; last_seen = $MeetingDate; last_meeting = $Meeting
        }
        if ($dueIso) { $item.due_set_on = $MeetingDate }
        if ($Done) { $item.status = 'done'; $item.done_by = 'note'; $item.done_on = $MeetingDate }
        $Store.NextId++
        [void]$Store.Items.Add($item)
        $Store.Index[$key] = $item
        return 'new'
    }

    $before = ConvertTo-Json -InputObject $item -Depth 4 -Compress
    if ($item.sources -notcontains $Source) { $item.sources = @($item.sources) + $Source }
    if ([string]::CompareOrdinal($MeetingDate, $item.last_seen) -ge 0) {
        $item.last_seen = $MeetingDate; $item.last_meeting = $Meeting; $item.task = $Task
    }
    if ($dueIso -and (-not $item.due_set_on -or [string]::CompareOrdinal($MeetingDate, $item.due_set_on) -ge 0)) {
        $item.due = $dueIso; $item.due_raw = $DueRaw; $item.due_set_on = $MeetingDate
    }
    if ($item.done_by -ne 'manual') {
        if ($Done -and $item.status -ne 'done') {
            $item.status = 'done'; $item.done_by = 'note'; $item.done_on = $MeetingDate
        } elseif (-not $Done -and $item.status -eq 'done' -and [string]::CompareOrdinal($MeetingDate, $item.done_on) -gt 0) {
            $item.status = 'open'; $item.done_by = $null; $item.done_on = $null
        }
    }
    if ($before -eq (ConvertTo-Json -InputObject $item -Depth 4 -Compress)) { return 'same' }
    return 'updated'
}

# Gives an item a new owner. Later ingests still match it by the owner the notes use.
function Set-ItemOwner($Store, $Item, [string]$Owner) {
    $existing = $Store.Index[(Get-ItemKey $Owner $Item.task_key)]
    if ($existing -and $existing.id -ne $Item.id) {
        throw "$Owner already has this task as item $($existing.id). Mark item $($Item.id) done instead."
    }
    if (-not $Item.original_owner) { $Item.original_owner = $Item.owner }
    $Item.owner = $Owner
    $Store.Index[(Get-ItemKey $Owner $Item.task_key)] = $Item
}

function Test-Overdue($Item, [datetime]$Today) {
    if ($Item.status -ne 'open' -or -not $Item.due) { return $false }
    return ((ConvertFrom-IsoDate $Item.due) -lt $Today)
}
