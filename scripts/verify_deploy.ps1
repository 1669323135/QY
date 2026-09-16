$modDir = Join-Path (Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods') 'ModLocalizePatch'

Write-Host '=== Mod deployment verification ==='
Write-Host "Directory: $modDir"
Write-Host ''

$files = Get-ChildItem $modDir -Recurse -File
Write-Host "Total files: $( $files.Count )"
Write-Host ''

foreach ($f in $files)
{
    $rel = $f.FullName.Substring($modDir.Length + 1)
    Write-Host "  $rel  ($( $f.Length ) bytes)"
}

Write-Host ''
$dll = Join-Path $modDir 'ModLocalizePatch.dll'
$yaml = Join-Path $modDir 'mod.yaml'
$info = Join-Path $modDir 'mod_info.yaml'

$ok = $true
if (-not (Test-Path $dll))
{
    Write-Host '[MISSING] ModLocalizePatch.dll'; $ok = $false
}
if (-not (Test-Path $yaml))
{
    Write-Host '[MISSING] mod.yaml'; $ok = $false
}
if (-not (Test-Path $info))
{
    Write-Host '[MISSING] mod_info.yaml'; $ok = $false
}

if ($ok)
{
    Write-Host '[OK] All required files present!'
}
else
{
    Write-Host '[ERROR] Some required files are missing!'
}
