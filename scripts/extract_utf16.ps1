[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$dllPath = 'E:\coding_temp_caramel.dll'
$bytes = [System.IO.File]::ReadAllBytes($dllPath)

# Extract UTF-16LE strings (ONI DLLs store string literals as UTF-16LE)
Write-Output "=== UTF-16LE STRINGS (len >= 3) ==="
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $ch = [BitConverter]::ToUInt16($bytes, $i)
    if ($ch -ge 0x20 -and $ch -le 0x7E)
    {
        [void]$sb.Append([char]$ch)
    }
    else
    {
        if ($sb.Length -ge 3)
        {
            Write-Output "  $($sb.ToString() )"
        }
        [void]$sb.Clear()
    }
}
