param([int]$Tail = 70)

# Inspect ONI Player.log for ModLocalizePatch / MeepNetAI(GRAVNetAI) runtime evidence.
# ASCII-only script (no BOM needed); Chinese comes from the log content read as UTF-8.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$log = Join-Path $env:USERPROFILE 'AppData\LocalLow\Klei\Oxygen Not Included\Player.log'
if (-not (Test-Path $log))
{
    Write-Output 'LOG NOT FOUND (game may never have run): '; Write-Output $log; exit
}

$item = Get-Item $log
Write-Output ('log LastWriteTime : ' + $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Output ('log size KB       : ' + [math]::Round($item.Length / 1KB, 1))
Write-Output ('deploy was at     : 2026-09-16 00:56  (log must be NEWER to reflect changes)')

$c = Get-Content -Encoding UTF8 $log
Write-Output ('total log lines   : ' + $c.Count)

$mlp = @($c | Select-String -SimpleMatch '[ModLocalizePatch]')
Write-Output ''
Write-Output ('=== [ModLocalizePatch] entries: ' + $mlp.Count + ' total; showing last ' + $Tail + ' ===')
$mlp | Select-Object -Last $Tail | ForEach-Object { Write-Output $_.Line }

Write-Output ''
Write-Output '=== GRAVNetAI / MeepNetAI / LocText patch evidence ==='
$ev = @($c | Select-String -Pattern 'GRAVNetAI|MeepNetAI|LocText')
Write-Output ('matches: ' + $ev.Count)
$ev | Select-Object -Last 25 | ForEach-Object { Write-Output $_.Line }

Write-Output ''
Write-Output '=== errors / exceptions (Harmony, patch, our mod) ==='
$err = @($c | Select-String -Pattern 'Exception|AmbiguousMatch|Undefined target|HarmonyException|NullReference' | Select-String -Pattern 'Localize|MeepNet|LocText|Strings|Harmony')
Write-Output ('matches: ' + $err.Count)
$err | Select-Object -Last 20 | ForEach-Object { Write-Output $_.Line }
