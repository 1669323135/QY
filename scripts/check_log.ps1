# Clean all ModLocalizePatch artifacts from local game directory
# to simulate a fresh workshop subscription scenario
$kleiDir = Join-Path $env:USERPROFILE "Documents\Klei\OxygenNotIncluded\mods"

# === Step 1: Remove Local\ModLocalizePatch deployment ===
Write-Host "=== Step 1: Remove Local mod deployment ===" -ForegroundColor Cyan
$localMod = Join-Path $kleiDir "Local\ModLocalizePatch"
if (Test-Path $localMod)
{
    Remove-Item -LiteralPath $localMod -Recurse -Force
    Write-Host "  REMOVED: Local\ModLocalizePatch" -ForegroundColor Green
}
else
{
    Write-Host "  Already clean" -ForegroundColor Gray
}

# === Step 2: Remove auto-generated zh.po from all target Steam mods ===
Write-Host ""
Write-Host "=== Step 2: Remove auto-generated zh.po from Steam mods ===" -ForegroundColor Cyan
$steamDir = Join-Path $kleiDir "Steam"
$targetIds = @("3798248283", "3113986230", "3770134628",
"3740127708", "3591826138", "3508859197", "3740131305",
"3508873047", "3508865977", "3508870243", "3743015529")
$cleaned = 0
foreach ($id in $targetIds)
{
    $poPath = Join-Path $steamDir "$id\translations\zh.po"
    if (Test-Path $poPath)
    {
        Remove-Item -LiteralPath $poPath -Force
        Write-Host "  REMOVED: Steam\$id\translations\zh.po" -ForegroundColor Green
        $cleaned++
    }
}
Write-Host "  Cleaned $cleaned zh.po file(s)"

# === Step 3: Remove whitelist.txt (runtime artifact) ===
Write-Host ""
Write-Host "=== Step 3: Remove runtime artifacts ===" -ForegroundColor Cyan
$whitelistPath = Join-Path $kleiDir "Local\ModLocalizePatch\whitelist.txt"
if (Test-Path $whitelistPath)
{
    Remove-Item -LiteralPath $whitelistPath -Force
    Write-Host "  REMOVED: whitelist.txt" -ForegroundColor Green
}
else
{
    Write-Host "  whitelist.txt already clean (removed with mod dir)" -ForegroundColor Gray
}

# === Step 4: Verify clean state ===
Write-Host ""
Write-Host "=== Step 4: Verify clean state ===" -ForegroundColor Cyan
$anyIssue = $false
if (Test-Path $localMod)
{
    Write-Host "  FAIL: Local mod still exists" -ForegroundColor Red
    $anyIssue = $true
}
foreach ($id in $targetIds)
{
    $poPath = Join-Path $steamDir "$id\translations\zh.po"
    if (Test-Path $poPath)
    {
        Write-Host "  FAIL: $id\translations\zh.po still exists" -ForegroundColor Red
        $anyIssue = $true
    }
}
if (-not $anyIssue)
{
    Write-Host "  ALL CLEAN - Ready for fresh subscription test" -ForegroundColor Green
}
