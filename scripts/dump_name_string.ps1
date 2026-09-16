param(
    [string]$DllPath,
    [string]$Needle
)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$needleBytes = [System.Text.Encoding]::Unicode.GetBytes($Needle)

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
        $end = [Math]::Min($bytes.Length - 1, $i + ($needleBytes.Length * 4) + 400)
        $ctx = ""
        for ($k = $i; $k -lt $end; $k += 2) {
            $ch = [BitConverter]::ToUInt16($bytes, $k)
            if ($ch -ge 0x20 -and $ch -le 0x7E)
            {
                $ctx += [char]$ch
            }
            elseif ($ch -eq 0)
            {
                $ctx += "|"
            }
            else
            {
                $ctx += "."
            }
        }
        Write-Output $ctx
        break
    }
}
