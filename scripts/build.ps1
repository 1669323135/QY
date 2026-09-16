#Requires -Version 5.1
<#
.SYNOPSIS
    ONI Mod auto-build script
.DESCRIPTION
    Build ModLocalizePatch and copy DLL to mod root directory.
    The csproj post-build event handles DLL copy automatically.
.EXAMPLE
    .\scripts\build.ps1                # Build Release
    .\scripts\build.ps1 -Config Debug  # Build Debug
    .\scripts\build.ps1 -Clean         # Clean + rebuild
#>

param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Release",
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# -- Project list --
$projects = @(
    @{
        Name = "ModLocalizePatch"
        Csproj = "ModLocalizePatch/ModLocalizePatch/ModLocalizePatch.csproj"
        Dll = "ModLocalizePatch/ModLocalizePatch.dll"
    }
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$failed = 0
$succeeded = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ONI Mod Build Script" -ForegroundColor Cyan
Write-Host "  Config: $Config | Root: $repoRoot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($proj in $projects)
{
    $csprojPath = Join-Path $repoRoot $proj.Csproj
    $projName = $proj.Name

    if (-not (Test-Path $csprojPath))
    {
        Write-Host "[SKIP] $projName - csproj not found" -ForegroundColor Yellow
        continue
    }

    Write-Host "--------------------------------------" -ForegroundColor DarkGray
    Write-Host "[$projName] Building ($Config)..." -ForegroundColor White

    if ($Clean)
    {
        Write-Host "  Cleaning..." -ForegroundColor DarkGray
        dotnet clean $csprojPath -c $Config --nologo -v q 2>&1 | Out-Null
    }

    $startTime = Get-Date
    $output = dotnet build $csprojPath -c $Config --nologo 2>&1
    $exitCode = $LASTEXITCODE
    $elapsed = (Get-Date) - $startTime

    if ($exitCode -ne 0)
    {
        Write-Host ""
        $output | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        Write-Host ""
        $failMsg = "  [FAIL] $projName - exit=$exitCode"
        Write-Host $failMsg -ForegroundColor Red
        $failed++
        continue
    }

    # Check DLL output
    $dllPath = Join-Path $repoRoot $proj.Dll
    if (Test-Path $dllPath)
    {
        $dllInfo = Get-Item $dllPath
        $dllSize = [math]::Round($dllInfo.Length / 1024, 1)
        $dllTime = $dllInfo.LastWriteTime.ToString("HH:mm:ss")
        $dllMsg = "  DLL: $( $proj.Dll ) - $dllSize KB, $dllTime"
        Write-Host $dllMsg -ForegroundColor DarkGray
    }

    $elapsedStr = [math]::Round($elapsed.TotalSeconds, 1)
    $okMsg = "  [OK] $projName - $elapsedStr s"
    Write-Host $okMsg -ForegroundColor Green
    $succeeded++
}

Write-Host ""
$summaryMsg = "  Done: $succeeded succeeded, $failed failed"
Write-Host "========================================" -ForegroundColor Cyan
if ($failed -gt 0)
{
    Write-Host $summaryMsg -ForegroundColor Red
}
else
{
    Write-Host $summaryMsg -ForegroundColor Green
}
Write-Host "========================================" -ForegroundColor Cyan

exit $failed
