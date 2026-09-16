param([string]$DllPath)

# Read DLL as bytes and search for UTF-16LE strings (common in .NET)
$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$text = [System.Text.Encoding]::Unicode.GetString($bytes)
$lines = $text -split "`0" | Where-Object { $_.Length -ge 5 -and $_ -match '[\x20-\x7E]' }

# Search for booster-related strings
$hits = $lines | Where-Object { $_ -match 'BB_BOOSTER_(SOLAR|MEDIKIT)|SolarBooster|MedkitBooster|Biomechanical|Subdermal|description|Description|DESC' }
$hits | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
