param([string]$DllPath)
$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$res = New-Object System.Collections.Generic.List[string]
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $ch = [BitConverter]::ToUInt16($bytes, $i)
    if ($ch -ge 0x20 -and $ch -le 0x7E)
    {
        [void]$sb.Append([char]$ch)
    }
    else
    {
        if ($sb.Length -ge 10)
        {
            $res.Add($sb.ToString())
        }; [void]$sb.Clear()
    }
}
$res | Where-Object { $_ -match 'erupt|pressur|periodic|A large|A high|A fissure|hot ' } | Select-Object -Unique
