param([string]$PoPath)

$content = Get-Content $PoPath -Raw
$lines = $content -split "`n"

$entryCount = 0
$msgctxtCount = 0
$msgidCount = 0
$msgstrCount = 0

foreach ($line in $lines)
{
    $line = $line.TrimEnd("`r")
    if ($line -match '^msgctxt\s+"')
    {
        $msgctxtCount++
    }
    if ($line -match '^msgid\s+"')
    {
        $msgidCount++
    }
    if ($line -match '^msgstr\s+"')
    {
        $msgstrCount++
    }
}

Write-Host "msgctxt count: $msgctxtCount"
Write-Host "msgid count: $msgidCount"
Write-Host "msgstr count: $msgstrCount"

if ($msgctxtCount -eq $msgidCount -and $msgidCount -eq $msgstrCount)
{
    Write-Host "OK: All counts match"
}
else
{
    Write-Host "ERROR: Counts don't match!"
}

# Check for entries with empty msgstr
$emptyMsgstr = 0
$inEntry = $false
$currentKey = ""
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].TrimEnd("`r")
    if ($line -match '^msgctxt\s+"([^"]+)"')
    {
        $currentKey = $matches[1]
        $inEntry = $true
    }
    if ($inEntry -and $line -match '^msgstr\s+"([^"]*)"')
    {
        if ($matches[1] -eq "")
        {
            Write-Host "EMPTY msgstr for: $currentKey"
            $emptyMsgstr++
        }
        $inEntry = $false
    }
}

Write-Host "Empty msgstr count: $emptyMsgstr"
