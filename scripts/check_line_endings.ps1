param([string]$PoPath)

$bytes = [System.IO.File]::ReadAllBytes($PoPath)
$crlfCount = 0
$lfCount = 0

for ($i = 0; $i -lt $bytes.Length - 1; $i++) {
    if ($bytes[$i] -eq 13 -and $bytes[$i + 1] -eq 10)
    {
        $crlfCount++
        $i++ # Skip next byte
    }
    elseif ($bytes[$i] -eq 10)
    {
        $lfCount++
    }
}

Write-Host "CRLF count: $crlfCount"
Write-Host "LF count: $lfCount"

if ($crlfCount -gt 0)
{
    Write-Host "File has CRLF line endings"
}
else
{
    Write-Host "File has LF line endings"
}
