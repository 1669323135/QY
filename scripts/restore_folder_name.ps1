# restore_folder_name.ps1 - Rename folder back from Chinese to English
$repoRoot = Split-Path -Parent $PSScriptRoot
$zhName = [char]0x6C49 + [char]0x5316 + [char]0x8865 + [char]0x4E01
$zhDir = Join-Path $repoRoot $zhName
$enDir = Join-Path $repoRoot "ModLocalizePatch"

Write-Host "=== Restore folder name to English ==="

# Step 1: Rename outer folder back
if (Test-Path $zhDir)
{
    if (Test-Path $enDir)
    {
        Write-Host "ERROR: Both folders exist! Manual cleanup needed."
        exit 1
    }
    Rename-Item -LiteralPath $zhDir -NewName "ModLocalizePatch"
    Write-Host "  OK: $zhName -> ModLocalizePatch (outer)"
}
else
{
    Write-Host "  SKIP: Chinese folder not found (already English?)"
}

# Step 2: Rename inner project folder back
$innerZh = Join-Path $enDir $zhName
$innerEn = Join-Path $enDir "ModLocalizePatch"
if (Test-Path $innerZh)
{
    Rename-Item -LiteralPath $innerZh -NewName "ModLocalizePatch"
    Write-Host "  OK: Inner $zhName -> ModLocalizePatch"
}
else
{
    Write-Host "  SKIP: Inner Chinese folder not found"
}

# Step 3: Rename .csproj back
$csprojZh = Join-Path $innerEn ($zhName + ".csproj")
if (Test-Path $csprojZh)
{
    Rename-Item -LiteralPath $csprojZh -NewName "ModLocalizePatch.csproj"
    Write-Host "  OK: .csproj renamed back"
}
else
{
    Write-Host "  SKIP: Chinese .csproj not found"
}

# Step 4: Rename .sln back
$slnZh = Join-Path $enDir ($zhName + ".sln")
if (Test-Path $slnZh)
{
    Rename-Item -LiteralPath $slnZh -NewName "ModLocalizePatch.sln"
    Write-Host "  OK: .sln renamed back"
}
else
{
    Write-Host "  SKIP: Chinese .sln not found"
}

Write-Host ""
Write-Host "=== Done ==="
