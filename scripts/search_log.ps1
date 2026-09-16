$logFile = Join-Path (Join-Path $env:USERPROFILE 'AppData\LocalLow\Klei\Oxygen Not Included') 'Player.log'

Write-Host '=== Searching for ModLocalizePatch in log ==='
$lines = Get-Content $logFile
$matches = $lines | Select-String -Pattern 'ModLocalizePatch' -SimpleMatch
if ($matches)
{
    foreach ($m in $matches)
    {
        Write-Host $m.Line
    }
}
else
{
    Write-Host 'No mentions of ModLocalizePatch found'
}

Write-Host ''
Write-Host '=== Searching for mod load errors ==='
$errors = $lines | Select-String -Pattern 'Failed to load mod|mod load error|ModLocalize' -SimpleMatch
if ($errors)
{
    foreach ($e in $errors)
    {
        Write-Host $e.Line
    }
}
else
{
    Write-Host 'No mod load errors found'
}

Write-Host ''
Write-Host '=== Searching for local mod detection ==='
$local = $lines | Select-String -Pattern 'local mod|ModLocalize|mods/Mod' -SimpleMatch
if ($local)
{
    foreach ($l in $local)
    {
        Write-Host $l.Line
    }
}
else
{
    Write-Host 'No local mod detection entries found'
}
