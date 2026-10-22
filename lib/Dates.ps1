# Turns date phrases from meeting notes ("by Friday", "10 Sep", "end of month")
# into real dates, counted from the meeting date.

$script:Invariant = [Globalization.CultureInfo]::InvariantCulture

$script:Months = @{
    'jan' = 1; 'january' = 1; 'feb' = 2; 'february' = 2; 'mar' = 3; 'march' = 3
    'apr' = 4; 'april' = 4; 'may' = 5; 'jun' = 6; 'june' = 6; 'jul' = 7; 'july' = 7
    'aug' = 8; 'august' = 8; 'sep' = 9; 'sept' = 9; 'september' = 9
    'oct' = 10; 'october' = 10; 'nov' = 11; 'november' = 11; 'dec' = 12; 'december' = 12
}
$script:FullMonthNames = 'january', 'february', 'march', 'april', 'may', 'june', 'july',
    'august', 'september', 'october', 'november', 'december'

# Values match [DayOfWeek]: Sunday = 0 ... Saturday = 6
$script:Weekdays = @{
    'sun' = 0; 'sunday' = 0; 'mon' = 1; 'monday' = 1; 'tue' = 2; 'tues' = 2; 'tuesday' = 2
    'wed' = 3; 'weds' = 3; 'wednesday' = 3; 'thu' = 4; 'thur' = 4; 'thurs' = 4; 'thursday' = 4
    'fri' = 5; 'friday' = 5; 'sat' = 6; 'saturday' = 6
}

function ConvertTo-IsoDate([datetime]$Date) {
    $Date.ToString('yyyy-MM-dd', $script:Invariant)
}

