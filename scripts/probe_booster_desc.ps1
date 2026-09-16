param([string]$DllPath)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$lines = $text -split [Environment]::NewLine | Where-Object { $_.Length -ge 3 }
$hits = $lines | Where-Object { $_ -match 'BB_BOOSTER_SOLAR|BB_BOOSTER_MEDIKIT|SolarBooster|MedkitBooster|Biomechanical|Subdermal|BB_BOOSTER_BATTERY|BB_BOOSTER_WATER|BB_BOOSTER_DREAM' }
$hits | Select-Object -First 50
