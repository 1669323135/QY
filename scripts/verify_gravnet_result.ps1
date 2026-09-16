param(
    [string]$Src = (Join-Path $env:TEMP 'meepnet_decompile\MeepNetAI'),
    [string]$Json = 'E:\编码仓库\QY\ModLocalizePatch\localizations\GRAVNetAI\zh.json',
    [string]$SrcLoc = 'E:\编码仓库\QY\ModLocalizePatch\localizations',
    [string]$Patch = 'E:\编码仓库\QY\ModLocalizePatch\ModLocalizePatch\MeepNetPatches.cs'
)

# Comprehensive result validation for the GRAVNetAI rename + MeepNetPatches (Plan A).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dst = Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods\Local\ModLocalizePatch'
$fail = 0

Write-Output '=== [1] exact/replace keys must appear VERBATIM as string literals in decompiled source ==='
$j = Get-Content -Raw -Encoding UTF8 $Json | ConvertFrom-Json
$exactKeys = @($j.exact.PSObject.Properties.Name)
$replaceKeys = @($j.replace.PSObject.Properties.Name)
$all = ''
Get-ChildItem $Src -Filter *.cs -File | ForEach-Object { $all += [System.IO.File]::ReadAllText($_.FullName) }
foreach ($k in $exactKeys)
{
    if (-not $all.Contains('"' + $k + '"'))
    {
        Write-Output ('  MISS(exact)  ' + $k); $fail++
    }
}
foreach ($k in $replaceKeys)
{
    if (-not $all.Contains('"' + $k + '"'))
    {
        Write-Output ('  MISS(replace) [' + $k + ']'); $fail++
    }
}
Write-Output ('  exact=' + $exactKeys.Count + ' replace=' + $replaceKeys.Count + ' -> verbatim misses=' + $fail)

Write-Output ''
Write-Output '=== [2] rename completeness (source) ==='
Write-Output ('  source GRAVNetAI dir exists : ' + (Test-Path (Join-Path $SrcLoc 'GRAVNetAI')))
Write-Output ('  source MeepNetAI dir gone   : ' + (-not (Test-Path (Join-Path $SrcLoc 'MeepNetAI'))))
$cfg = Get-Content -Raw -Encoding UTF8 (Join-Path $SrcLoc 'config.json') | ConvertFrom-Json
$vals = @($cfg.steamIdMapping.PSObject.Properties | ForEach-Object { $_.Value })
Write-Output ('  config values -> GRAVNetAI  : ' + (($vals | Where-Object { $_ -eq 'GRAVNetAI' }).Count) + ' (expect 2)')
Write-Output ('  config any value == MeepNetAI (expect False): ' + ($vals -contains 'MeepNetAI'))

Write-Output ''
Write-Output '=== [3] MeepNetPatches.cs config ==='
$pc = [System.IO.File]::ReadAllText($Patch)
Write-Output ('  LIB_FOLDER = GRAVNetAI      : ' + ($pc -match 'LIB_FOLDER = "GRAVNetAI"'))
Write-Output ('  GATE_TYPE  = MeepNetAI.MeepNetStrings : ' + ($pc -match 'MeepNetAI\.MeepNetStrings'))
Write-Output ('  patches LocText.set_text    : ' + ($pc -match 'set_text'))

Write-Output ''
Write-Output '=== [4] deployed mirror integrity ==='
$dl = Join-Path $dst 'localizations'
Write-Output ('  deployed GRAVNetAI/zh.json  : ' + (Test-Path (Join-Path $dl 'GRAVNetAI\zh.json')))
Write-Output ('  deployed stale MeepNetAI gone: ' + (-not (Test-Path (Join-Path $dl 'MeepNetAI'))))
$dj = Get-Content -Raw -Encoding UTF8 (Join-Path $dl 'GRAVNetAI\zh.json') | ConvertFrom-Json
Write-Output ('  deployed zh.json counts     : translations=' + ($dj.translations.PSObject.Properties | Measure-Object).Count + ' exact=' + ($dj.exact.PSObject.Properties | Measure-Object).Count + ' replace=' + ($dj.replace.PSObject.Properties | Measure-Object).Count)
$dcfg = Get-Content -Raw -Encoding UTF8 (Join-Path $dl 'config.json') | ConvertFrom-Json
Write-Output ('  deployed cfg 3778736902 ->   : ' + $dcfg.steamIdMapping.'3778736902')
$dll = Get-Item (Join-Path $dst 'ModLocalizePatch.dll')
Write-Output ('  deployed DLL KB / time      : ' + [math]::Round($dll.Length/1KB, 1) + ' / ' + $dll.LastWriteTime.ToString('MM-dd HH:mm'))
$sdll = Get-Item 'E:\编码仓库\QY\ModLocalizePatch\ModLocalizePatch.dll'
Write-Output ('  source DLL KB / time        : ' + [math]::Round($sdll.Length/1KB, 1) + ' / ' + $sdll.LastWriteTime.ToString('MM-dd HH:mm'))

Write-Output ''
Write-Output ('=== RESULT: ' + $( if ($fail -eq 0)
{
    'exact/replace all verbatim-matched'
}
else
{
    "$fail MISS(ES)"
} ) + ' ===')
