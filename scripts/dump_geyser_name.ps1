param(
    [string]$DllPath,
    [string]$KeyName
)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$needleBytes = [System.Text.Encoding]::Unicode.GetBytes($KeyName)

for ($i = 0; $i -le ($bytes.Length - $needleBytes.Length); $i++) {
    $found = $true
    for ($j = 0; $j -lt $needleBytes.Length; $j++) {
        if ($bytes[$i + $j] -ne $needleBytes[$j])
        {
            $found = $false
            break
        }
    }
    if ($found)
    {
        # Extract the value string after the key
        $start = $i + $needleBytes.Length
        $valueStr = ""
        for ($k = $start; $k -lt [Math]::Min($bytes.Length, $start + 500); $k += 2) {
            $ch = [BitConverter]::ToUInt16($bytes, $k)
            if ($ch -eq 0)
            {
                break
            }
            if ($ch -ge 0x20 -and $ch -le 0x7E)
            {
                $valueStr += [char]$ch
            }
            elseif ($ch -gt 0x7E)
            {
                $valueStr += "<U+$( "{0:X4}" -f $ch )>"
            }
            else
            {
                $valueStr += "."
            }
        }
        Write-Output "Key: $KeyName"
        Write-Output "Value: $valueStr"
        Write-Output "---"
        break
    }
}
