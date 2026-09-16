$repoRoot = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $repoRoot 'ModLocalizePatch\localizations\BionicBoostersPlus\zh.json'
$potPath = Join-Path $repoRoot 'mods\3798248283\translations\translation_template.pot'
$outPath = Join-Path $env:USERPROFILE 'Documents\Klei\OxygenNotIncluded\mods\Steam\3798248283\translations\zh.po'

# 读取 zh.json
$jsonObj = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$translations = @{ }
$jsonObj.translations.PSObject.Properties | ForEach-Object { $translations[$_.Name] = $_.Value }

# 读取 pot 模板，提取 msgctxt -> msgid 映射
$potContent = Get-Content $potPath -Raw -Encoding UTF8
$entries = @{ }
$currentMsgctxt = $null
$currentMsgid = $null

foreach ($line in ($potContent -split "`n"))
{
    $line = $line.Trim()
    if ($line -match '^msgctxt\s+"(.+)"$')
    {
        $currentMsgctxt = $Matches[1]
    }
    elseif ($line -match '^msgid\s+"(.*)"$')
    {
        $currentMsgid = $Matches[1]
        if ($currentMsgctxt -and $currentMsgid -ne $null)
        {
            $entries[$currentMsgctxt] = $currentMsgid
        }
    }
}

# 生成 .po 文件
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('msgid ""')
[void]$sb.AppendLine('msgstr ""')
[void]$sb.AppendLine('"Language: zh\n"')
[void]$sb.AppendLine('')

foreach ($key in $entries.Keys | Sort-Object)
{
    $english = $entries[$key]
    $chinese = if ( $translations.ContainsKey($key))
    {
        $translations[$key]
    }
    else
    {
        $english
    }

    # .po 格式：英文来自 pot 模板已正确转义，保持原样；中文来自 JSON 需转义双引号和换行
    $englishEsc = $english
    $chineseEsc = ($chinese -replace "`r`n", '\n') -replace "`n", '\n' -replace '"', '\"'

    [void]$sb.AppendLine("#. $key")
    [void]$sb.AppendLine("msgctxt `"$key`"")
    [void]$sb.AppendLine("msgid `"$englishEsc`"")
    [void]$sb.AppendLine("msgstr `"$chineseEsc`"")
    [void]$sb.AppendLine('')
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$content = $sb.ToString() -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($outPath, $content, $utf8NoBom)
Write-Host "Generated: $outPath ($( $entries.Count ) entries)"
