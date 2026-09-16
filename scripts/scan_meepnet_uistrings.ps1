param(
    [string]$Dir = (Join-Path $env:TEMP 'meepnet_decompile\MeepNetAI')
)

# Scan the decompiled MeepNetAI sources for user-facing strings that live
# OUTSIDE the central MeepNetStrings table, so nothing is missed when building
# the zh.json translation library.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$files = Get-ChildItem $Dir -Filter *.cs -File

Write-Output '=== [1] Strings.Add / Strings.Get / LocString usages (grouped by file) ==='
$files | Select-String -Pattern 'Strings\.Add|Strings\.Get|LocString|CreateLocStringKeys' |
        Group-Object Filename | Sort-Object Count -Descending |
        ForEach-Object { Write-Output ('  ' + $_.Count.ToString().PadLeft(3) + '  ' + $_.Name) }

Write-Output ''
Write-Output '=== [2] "STRINGS." literal keys outside MeepNetStrings.cs ==='
$files | Where-Object { $_.Name -ne 'MeepNetStrings.cs' } |
        Select-String -Pattern '"STRINGS\.' |
        ForEach-Object { Write-Output ('  ' + $_.Filename + ':' + $_.LineNumber + ': ' + $_.Line.Trim()) }

Write-Output ''
Write-Output '=== [3] Side screen / UI label assignments (.text =, SetText, AddLabel, tooltip) ==='
$files | Select-String -Pattern '\.text\s*=\s*"|SetText\(|LocText|\.tooltip|AddLabel|title\s*=\s*"' |
        Where-Object { $_.Line -match '"[A-Za-z][A-Za-z ,''\.\-]{3,}"' } |
        Select-Object -First 60 |
        ForEach-Object { Write-Output ('  ' + $_.Filename + ':' + $_.LineNumber + ': ' + $_.Line.Trim()) }

Write-Output ''
Write-Output '=== [4] PLib Options [Option] attributes (mod settings dialog) ==='
$files | Select-String -Pattern 'OptionAttribute|\[Option\(|POption|Title\s*=|Tooltip\s*=' |
        Select-Object -First 40 |
        ForEach-Object { Write-Output ('  ' + $_.Filename + ':' + $_.LineNumber + ': ' + $_.Line.Trim()) }
