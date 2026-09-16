param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

# Display width: CJK / fullwidth / wide symbols count as 2 columns, others 1.
function Get-DispWidth([string]$s)
{
    if ( [string]::IsNullOrEmpty($s))
    {
        return 0
    }
    $w = 0
    foreach ($ch in $s.ToCharArray())
    {
        $c = [int]$ch
        $wide = $false
        if ($c -ge 0x1100 -and $c -le 0x115F)
        {
            $wide = $true
        }
        elseif ($c -ge 0x2E80 -and $c -le 0xA4CF)
        {
            $wide = $true
        }
        elseif ($c -ge 0xAC00 -and $c -le 0xD7A3)
        {
            $wide = $true
        }
        elseif ($c -ge 0xF900 -and $c -le 0xFAFF)
        {
            $wide = $true
        }
        elseif ($c -ge 0xFE30 -and $c -le 0xFE4F)
        {
            $wide = $true
        }
        elseif ($c -ge 0xFF00 -and $c -le 0xFF60)
        {
            $wide = $true
        }
        elseif ($c -ge 0xFFE0 -and $c -le 0xFFE6)
        {
            $wide = $true
        }
        elseif ($c -ge 0x2600 -and $c -le 0x27BF)
        {
            $wide = $true
        }
        elseif ($c -ge 0x2B00 -and $c -le 0x2BFF)
        {
            $wide = $true
        }
        elseif ($c -ge 0x1F300)
        {
            $wide = $true
        }
        if ($wide)
        {
            $w += 2
        }
        else
        {
            $w += 1
        }
    }
    return $w
}

function Test-SepCell([string]$c)
{
    return ($c -match '^:?-{2,}:?$')
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$lines = [System.IO.File]::ReadAllLines($Path, $utf8NoBom)
$out = New-Object System.Collections.Generic.List[string]

$i = 0
while ($i -lt $lines.Count)
{
    $trim = $lines[$i].Trim()
    if ($trim.StartsWith('|') -and $trim.EndsWith('|') -and $trim.Length -gt 1)
    {
        $block = New-Object System.Collections.Generic.List[string]
        while ($i -lt $lines.Count)
        {
            $t2 = $lines[$i].Trim()
            if ($t2.StartsWith('|') -and $t2.EndsWith('|') -and $t2.Length -gt 1)
            {
                $block.Add($lines[$i])
                $i++
            }
            else
            {
                break
            }
        }
        $rows = New-Object System.Collections.Generic.List[object]
        $sepIndex = -1
        $colCount = 0
        for ($r = 0; $r -lt $block.Count; $r++) {
            $inner = $block[$r].Trim()
            $inner = $inner.Substring(1, $inner.Length - 2)
            $cells = @($inner -split '\|' | ForEach-Object { $_.Trim() })
            $rows.Add($cells)
            if ($cells.Count -gt $colCount)
            {
                $colCount = $cells.Count
            }
            $isSep = $true
            foreach ($cc in $cells)
            {
                if (-not (Test-SepCell $cc))
                {
                    $isSep = $false; break
                }
            }
            if ($isSep -and $sepIndex -lt 0)
            {
                $sepIndex = $r
            }
        }
        $W = New-Object 'int[]' $colCount
        for ($r = 0; $r -lt $rows.Count; $r++) {
            if ($r -eq $sepIndex)
            {
                continue
            }
            $cells = $rows[$r]
            for ($c = 0; $c -lt $colCount; $c++) {
                $val = ''
                if ($c -lt $cells.Count)
                {
                    $val = $cells[$c]
                }
                $dw = Get-DispWidth $val
                if ($dw -gt $W[$c])
                {
                    $W[$c] = $dw
                }
            }
        }
        for ($r = 0; $r -lt $rows.Count; $r++) {
            $parts = New-Object System.Collections.Generic.List[string]
            for ($c = 0; $c -lt $colCount; $c++) {
                if ($r -eq $sepIndex)
                {
                    $parts.Add(' ' + ('-' * $W[$c]) + ' ')
                }
                else
                {
                    $val = ''
                    if ($c -lt $rows[$r].Count)
                    {
                        $val = $rows[$r][$c]
                    }
                    $pad = $W[$c] - (Get-DispWidth $val)
                    if ($pad -lt 0)
                    {
                        $pad = 0
                    }
                    $parts.Add(' ' + $val + (' ' * $pad) + ' ')
                }
            }
            $out.Add('|' + ($parts -join '|') + '|')
        }
    }
    else
    {
        $out.Add($lines[$i])
        $i++
    }
}

[System.IO.File]::WriteAllLines($Path, $out, $utf8NoBom)
Write-Output ("ALIGNED lines=" + $out.Count)
