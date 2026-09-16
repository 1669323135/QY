param(
    [Parameter(Mandatory = $true)]
    [string]$DllPath,
    [string]$Filter = 'STRINGS|GEYSER|Geyser|geyser|MOLTEN|LIQUID|NAME|DESC|Volcano|Mercury|Zinc|Lead'
)

# Extract readable strings (ASCII and UTF-16LE) from a .NET DLL,
# keeping only lines that look like localization keys or geyser/element text.
$bytes = [System.IO.File]::ReadAllBytes($DllPath)

$results = New-Object System.Collections.Generic.List[string]

# ASCII strings
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bytes.Length; $i++) {
    $b = $bytes[$i]
    if ($b -ge 0x20 -and $b -le 0x7E)
    {
        [void]$sb.Append([char]$b)
    }
    else
    {
        if ($sb.Length -ge 4)
        {
            $results.Add($sb.ToString())
        }
        [void]$sb.Clear()
    }
}

# UTF-16LE strings
$sb2 = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $ch = [BitConverter]::ToUInt16($bytes, $i)
    if ($ch -ge 0x20 -and $ch -le 0x7E)
    {
        [void]$sb2.Append([char]$ch)
    }
    else
    {
        if ($sb2.Length -ge 4)
        {
            $results.Add($sb2.ToString())
        }
        [void]$sb2.Clear()
    }
}

$results | Where-Object { $_ -match $Filter } | Select-Object -Unique | ForEach-Object { Write-Output $_ }
