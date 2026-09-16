param(
    [Parameter(Mandatory = $true)]
    [string]$Root
)

# Self-contained full scan of every mod folder under $Root.
# For each mod report: title/staticID (from mod.yaml), whether it already ships
# author translations (.po under a translations/strings/Translations folder),
# and how many user-facing STRINGS.* keys are embedded in its DLLs.
# No nested powershell calls; string extraction is inlined (ASCII + UTF-16LE).

function Get-EmbeddedStrings([byte[]]$bytes)
{
    $out = New-Object System.Collections.Generic.List[string]
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
                $out.Add($sb.ToString())
            }; [void]$sb.Clear()
        }
    }
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
                $out.Add($sb2.ToString())
            }; [void]$sb2.Clear()
        }
    }
    return $out
}

$modDirs = Get-ChildItem -Path $Root -Directory | Sort-Object Name
foreach ($md in $modDirs)
{
    $title = ""
    $staticID = ""
    $yaml = Join-Path $md.FullName "mod.yaml"
    if (Test-Path $yaml)
    {
        foreach ($line in (Get-Content -Raw -Encoding UTF8 $yaml) -split "`n")
        {
            $t = $line.Trim()
            if ( $t.StartsWith("title:"))
            {
                $title = $t.Substring(6).Trim().Trim('"', "'")
            }
            elseif ($t.StartsWith("staticID:"))
            {
                $staticID = $t.Substring(9).Trim().Trim('"', "'")
            }
        }
    }

    # author-provided translations?
    $poCount = (Get-ChildItem -Path $md.FullName -Recurse -Filter *.po -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $zhPo = (Get-ChildItem -Path $md.FullName -Recurse -Filter zh*.po -File -ErrorAction SilentlyContinue | Measure-Object).Count

    # STRINGS.* keys embedded in DLLs
    $keySet = New-Object System.Collections.Generic.HashSet[string]
    foreach ($dll in (Get-ChildItem -Path $md.FullName -Filter *.dll -File -ErrorAction SilentlyContinue))
    {
        try
        {
            $bytes = [System.IO.File]::ReadAllBytes($dll.FullName)
            foreach ($s in (Get-EmbeddedStrings $bytes))
            {
                if ($s -match '^STRINGS\.[A-Za-z0-9_.]+$')
                {
                    [void]$keySet.Add($s)
                }
            }
        }
        catch
        {
        }
    }

    $flag = ""
    if ($zhPo -gt 0)
    {
        $flag = "HAS_ZH_PO"
    }
    elseif ($poCount -gt 0)
    {
        $flag = "HAS_PO(no-zh)"
    }
    elseif ($keySet.Count -gt 0)
    {
        $flag = "CANDIDATE"
    }
    else
    {
        $flag = "no-strings"
    }

    Write-Output ("[" + $md.Name + "] " + $flag + " | title=" + $title + " | staticID=" + $staticID + " | po=" + $poCount + " zhpo=" + $zhPo + " STRINGSkeys=" + $keySet.Count)
    if ($keySet.Count -gt 0 -and $zhPo -eq 0)
    {
        $keySet | Select-Object -First 12 | ForEach-Object { Write-Output ("      " + $_) }
    }
}
