param(
    [string]$Src = (Join-Path $env:TEMP 'meepnet_decompile\MeepNetAI')
)

# Comprehensive scan for inline user-facing English literals that bypass STRINGS keys.
# Excludes the central MeepNetStrings table and pure Strings.Add/Get registration files.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$exclude = @('MeepNetStrings.cs')

# Patterns that indicate a user-facing UI string assignment / attribute
$uiPattern = '\.text\s*=|\.toolTip\s*=|\.tooltip\s*=|SetText\(|new Notification\(|AddToolTip|\[Option\(|ToolTip\(|\.SetTitle|ShowTooltip|\.label\s*=|LocText'

# A "sentence-like" English literal: has a space, a lowercase letter, length >= 15
$sentencePattern = '"[A-Za-z][^"]*[a-z][^"]* [^"]*"'

Get-ChildItem $Src -Filter *.cs -File | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
    $file = $_
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match $uiPattern)
        {
            # extract quoted literals on this line that look like sentences
            foreach ($m in [regex]::Matches($line, '"([^"]{6,})"'))
            {
                $lit = $m.Groups[1].Value
                if ($lit -match ' ' -and $lit -match '[a-z]' -and $lit -notmatch 'kanim|_anim|prefab|STRINGS\.|MeepNet[A-Z]|GRAVNet AI\]|http')
                {
                    Write-Output ($file.Name + ':' + ($i + 1) + ': ' + $lit)
                }
            }
        }
    }
}
