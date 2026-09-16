param(
    [string]$Doc = 'E:\编码仓库\QY\汉化文本校对文档.md'
)

# Scan the proofreading doc for any user-filled "修正后中文" cells (non-empty last column),
# and verify section structure after the GRAVNetAI rename.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$lines = [System.IO.File]::ReadAllLines($Doc)

$filled = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $t = $line.Trim()
    if (-not $t.StartsWith('|'))
    {
        continue
    }
    $cells = $line -split '\|'
    if ($cells.Count -lt 3)
    {
        continue
    }
    # correction cell = second-to-last (last is '' after trailing |)
    $corr = $cells[$cells.Count - 2].Trim()
    if ( [string]::IsNullOrEmpty($corr))
    {
        continue
    }
    if ($corr -match '^:?-{2,}:?$')
    {
        continue
    }        # separator row
    if ($corr -eq '※ 修正后中文')
    {
        continue
    }          # header row
    $key = $cells[1].Trim()
    $filled.Add(('line ' + ($i + 1) + ' | ' + $key + ' | 修正=> ' + $corr))
}

Write-Output ('=== user-filled 修正后中文 cells: ' + $filled.Count + ' ===')
$filled | ForEach-Object { Write-Output ('  ' + $_) }

Write-Output ''
Write-Output '=== structure checks ==='
Write-Output ('  六 header is GRAVNetAI      : ' + [bool]($lines | Select-String -SimpleMatch '## 六、GRAVNet AI and Infrastructure（GRAVNetAI）'))
Write-Output ('  6.11 inline section present : ' + [bool]($lines | Select-String -SimpleMatch '### 6.11 内联硬编码文本'))
Write-Output ('  七 统计概览 present          : ' + [bool]($lines | Select-String -SimpleMatch '## 七、统计概览'))
Write-Output ('  stray localizations/MeepNetAI path ref (expect 0): ' + (@($lines | Select-String -SimpleMatch 'localizations/MeepNetAI').Count))
Write-Output ('  total lines                 : ' + $lines.Count)