function ConvertFrom-IsoDate([string]$Text) {
    if (-not $Text) { return $null }
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact($Text.Trim(), 'yyyy-MM-dd', $script:Invariant,
            [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function Format-FriendlyDate([datetime]$Date) {
    $Date.ToString('ddd d MMM yyyy', $script:Invariant)
}

function New-SafeDate([int]$Year, [int]$Month, [int]$Day) {
    try { return (New-Object DateTime $Year, $Month, $Day) } catch { return $null }
}

# A day and month without a year belongs to the meeting's year, unless that would
# put it more than six months before the meeting (then it means next year).
function Get-DayMonthDate([int]$Day, [int]$Month, $Year, [datetime]$Ref) {
    if ($Year) { return New-SafeDate $Year $Month $Day }
    $date = New-SafeDate $Ref.Year $Month $Day
    if ($date -and $date -lt $Ref.AddDays(-180)) { $date = New-SafeDate ($Ref.Year + 1) $Month $Day }
    return $date
}

# "Friday" means the next Friday strictly after the meeting day.
function Get-NextWeekday([datetime]$Ref, [int]$DayOfWeek) {
    $diff = ($DayOfWeek - [int]$Ref.DayOfWeek + 7) % 7
    if ($diff -eq 0) { $diff = 7 }
    return $Ref.AddDays($diff)
}

# Friday of the meeting's week (or the coming Friday if the meeting was at the weekend).
function Get-EndOfWeek([datetime]$Ref) {
    return $Ref.AddDays((5 - [int]$Ref.DayOfWeek + 7) % 7)
}

function Get-EndOfMonth([int]$Year, [int]$Month) {
    return New-SafeDate $Year $Month ([DateTime]::DaysInMonth($Year, $Month))
}

# Turns one whole phrase ("friday", "10 sep", "2026-10-09") into a date, or $null.
# The phrase must be a date and nothing else, so "10%" is never read as a date.
function Resolve-DatePhrase([string]$Phrase, [datetime]$Ref) {
    if (-not $Phrase) { return $null }
    $p = $Phrase.ToLowerInvariant().Trim()
    $p = $p.TrimEnd([char[]]@('.', ',', ';', ':', '!', ')')).Trim()
    $p = $p -replace '\s+', ' '

    if ($p -match '^(\d{4})-(\d{1,2})-(\d{1,2})$') {
        return New-SafeDate ([int]$Matches[1]) ([int]$Matches[2]) ([int]$Matches[3])
    }
    if ($p -match '^(today|eod|end of day|cob)$') { return $Ref }
    if ($p -match '^(eod tomorrow|tomorrow eod|tomorrow)$') { return $Ref.AddDays(1) }
    if ($p -match '^end of (the |this )?week$') { return Get-EndOfWeek $Ref }
    if ($p -match '^end of next week$') { return (Get-EndOfWeek $Ref).AddDays(7) }
    if ($p -match '^end of (the |this )?month$') { return Get-EndOfMonth $Ref.Year $Ref.Month }

    # "november" / "end of november" -> last day of that month
    if ($p -match '^(?:end of )?([a-z]+)$' -and $script:FullMonthNames -contains $Matches[1]) {
        $month = $script:Months[$Matches[1]]
        $last = Get-EndOfMonth $Ref.Year $month
        if ($last -lt $Ref.AddDays(-180)) { $last = Get-EndOfMonth ($Ref.Year + 1) $month }
        return $last
    }
    # "mid-october" -> the 15th
    if ($p -match '^mid[- ]?([a-z]+)$' -and $script:Months.ContainsKey($Matches[1])) {
        return Get-DayMonthDate 15 $script:Months[$Matches[1]] $null $Ref
    }
    # "friday" / "next tuesday" ("next" = one week later than the plain weekday)
    if ($p -match '^(next )?([a-z]+)$' -and $script:Weekdays.ContainsKey($Matches[2])) {
        $isNext = [bool]$Matches[1]
        $date = Get-NextWeekday $Ref $script:Weekdays[$Matches[2]]
        if ($isNext) { $date = $date.AddDays(7) }
        return $date
    }
    # "10 sep", "wed 16 sep", "monday, 14 september 2026"
    if ($p -match '^(?:([a-z]+),? )?(\d{1,2})(?:st|nd|rd|th)? ([a-z]+),?(?: (\d{4}))?$') {
        $weekday = $Matches[1]; $day = [int]$Matches[2]; $monthName = $Matches[3]; $year = $Matches[4]
        if ($weekday -and -not $script:Weekdays.ContainsKey($weekday)) { return $null }
        if (-not $script:Months.ContainsKey($monthName)) { return $null }
        return Get-DayMonthDate $day $script:Months[$monthName] $year $Ref
    }
    # "oct 3rd", "september 9, 2026"
    if ($p -match '^(?:([a-z]+),? )?([a-z]+) (\d{1,2})(?:st|nd|rd|th)?,?(?: (\d{4}))?$') {
        $weekday = $Matches[1]; $monthName = $Matches[2]; $day = [int]$Matches[3]; $year = $Matches[4]
        if ($weekday -and -not $script:Weekdays.ContainsKey($weekday)) { return $null }
        if (-not $script:Months.ContainsKey($monthName)) { return $null }
        return Get-DayMonthDate $day $script:Months[$monthName] $year $Ref
    }
    return $null
}

# Meeting dates must contain a year ("2026-09-08", "9 September 2026").
function ConvertFrom-MeetingDate([string]$Text) {
    if (-not $Text -or $Text -notmatch '\b\d{4}\b') { return $null }
    return Resolve-DatePhrase $Text (Get-Date).Date
}

function Remove-TrailingPunctuation([string]$Text) {
    $trim = [char[]]@(' ', ',', ':', ';', '-', [char]0x2014, [char]0x2013)
    return $Text.Trim().TrimEnd($trim).Trim()
}

# Finds the due date at the end of an action item ("... by Friday") and returns
# the task without it. The due phrase must run to the end of the line.
function Split-DueDate([string]$Text, [datetime]$Ref) {
    $rx = [regex]'(?i)(?:,\s*\w+\s+)?\b(?:by|due|on|from|for|before|until)\s+'
    foreach ($m in $rx.Matches($Text)) {
        $due = Resolve-DatePhrase $Text.Substring($m.Index + $m.Length) $Ref
        if ($due) {
            return @{
                Task   = Remove-TrailingPunctuation $Text.Substring(0, $m.Index)
                Due    = $due
                DueRaw = ($Text.Substring($m.Index).Trim() -replace '^,\s*', '')
            }
        }
    }
    # "Karan to circulate the summary tomorrow" (no "by")
    $bare = [regex]::Match($Text, '(?i)\s+(tomorrow|today|eod)\s*$')
    if ($bare.Success) {
        return @{
            Task   = Remove-TrailingPunctuation $Text.Substring(0, $bare.Index)
            Due    = Resolve-DatePhrase $bare.Groups[1].Value $Ref
            DueRaw = $bare.Groups[1].Value
        }
    }
    return @{ Task = Remove-TrailingPunctuation $Text; Due = $null; DueRaw = $null }
}
