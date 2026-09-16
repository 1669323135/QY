param([string]$DllPath)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$text = [System.Text.Encoding]::Unicode.GetString($bytes)
$lines = $text -split "`0" | Where-Object { $_.Length -ge 3 -and $_ -match '[\x20-\x7E]' }

# Search for description-related patterns
$hits = $lines | Where-Object { $_ -match 'description|Description|GetDescription|desc|Desc|tooltip|Tooltip|EFFECT|EFFECT_DESC' }
$hits | Select-Object -First 30 | ForEach-Object { Write-Host $_ }
