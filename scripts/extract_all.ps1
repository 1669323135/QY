[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Extract-UTF16Strings
{
    param([string]$dllPath, [string]$label)
    $bytes = [System.IO.File]::ReadAllBytes($dllPath)
    Write-Output "=== $label ==="
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
    Write-Output ""
}

Extract-UTF16Strings 'E:\coding_temp_nickel.dll' 'NICKEL'
Extract-UTF16Strings 'E:\coding_temp_salt.dll' 'SALT'
Extract-UTF16Strings 'E:\coding_temp_iridium.dll' 'IRIDIUM'
