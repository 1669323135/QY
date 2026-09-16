param([string]$DllPath)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$sb = New-Object System.Text.StringBuilder
$results = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -ge 0x20 -and $b -le 0x7E)
    {
        [void]$sb.Append([char]$b)
    }
    else
    {
        if ($sb.Length -ge 4)
        {
            $results.Add($sb.ToString())
        }
        [void]$sb.Clear()
    }
}

$patterns = 'PLib', 'Localization', 'OverloadStrings', 'RegisterForTranslation', 'AddLocString', 'LocString', 'Strings', 'TranslateStrings', 'SetTranslation', 'PStr', 'UserMod2', 'BuildingConfig', 'GeneratedBuildings', 'RegisterBuilding', 'OnLoad', 'OnAllModsLoaded', 'AddBuilding', 'strings_templates', 'translations'
$uniq = $results | Select-Object -Unique
foreach ($p in $patterns)
{
    $hits = $uniq | Where-Object { $_ -match [regex]::Escape($p) }
    if ($hits)
    {
        Write-Output "==== $p ===="
        $hits | Select-Object -First 25 | ForEach-Object { Write-Output "  $_" }
    }
}
