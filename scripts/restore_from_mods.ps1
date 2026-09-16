# restore_from_mods.ps1 - Restore missing files from deployed mods copy
$repoRoot = Split-Path -Parent $PSScriptRoot
$modSrc = Join-Path $repoRoot "mods\ModLocalizePatch"
$modDst = Join-Path $repoRoot "ModLocalizePatch"

Write-Host "=== Restoring from mods copy ==="
Write-Host "Source: $modSrc"
Write-Host "Target: $modDst"

if (-not (Test-Path $modSrc))
{
    Write-Host "ERROR: Source not found: $modSrc"
    exit 1
}

# Copy missing root files
$rootFiles = @("README.md", "preview.png", "ModLocalizePatch.dll")
foreach ($f in $rootFiles)
{
    $src = Join-Path $modSrc $f
    $dst = Join-Path $modDst $f
    if ((Test-Path $src) -and (-not (Test-Path $dst)))
    {
        Copy-Item -LiteralPath $src -Destination $dst -Force
        Write-Host "  Restored: $f"
    }
}

# Copy localizations directory
$srcLoc = Join-Path $modSrc "localizations"
$dstLoc = Join-Path $modDst "localizations"
if ((Test-Path $srcLoc) -and (-not (Test-Path $dstLoc)))
{
    & robocopy $srcLoc $dstLoc /MIR /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null
    Write-Host "  Restored: localizations/"
}

# Copy missing .cs files from git history or other source
# Patches.cs, LocalizationManager.cs, CritterOverlayPatches.cs are NOT in mods copy
# They only exist in the source project. Check if they're still somewhere.
$innerDst = Join-Path $modDst "ModLocalizePatch"
$missingCs = @("Patches.cs", "LocalizationManager.cs", "CritterOverlayPatches.cs")
foreach ($f in $missingCs)
{
    $dst = Join-Path $innerDst $f
    if (-not (Test-Path $dst))
    {
        Write-Host "  [MISSING] $f - needs git recovery or manual restore"
    }
}

Write-Host ""
Write-Host "=== Done ==="
