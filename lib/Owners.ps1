# Works out who owns an action item: "Priya N." / "@anita" / "Rahul" -> a full name
# from the attendee lists, "unassigned", or "Priya (ambiguous)" when we can't tell.

$script:Unassigned = 'unassigned'
$script:GroupOwners = 'everyone', 'everybody', 'team', 'the team', 'all', 'someone', 'somebody',
    'anyone', 'nobody', 'tbd', 'tba', 'tbc'

function Test-NeedsOwnerFix([string]$Owner) {
    return ($Owner -eq $script:Unassigned -or $Owner -like '* (ambiguous)')
}

# "Anita & Rahul" -> Anita, Rahul. "Lena (with Priya)" -> Lena. "@anita:" -> anita.
function Split-OwnerText([string]$Raw) {
    $s = ($Raw.Trim() -replace '^@', '' -replace ':$', '').Trim()
    $s = ($s -replace '\(.*?\)', '').Trim()
    $parts = @($s -split '\s*(?:&|\band\b|,|/)\s*' | Where-Object { $_.Trim() })
    if ($parts.Count -eq 0) { return @('') }
    return $parts
}

function Find-People([string[]]$Pool, [string]$First, [string]$Initial) {
    @($Pool | Where-Object {
        $parts = @($_ -split '\s+')
        ($parts[0] -ieq $First) -and
            (-not $Initial -or ($parts.Count -gt 1 -and $parts[-1].StartsWith($Initial, 'OrdinalIgnoreCase')))
    })
}

# Attendees of this meeting are checked first, then everyone seen in any note.
function Resolve-Owner([string]$Name, [string[]]$Attendees, [string[]]$Everyone) {
    $n = $Name.Trim()
    if (-not $n -or $script:GroupOwners -contains $n.ToLowerInvariant()) { return $script:Unassigned }

    $exact = @($Everyone | Where-Object { $_ -ieq $n })
    if ($exact.Count -ge 1) { return $exact[0] }

    $tokens = @(($n -replace '\.', '').Trim() -split '\s+')
    $first = $tokens[0]
    $initial = $null
    if ($tokens.Count -gt 1) { $initial = $tokens[-1].Substring(0, 1) }
    $label = (Get-Culture).TextInfo.ToTitleCase($first.ToLowerInvariant())

    foreach ($pool in @($Attendees, $Everyone)) {
        $found = @(Find-People @($pool) $first $initial)
        if ($found.Count -eq 1) { return $found[0] }
        if ($found.Count -gt 1) { return "$label (ambiguous)" }
    }
    # Not in any attendee list: keep the name as written.
    return (Get-Culture).TextInfo.ToTitleCase($n.ToLowerInvariant())
}

# Simplified task text used to spot the same task across meetings:
# "send the revised quote to Acme" == "Send revised quote to Acme."
function Get-TaskKey([string]$Task) {
    $words = ($Task.ToLowerInvariant() -replace '[^a-z0-9]+', ' ').Trim() -split ' '
    return (@($words | Where-Object { $_ -and $_ -notin @('the', 'a', 'an') }) -join ' ')
}
