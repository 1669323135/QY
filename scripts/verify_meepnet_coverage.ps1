param(
    [string]$Src = (Join-Path $env:TEMP 'meepnet_decompile\MeepNetAI'),
    [string]$Json = 'E:\编码仓库\QY\ModLocalizePatch\localizations\MeepNetAI\zh.json'
)

# Verify zh.json covers every STRINGS key the mod registers, so nothing user-facing
# is missed. Collects (a) full "STRINGS.*" literals from the decompiled sources and
# (b) the runtime-concatenated keys (DroneBoosters, AIModels), then diffs vs zh.json.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- keys already loaded from JSON library ---
$j = Get-Content -Raw -Encoding UTF8 $Json | ConvertFrom-Json
$jsonKeys = @($j.translations.PSObject.Properties.Name)

# --- (a) full STRINGS.* literals across decompiled sources ---
$codeKeys = New-Object System.Collections.Generic.HashSet[string]
Get-ChildItem $Src -Filter *.cs -File | ForEach-Object {
    $txt = [System.IO.File]::ReadAllText($_.FullName)
    foreach ($m in [regex]::Matches($txt, '"(STRINGS\.[A-Za-z0-9_\.]+)"'))
    {
        [void]$codeKeys.Add($m.Groups[1].Value)
    }
}

# --- (b) runtime-concatenated dynamic keys ---
# DroneBoosters: DroneId = "MeepNetDrone" + sourceId, uppercased
$boosters = @('Booster_Construct1', 'Booster_Ranch1', 'Booster_Cook1', 'Booster_Art1', 'Booster_Research1', 'Booster_Research2', 'Booster_Research3', 'Booster_Carry1', 'Booster_Op1', 'Booster_Op2', 'Booster_Medicine1', 'Booster_Tidy1')
foreach ($b in $boosters)
{
    $u = ('MeepNetDrone' + $b).ToUpperInvariant()
    [void]$codeKeys.Add('STRINGS.ITEMS.INDUSTRIAL_PRODUCTS.' + $u + '.NAME')
    [void]$codeKeys.Add('STRINGS.ITEMS.INDUSTRIAL_PRODUCTS.' + $u + '.DESC')
    [void]$codeKeys.Add('STRINGS.MISC.TAGS.' + $u)
}
# AIModels: ModelTechItem(i) = "MeepNetModelTech" + i, uppercased
for ($i = 0; $i -lt 12; $i++) {
    $u = ('MeepNetModelTech' + $i).ToUpperInvariant()
    [void]$codeKeys.Add('STRINGS.RESEARCH.OTHER_TECH_ITEMS.' + $u + '.NAME')
    [void]$codeKeys.Add('STRINGS.RESEARCH.OTHER_TECH_ITEMS.' + $u + '.DESC')
}
# OrbitalDroneDeploymentIds concatenated keys
foreach ($pair in @(
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONEMODULE', 'NAME'),
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONEMODULE', 'DESC'),
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONEMODULE', 'EFFECT'),
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONECARRIER', 'NAME'),
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONECARRIER', 'DESC'),
    @('STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALDRONECARRIER', 'EFFECT'),
    @('STRINGS.ROBOTS.MODELS.MEEPNETORBITALWORKERDRONE', 'NAME'),
    @('STRINGS.ROBOTS.MODELS.MEEPNETORBITALWORKERDRONE', 'DESC'),
    @('STRINGS.MISC.TAGS.MEEPNETORBITALWORKERDRONE', ''),
    @('STRINGS.MISC.TAGS.MEEPNETORBITALDRONECARRIER', '')
))
{
    $k = $pair[0]; if ($pair[1])
    {
        $k = $k + '.' + $pair[1]
    }
    [void]$codeKeys.Add($k)
}

# --- intentional omissions (empty string.Empty DESC / pure format placeholders) ---
$omit = @(
    'STRINGS.BUILDINGS.PREFABS.MEEPNETSILICONPURIFIER.DESC',
    'STRINGS.BUILDINGS.PREFABS.MEEPNETCOOLANTBLENDER.DESC',
    'STRINGS.BUILDINGS.PREFABS.MEEPNETORBITALRAILEJECTOR.DESC',
    'STRINGS.BUILDING.STATUSITEMS.MEEPNETAI.NAME',
    'STRINGS.BUILDING.STATUSITEMS.MEEPNETAI.TOOLTIP'
)

Write-Output ('code keys collected : ' + $codeKeys.Count)
Write-Output ('json keys           : ' + $jsonKeys.Count)

$missing = $codeKeys | Where-Object { ($jsonKeys -notcontains $_) -and ($omit -notcontains $_) } | Sort-Object
Write-Output ''
Write-Output ('=== registered in code but NOT in zh.json (excl. intentional omissions): ' + (@($missing).Count) + ' ===')
$missing | ForEach-Object { Write-Output ('  MISSING ' + $_) }

$extra = $jsonKeys | Where-Object { -not $codeKeys.Contains($_) } | Sort-Object
Write-Output ''
Write-Output ('=== in zh.json but no code literal found (may be dynamic/expected): ' + (@($extra).Count) + ' ===')
$extra | ForEach-Object { Write-Output ('  EXTRA ' + $_) }
