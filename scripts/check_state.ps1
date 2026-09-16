# check_state.ps1 - Quick check of current project state
$repoRoot = Split-Path -Parent $PSScriptRoot
$modDir = Join-Path $repoRoot "ModLocalizePatch"

Write-Host "=== Project State Check ==="
Write-Host "ModLocalizePatch exists: $( Test-Path $modDir )"

if (Test-Path $modDir)
{
    Write-Host ""
    Write-Host "--- Root files ---"
    Get-ChildItem -LiteralPath $modDir -File | ForEach-Object { Write-Host "  $( $_.Name )" }

    Write-Host ""
    Write-Host "--- Subdirectories ---"
    Get-ChildItem -LiteralPath $modDir -Directory | ForEach-Object { Write-Host "  $( $_.Name )/" }

    # Check inner project folder
    $innerDir = Join-Path $modDir "ModLocalizePatch"
    if (Test-Path $innerDir)
    {
        Write-Host ""
        Write-Host "--- Inner project files ---"
        Get-ChildItem -LiteralPath $innerDir -File | ForEach-Object { Write-Host "  $( $_.Name )" }
    }
    else
    {
        Write-Host ""
        Write-Host "  [WARN] Inner ModLocalizePatch/ folder NOT found"
        # Check if Chinese-named inner folder exists
        $zhName = [char]0x6C49 + [char]0x5316 + [char]0x8865 + [char]0x4E01
        $innerZh = Join-Path $modDir $zhName
        if (Test-Path $innerZh)
        {
            Write-Host "  [INFO] Inner folder is Chinese-named: $zhName/"
        }
    }
}

# Check if Chinese folder still exists
$zhName = [char]0x6C49 + [char]0x5316 + [char]0x8865 + [char]0x4E01
$zhDir = Join-Path $repoRoot $zhName
Write-Host ""
Write-Host "Chinese folder ($zhName) exists: $( Test-Path $zhDir )"
