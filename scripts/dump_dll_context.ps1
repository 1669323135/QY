param(
    [Parameter(Mandatory = $true)]
    [string]$DllPath,
    [Parameter(Mandatory = $true)]
    [string]$Needle,
    [int]$Before = 10,
    [int]$After = 200
)

# Dump a printable-ASCII window around every occurrence of $Needle in the DLL,
# so split/localization strings that are not contiguous runs can still be read.
$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$pat = [System.Text.Encoding]::ASCII.GetBytes($Needle)
$patU = [System.Text.Encoding]::Unicode.GetBytes($Needle)

function Dump-Window([byte[]]$bytes, [int]$i, [int]$len, [int]$Before, [int]$After, [bool]$unicode)
{
    if ($unicode)
    {
        $start = [Math]::Max(0, $i - ($Before * 2))
        $end = [Math]::Min($bytes.Length - 1, $i + $len + ($After * 2))
        $ctx = ""
        for ($k = $start; $k -lt $end; $k += 2) {
            $ch = [BitConverter]::ToUInt16($bytes, $k)
            if ($ch -ge 0x20 -and $ch -le 0x7E)
            {
                $ctx += [char]$ch
            }
            else
            {
                $ctx += "."
            }
        }
    }
    else
    {
        $start = [Math]::Max(0, $i - $Before)
        $end = [Math]::Min($bytes.Length, $i + $len + $After)
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
    }
    return $ctx
}

foreach ($mode in @(@{ pat = $pat; uni = $false }, @{ pat = $patU; uni = $true }))
{
    $p = $mode.pat
    for ($i = 0; $i -le ($bytes.Length - $p.Length); $i++) {
        $found = $true
        for ($j = 0; $j -lt $p.Length; $j++) {
            if ($bytes[$i + $j] -ne $p[$j])
            {
                $found = $false; break
            }
        }
        if ($found)
        {
            $enc = if ($mode.uni)
            {
                "UTF16"
            }
            else
            {
                "ASCII"
            }
            $ctx = Dump-Window $bytes $i $p.Length $Before $After $mode.uni
            Write-Output "[$enc] offset $i : $ctx"
            Write-Output "----"
        }
    }
}
