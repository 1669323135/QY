# verify_project_deploy.ps1 - Verify mod deployment to project mods folder
# Use script's own location to derive paths (avoids Chinese path encoding issues)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$target = Join-Path $projectRoot 'mods\ModLocalizePatch'
$source = Join-Path $projectRoot 'ModLocalizePatch'

Write-Host "=== Verifying deployment ==="
Write-Host "Source: $source"
Write-Host "Target: $target"
Write-Host ""

if (-not (Test-Path $source))
{
    Write-Host "ERROR: Source directory does not exist: $source"
    exit 1
}

# Perform the copy using robocopy (handles Chinese paths correctly)
Write-Host "--- Running robocopy ---"
$robocopyArgs = @($source, $target, '/MIR', '/NFL', '/NDL', '/NJH')
& robocopy @robocopyArgs
Write-Host "robocopy exit code: $LASTEXITCODE"
Write-Host ""

# Verify
if (-not (Test-Path $target))
{
    Write-Host "ERROR: Target directory still missing after robocopy!"
    exit 1
}

# Check core files
$coreFiles = @('ModLocalizePatch.dll', 'mod.yaml', 'mod_info.yaml', 'preview.png', 'README.md')
Write-Host "--- Core files ---"
$allOk = $true
foreach ($f in $coreFiles)
{
    $path = Join-Path $target $f
    if (Test-Path $path)
    {
        $size = (Get-Item $path).Length
        Write-Host "  [OK] $f ($size bytes)"
    }
    else
    {
        Write-Host "  [MISSING] $f"
        $allOk = $false
    }
}

# Check localizations directory
$locDir = Join-Path $target 'localizations'
Write-Host ""
Write-Host "--- Localizations ---"
if (Test-Path $locDir)
{
    $configPath = Join-Path $locDir 'config.json'
    if (Test-Path $configPath)
    {
        Write-Host "  [OK] config.json"
    }

    $subDirs = Get-ChildItem $locDir -Directory
    Write-Host "  Translation folders: $( $subDirs.Count )"
    foreach ($d in $subDirs)
    {
        $jsonFiles = Get-ChildItem (Join-Path $locDir $d.Name) -Filter '*.json'
        Write-Host "    $( $d.Name )/ - $( $jsonFiles.Count ) json file(s)"
    }
}
else
{
    Write-Host "  [MISSING] localizations/"
    $allOk = $false
}

Write-Host ""
if ($allOk)
{
    Write-Host "=== Deployment verified successfully ==="
}
else
{
    Write-Host "=== Deployment has issues - check above ==="
}
