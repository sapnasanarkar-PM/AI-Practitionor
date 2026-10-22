# Automatic checks. Run:  powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-Tests.ps1
$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'lib\Commands.ps1')

$script:Failed = 0
$script:Passed = 0
function Assert-Equal($Expected, $Actual, [string]$Name) {
    if ("$Expected" -ceq "$Actual") { $script:Passed++ }
    else { $script:Failed++; Write-Host "FAIL: $Name`n  expected: $Expected`n  actual:   $Actual" -ForegroundColor Red }
}
function Get-Due([string]$Text, [string]$Meeting) {
    $r = Split-DueDate $Text (ConvertFrom-IsoDate $Meeting)
    if ($r.Due) { return "$(ConvertTo-IsoDate $r.Due) | $($r.Task)" }
    return "none | $($r.Task)"
}

# --- Due dates (2026-09-01 is a Tuesday) ---
Assert-Equal '2026-09-04 | send the quote' (Get-Due 'send the quote by Friday' '2026-09-01') 'weekday'
Assert-Equal '2026-09-11 | x' (Get-Due 'x by Friday' '2026-09-04') 'same weekday means next week'
Assert-Equal '2026-09-02 | x' (Get-Due 'x by tomorrow' '2026-09-01') 'tomorrow'
Assert-Equal '2026-09-22 | write the postmortem' (Get-Due 'write the postmortem by EOD tomorrow' '2026-09-21') 'EOD tomorrow'
Assert-Equal '2026-10-08 | x' (Get-Due 'x by EOD' '2026-10-08') 'EOD'
Assert-Equal '2026-09-11 | draft plan' (Get-Due 'draft plan by end of next week' '2026-09-03') 'end of next week'
Assert-Equal '2026-09-30 | collect quotes' (Get-Due 'collect quotes by end of month' '2026-09-14') 'end of month'
Assert-Equal '2026-10-13 | start SSO spike' (Get-Due 'start SSO spike by next Tuesday' '2026-10-05') 'next weekday'
Assert-Equal '2026-10-03 | finalise targets' (Get-Due 'finalise targets by Oct 3rd' '2026-09-30') 'month day ordinal'
Assert-Equal '2026-09-10 | export invoices' (Get-Due 'export invoices by 10 Sep' '2026-09-03') 'day month'
Assert-Equal '2026-09-16 | finalise copy' (Get-Due 'finalise copy by Wed 16 Sep' '2026-09-14') 'weekday + date'
Assert-Equal '2026-10-10 | schedule cutover' (Get-Due 'schedule cutover for Saturday 10 Oct' '2026-09-29') 'for weekday + date'
Assert-Equal '2026-10-15 | propose rotation' (Get-Due 'propose rotation by mid-October' '2026-09-30') 'mid-month'
Assert-Equal '2026-11-30 | schedule the QBR' (Get-Due 'schedule the QBR for November' '2026-10-14') 'month only'
Assert-Equal '2026-10-15 | run the customer survey' (Get-Due 'run the customer survey, results due 15 October' '2026-09-30') 'results due'
Assert-Equal '2026-10-09 | freeze edits' (Get-Due 'freeze edits from 9 Oct' '2026-09-29') 'from date'
Assert-Equal "2026-10-09 | cut costs by 10% $([char]0x2014) proposal" (Get-Due "cut costs by 10% $([char]0x2014) proposal by 2026-10-09" '2026-10-02') '10% is not a date'
Assert-Equal '2026-09-11 | send revised quote to Acme' (Get-Due "send revised quote to Acme $([char]0x2014) by Friday" '2026-09-08') 'dash before due'
Assert-Equal '2026-10-01 | circulate the summary' (Get-Due 'circulate the summary tomorrow' '2026-09-30') 'bare tomorrow'
Assert-Equal 'none | snapshot the DB before cutover' (Get-Due 'snapshot the DB before cutover' '2026-09-03') 'no date'
Assert-Equal '2027-01-05 | x' (Get-Due 'x by 5 Jan' '2026-12-20') 'year rolls over'
Assert-Equal '2026-09-14' (ConvertTo-IsoDate (ConvertFrom-MeetingDate 'Monday, 14 September 2026')) 'meeting date long form'
Assert-Equal '' "$(ConvertFrom-MeetingDate 'sometime last week')" 'meeting date nonsense'

# --- Owners ---
$everyone = 'Priya Nair', 'Priya Shah', 'Rahul Mehta', 'Rahul Verma', 'Anita Desai', 'Lena Fischer'
Assert-Equal 'Priya Nair' (Resolve-Owner 'Priya N.' @('Priya Nair', 'Priya Shah') $everyone) 'initial picks the right Priya'
Assert-Equal 'Priya (ambiguous)' (Resolve-Owner 'Priya' @('Priya Nair', 'Priya Shah') $everyone) 'two Priyas in the room'
Assert-Equal 'Rahul Mehta' (Resolve-Owner 'Rahul' @('Rahul Mehta', 'Anita Desai') $everyone) 'only one Rahul in the room'
Assert-Equal 'Rahul (ambiguous)' (Resolve-Owner 'Rahul' @() $everyone) 'no attendee list, two Rahuls known'
Assert-Equal 'Anita Desai' (Resolve-Owner 'anita' @('Anita Desai') $everyone) '@anita'
Assert-Equal 'unassigned' (Resolve-Owner 'Everyone' @() $everyone) 'group owner'
Assert-Equal 'Anita|Rahul' ((Split-OwnerText 'Anita & Rahul') -join '|') 'two owners'
Assert-Equal 'Lena' ((Split-OwnerText 'Lena (with Priya)') -join '|') 'helper in brackets'
Assert-Equal (Get-TaskKey 'Send revised quote to Acme.') (Get-TaskKey 'send the revised quote to Acme') 'task key ignores the/punctuation'

