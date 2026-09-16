param(
    [Parameter(Mandatory = $true)]
    [string]$ModDir,
    [int]$MinLen = 12
)

# Resolve the main DLL (skip PLib) and list human-readable text values:
# UTF-16LE runs that contain CJK characters OR look like English sentences
# (contain a space, length >= MinLen). Used to judge whether a mod's own
# building/UI text is still English (needs translation) or already localized.
$dll = Get-ChildItem -Path $ModDir -Filter *.dll -File | Where-Object { $_.Name -notmatch 'PLib' } | Select-Object -First 1
if (-not $dll)
{
    Write-Output "no dll found"; exit
}
Write-Output ("DLL: " + $dll.Name)

$bytes = [System.IO.File]::ReadAllBytes($dll.FullName)
$sb = New-Object System.Text.StringBuilder
$results = New-Object System.Collections.Generic.List[string]

# UTF-16LE, keep printable ASCII + CJK
for ($i = 0; $i -lt $bytes.Length - 1; $i += 2) {
    $ch = [BitConverter]::ToUInt16($bytes, $i)
    if (($ch -ge 0x20 -and $ch -le 0x7E) -or ($ch -ge 0x4E00 -and $ch -le 0x9FFF) -or $ch -eq 0xFF0C -or $ch -eq 0x3002)
    {
        [void]$sb.Append([char]$ch)
    }
    else
    {
        if ($sb.Length -ge $MinLen)
        {
            $results.Add($sb.ToString())
        }
        [void]$sb.Clear()
    }
}
if ($sb.Length -ge $MinLen)
{
    $results.Add($sb.ToString())
}

$results |
        Where-Object { ($_ -match '[\u4e00-\u9fff]') -or ($_ -match ' ') } |
        Select-Object -Unique |
        ForEach-Object { Write-Output $_ }
