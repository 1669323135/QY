# check_compat.ps1 - Check ONI game compatibility info
$ErrorActionPreference = 'SilentlyContinue'

# Detect game install path
$gamePaths = @(
    'D:\Steam\steamapps\common\OxygenNotIncluded',
    'E:\Steam\steamapps\common\OxygenNotIncluded',
    'C:\Program Files (x86)\Steam\steamapps\common\OxygenNotIncluded',
    'C:\Program Files\Steam\steamapps\common\OxygenNotIncluded'
)

$gamePath = $null
foreach ($p in $gamePaths)
{
    if (Test-Path $p)
    {
        $gamePath = $p; break
    }
}

if (-not $gamePath)
{
    Write-Host "ERROR: Game not found"
    exit 1
}

Write-Host "=== Game Path ==="
Write-Host "  $gamePath"

# Game exe version
$exePath = Join-Path $gamePath 'OxygenNotIncluded.exe'
if (Test-Path $exePath)
{
    $exeInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)
    Write-Host ""
    Write-Host "=== Game Executable ==="
    Write-Host "  FileVersion:    $( $exeInfo.FileVersion )"
    Write-Host "  ProductVersion: $( $exeInfo.ProductVersion )"
    Write-Host "  ProductName:    $( $exeInfo.ProductName )"
}

# Managed DLL versions
$managedPath = Join-Path $gamePath 'OxygenNotIncluded_Data\Managed'
Write-Host ""
Write-Host "=== Key Dependency DLLs ==="

$dllNames = @('0Harmony.dll', 'Assembly-CSharp.dll', 'Newtonsoft.Json.dll', 'UnityEngine.dll', 'UnityEngine.CoreModule.dll')
foreach ($dll in $dllNames)
{
    $dllPath = Join-Path $managedPath $dll
    if (Test-Path $dllPath)
    {
        $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dllPath)
        $size = (Get-Item $dllPath).Length
        Write-Host "  $dll"
        Write-Host "    FileVersion:    $( $info.FileVersion )"
        Write-Host "    ProductVersion: $( $info.ProductVersion )"
        Write-Host "    Size:           $size bytes"
    }
    else
    {
        Write-Host "  $dll - NOT FOUND"
    }
}

# DLC detection
Write-Host ""
Write-Host "=== DLC Detection ==="
$dlls2 = Get-ChildItem $managedPath -Filter '*Dlc*' -ErrorAction SilentlyContinue
if ($dlls2)
{
    foreach ($d in $dlls2)
    {
        Write-Host "  DLC file: $( $d.Name ) ($( $d.Length ) bytes)"
    }
}
else
{
    Write-Host "  No DLC-specific DLLs found"
}

# Check for Spaced Out content
$spacedOutPath = Join-Path $gamePath 'Dlc\spacedout'
if (Test-Path $spacedOutPath)
{
    Write-Host "  Spaced Out DLC folder: EXISTS"
}
else
{
    Write-Host "  Spaced Out DLC folder: not found at expected path"
}

# .NET runtime
Write-Host ""
Write-Host "=== .NET Runtime ==="
$dotnetVersions = dotnet --list-runtimes 2>&1
if ($dotnetVersions)
{
    $dotnetVersions | ForEach-Object { Write-Host "  $_" }
}
else
{
    Write-Host "  dotnet CLI not found"
}

# mod_info.yaml
Write-Host ""
Write-Host "=== Mod Compat Config (mod_info.yaml) ==="
$modInfoPath = 'E:\编码仓库\QY\ModLocalizePatch\mod_info.yaml'
if (Test-Path $modInfoPath)
{
    Get-Content $modInfoPath | ForEach-Object { Write-Host "  $_" }
}

# Target mod compatibility check
Write-Host ""
Write-Host "=== Target Mod Compatibility ==="
$localModsDir = Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods'
$steamCacheDir = Join-Path $localModsDir 'Steam'
$workshopDirs = @(
    'D:\Steam\steamapps\workshop\content\457140',
    'E:\Steam\steamapps\workshop\content\457140',
    'C:\Program Files (x86)\Steam\steamapps\workshop\content\457140',
    'C:\Program Files\Steam\steamapps\workshop\content\457140'
)

if (Test-Path $steamCacheDir)
{
    Write-Host "  Steam cache dir: EXISTS"
    $cachedMods = Get-ChildItem $steamCacheDir -Directory -ErrorAction SilentlyContinue
    Write-Host "  Cached mods count: $( $cachedMods.Count )"
}

$configPath = 'E:\编码仓库\QY\ModLocalizePatch\localizations\config.json'
if (Test-Path $configPath)
{
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    $mapping = $config.steamIdMapping

    $searchRoots = @()
    if (Test-Path $localModsDir)
    {
        $searchRoots += $localModsDir
    }
    if (Test-Path $steamCacheDir)
    {
        $searchRoots += $steamCacheDir
    }
    foreach ($wd in $workshopDirs)
    {
        if (Test-Path $wd)
        {
            $searchRoots += $wd
        }
    }

    foreach ($key in $mapping.PSObject.Properties.Name)
    {
        if ($key -notmatch '^\d+$')
        {
            continue
        }
        $folderName = $mapping.$key
        $found = $false
        foreach ($root in $searchRoots)
        {
            $modDir = Join-Path $root $key
            if (Test-Path $modDir)
            {
                $found = $true
                $targetModInfo = Join-Path $modDir 'mod_info.yaml'
                $targetModYaml = Join-Path $modDir 'mod.yaml'
                $supportedContent = 'unknown'
                $minBuild = 'unknown'
                $targetTitle = 'unknown'

                if (Test-Path $targetModInfo)
                {
                    $infoContent = Get-Content $targetModInfo -Raw
                    if ($infoContent -match 'supportedContent:\s*(\S+)')
                    {
                        $supportedContent = $Matches[1]
                    }
                    if ($infoContent -match 'minimumSupportedBuild:\s*(\S+)')
                    {
                        $minBuild = $Matches[1]
                    }
                }
                if (Test-Path $targetModYaml)
                {
                    $yamlContent = Get-Content $targetModYaml -Raw
                    if ($yamlContent -match 'title:\s*(.+)')
                    {
                        $targetTitle = $Matches[1].Trim().Trim('"')
                    }
                }

                Write-Host "  [$key] $targetTitle"
                Write-Host "    supportedContent=$supportedContent minBuild=$minBuild"
                break
            }
        }
        if (-not $found)
        {
            Write-Host "  [$key] $folderName - NOT INSTALLED"
        }
    }
}

Write-Host ""
Write-Host "=== Done ==="