# --- Full run on the sample notes ---
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("actiontrack-test-" + [guid]::NewGuid())
[void](New-Item -ItemType Directory -Path $tmp)
$env:ACTIONTRACK_DATA = Join-Path $tmp 'data.json'
$env:ACTIONTRACK_TODAY = '2026-10-22'
Push-Location $tmp
try {
    function Find-Task([string]$Owner, [string]$Task) {
        # leading comma keeps a one-item result as a list
        , @((Read-Store).Items | Where-Object { $_.owner -eq $Owner -and $_.task -eq $Task })
    }
    $notes = Join-Path $root 'notes'
    Assert-Equal 0 (Invoke-ActionTrack @('ingest', $notes) 6>$null) 'ingest succeeds'
    $store = Read-Store
    $count = $store.Items.Count

    Assert-Equal 1 (Find-Task 'Priya Nair' 'send the revised quote to Acme').Count 'duplicate quote item merged'
    Assert-Equal 'done' (Find-Task 'Priya Nair' 'send the revised quote to Acme')[0].status 'later [x] closes it'
    Assert-Equal '2026-09-24' (Find-Task 'Anita Desai' 'share updated wireframes')[0].due 'latest due date wins'
    Assert-Equal '' "$((Find-Task 'Karan Joshi' 'refund affected customers')[0].due)" 'quoted line ignored'
    Assert-Equal 0 @($store.Items | Where-Object { $_.task -like '*remediate*' -or $_.task -like '*hardware tokens*' }).Count 'code block and HTML comment ignored'
    Assert-Equal 1 (Find-Task 'Priya (ambiguous)' 'sign off the cutover checklist').Count 'ambiguous Priya'
    Assert-Equal 1 (Find-Task 'Anita Desai' 'Refresh the brand kit').Count 'table row read'
    Assert-Equal 1 (Find-Task 'Karan Joshi' 'circulate the offsite summary').Count 'ACTION: line read'
    Assert-Equal 1 (Find-Task 'Meera Iyer' 'chase Orbit Labs').Count 'file-name date fallback'
    Assert-Equal $true (Test-Overdue (Find-Task 'Priya Nair' 'prepare the renewal one-pager')[0] (ConvertFrom-IsoDate '2026-10-22')) 'overdue at run time'
    Assert-Equal $false (Test-Overdue (Find-Task 'Priya Nair' 'prepare the renewal one-pager')[0] (ConvertFrom-IsoDate '2026-10-01')) 'not overdue earlier'

    # manual done survives re-ingest, and re-ingest makes no duplicates
    $id = (Find-Task 'Priya Nair' 'prepare the renewal one-pager')[0].id
    Assert-Equal 0 (Invoke-ActionTrack @('done', "$id") 6>$null) 'done succeeds'
    Assert-Equal 0 (Invoke-ActionTrack @('ingest', $notes) 6>$null) 'second ingest succeeds'
    Assert-Equal $count (Read-Store).Items.Count 're-ingest adds nothing'
    Assert-Equal 'manual' (Find-Task 'Priya Nair' 'prepare the renewal one-pager')[0].done_by 'manual done not reopened'

    # followup
    Assert-Equal 1 (Invoke-ActionTrack @('followup', 'Priya') 6>$null) 'ambiguous first name refused'
    Assert-Equal 0 (Invoke-ActionTrack @('followup', 'Priya Nair', '--dry-run') 6>$null) 'dry run succeeds'
    Assert-Equal $false (Test-Path (Join-Path $tmp 'drafts')) 'dry run writes nothing'
    '{ "Priya Nair": "priya@example.com" }' | Set-Content (Join-Path $tmp 'people.json')
    Assert-Equal 0 (Invoke-ActionTrack @('followup', 'priya nair') 6>$null) 'followup succeeds'
    $draft = Get-Content (Join-Path $tmp 'drafts\priya-nair.json') -Raw | ConvertFrom-Json
    Assert-Equal 'priya@example.com' $draft.to 'draft has email'
    Assert-Equal $true ($draft.body -like '*Collect beta feedback from Acme*') 'draft lists open item'
    Assert-Equal $false ($draft.body -like '*renewal one-pager*') 'draft skips done item'

    # bad input never crashes
    Assert-Equal 1 (Invoke-ActionTrack @('done', '9999') 6>$null) 'unknown id'
    Assert-Equal 1 (Invoke-ActionTrack @('list', '--status', 'late') 6>$null) 'bad status'
    Assert-Equal 1 (Invoke-ActionTrack @('list', '--today', 'tomorrow') 6>$null) 'bad today'
} finally {
    Pop-Location
    Remove-Item -Recurse -Force $tmp
    Remove-Item Env:ACTIONTRACK_DATA, Env:ACTIONTRACK_TODAY
}

Write-Host ''
if ($script:Failed) { Write-Host "$script:Failed failed, $script:Passed passed" -ForegroundColor Red; exit 1 }
Write-Host "All $script:Passed checks passed" -ForegroundColor Green
exit 0
