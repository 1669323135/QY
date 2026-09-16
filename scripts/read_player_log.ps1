# read_player_log.ps1
$logPath = Join-Path $env:USERPROFILE 'AppData\LocalLow\Klei\Oxygen Not Included\Player.log'
if (Test-Path $logPath)
{
    Get-Content -LiteralPath $logPath -TotalCount 50
}
else
{
    Write-Host "Player.log not found at: $logPath"
}
