[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dllPath = 'E:\coding_temp_geyser.dll'
$bytes = [System.IO.File]::ReadAllBytes($dllPath)

# Find #US header in .NET metadata
# Search for "#US" or "#Strings" or "#~" markers
$text = [System.Text.Encoding]::ASCII.GetString($bytes)

# Extract all readable strings including Unicode (UTF-16LE)
Write-Output "=== ASCII STRINGS (len >= 3) ==="
$sb = New-Object System.Text.StringBuilder
$asciiResults = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -ge 0x20 -and $b -le 0x7E)
    {
        [void]$sb.Append([char]$b)
    }
    else
    {
        if ($sb.Length -ge 3)
        {
            $asciiResults.Add($sb.ToString())
        }
        [void]$sb.Clear()
    }
}
$asciiResults | ForEach-Object { Write-Output "  $_" }

Write-Output ""
Write-Output "=== UTF-16LE STRINGS (len >= 3) ==="
$sb2 = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $ch = [BitConverter]::ToUInt16($bytes, $i)
    if ($ch -ge 0x20 -and $ch -le 0x7E)
    {
        [void]$sb2.Append([char]$ch)
    }
    else
    {
        if ($sb2.Length -ge 3)
        {
            Write-Output "  $($sb2.ToString() )"
        }
        [void]$sb2.Clear()
    }
}

# Also look for compressed string blobs (#US heap uses compressed length prefix)
Write-Output ""
Write-Output "=== SEARCHING FOR SPECIFIC PATTERNS ==="
$patterns = @('Ethanol', 'ethanol', 'Geyser', 'geyser', 'STRINGS', 'Alcohol', 'alcohol', 'Liquid', 'liquid', 'Generic', 'generic')
foreach ($pat in $patterns)
{
    $patBytes = [System.Text.Encoding]::ASCII.GetBytes($pat)
    for ($i = 0; $i -lt ($bytes.Length - $patBytes.Length); $i++) {
        $found = $true
        for ($j = 0; $j -lt $patBytes.Length; $j++) {
            if ($bytes[$i + $j] -ne $patBytes[$j])
            {
                $found = $false; break
            }
        }
        if ($found)
        {
            # Extract surrounding context
            $start = [Math]::Max(0, $i - 20)
            $end = [Math]::Min($bytes.Length, $i + $patBytes.Length + 40)
            $ctx = ""
            for ($k = $start; $k -lt $end; $k++) {
                $b = $bytes[$k]
                if ($b -ge 0x20 -and $b -le 0x7E)
                {
                    $ctx += [char]$b
                }
                else
                {
                    $ctx += "."
                }
            }
            Write-Output "  Found '$pat' at offset $i : $ctx"
        }
    }
}
