param(
    [Parameter(Mandatory = $true)]
    [string]$ModDir,
    [Parameter(Mandatory = $true)]
    [string]$KeyNeedle
)

# Resolve the main DLL in $ModDir (skipping PLib), then dump a printable window
# around each occurrence of $KeyNeedle (ASCII and UTF-16LE) to read string values.
$dll = Get-ChildItem -Path $ModDir -Filter *.dll -File | Where-Object { $_.Name -notmatch 'PLib' } | Select-Object -First 1
if (-not $dll)
{
    Write-Output "no dll found"; exit
}
Write-Output ("DLL: " + $dll.Name)

$bytes = [System.IO.File]::ReadAllBytes($dll.FullName)

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

foreach ($mode in @(@{ uni = $false }, @{ uni = $true }))
{
    if ($mode.uni)
    {
        $p = [System.Text.Encoding]::Unicode.GetBytes($KeyNeedle)
    }
    else
    {
        $p = [System.Text.Encoding]::ASCII.GetBytes($KeyNeedle)
    }
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
            Write-Output ("[" + $enc + "] " + (Dump-Window $bytes $i $p.Length 5 160 $mode.uni))
        }
    }
}
