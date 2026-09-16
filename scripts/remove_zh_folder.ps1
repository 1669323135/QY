# remove_zh_folder.ps1 - Remove the Chinese-named folder
$repoRoot = Split-Path -Parent $PSScriptRoot
$zhName = [char]0x6C49 + [char]0x5316 + [char]0x8865 + [char]0x4E01
$zhDir = Join-Path $repoRoot $zhName

if (Test-Path $zhDir)
{
    Remove-Item -LiteralPath $zhDir -Recurse -Force
    Write-Host "Removed: $zhDir"
}
else
{
    Write-Host "Not found (already clean): $zhDir"
}

# Also clean up old game mod deployment folders
$gameModsDir = Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods\Local'
$oldGameDir = Join-Path $gameModsDir $zhName
if (Test-Path $oldGameDir)
{
    Remove-Item -LiteralPath $oldGameDir -Recurse -Force
    Write-Host "Removed game mod folder: $oldGameDir"
}

Write-Host "Cleanup done."
