param(
    [string]$JsonPath,
    [string]$PotPath,
    [string]$OutputPath
)

# 读取 zh.json
$json = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$translations = $json.translations

# 读取 pot 模板，提取 msgctxt -> msgid 映射
$potContent = Get-Content $PotPath -Raw -Encoding UTF8
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

    # .po 格式：双引号转义为 \"；中文来自 JSON 的换行符需转为 \n
    $englishEsc = $english -replace '"', '\"'
    $chineseEsc = ($chinese -replace "`r`n", '\n') -replace "`n", '\n' -replace '"', '\"'

    [void]$sb.AppendLine("#. $key")
    [void]$sb.AppendLine("msgctxt `"$key`"")
    [void]$sb.AppendLine("msgid `"$englishEsc`"")
    [void]$sb.AppendLine("msgstr `"$chineseEsc`"")
    [void]$sb.AppendLine('')
}

$sb.ToString() | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "Generated: $OutputPath ($( $entries.Count ) entries)"
