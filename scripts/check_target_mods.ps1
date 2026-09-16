# check_target_mods.ps1 - Check target mod compatibility
$ids = @('3113986230', '3740127708', '3591826138', '3508859197', '3740131305', '3508873047', '3508865977', '3508870243', '3743015529', '3770134628', '3798248283')
$localModsDir = Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods'
$steamCache = Join-Path $localModsDir 'Steam'
$roots = @(
    $localModsDir,
    $steamCache,
    'D:\Steam\steamapps\workshop\content\457140',
    'E:\Steam\steamapps\workshop\content\457140'
)

foreach ($id in $ids)
{
    $found = $false
    foreach ($r in $roots)
    {
        $p = Join-Path $r $id
        if (Test-Path $p)
        {
            $mi = Join-Path $p 'mod_info.yaml'
            $sc = 'unknown'
            $mb = 'unknown'
            $av = 'unknown'
            if (Test-Path $mi)
            {
                $c = Get-Content $mi -Raw
                if ($c -match 'supportedContent:\s*(\S+)')
                {
                    $sc = $Matches[1]
                }
                if ($c -match 'minimumSupportedBuild:\s*(\d+)')
                {
                    $mb = $Matches[1]
                }
                if ($c -match 'APIVersion:\s*(\d+)')
                {
                    $av = $Matches[1]
                }
            }
            Write-Host "[$id] supportedContent=$sc minBuild=$mb APIVersion=$av [FOUND]"
            $found = $true
            break
        }
    }
    if (-not $found)
    {
        Write-Host "[$id] NOT INSTALLED"
    }
}
