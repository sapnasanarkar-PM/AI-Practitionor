# Entry point. Run through actiontrack.cmd, e.g.:  .\actiontrack list --status overdue
[Console]::OutputEncoding = [Text.Encoding]::UTF8
. (Join-Path $PSScriptRoot 'lib/Commands.ps1')
exit (Invoke-ActionTrack $args)
