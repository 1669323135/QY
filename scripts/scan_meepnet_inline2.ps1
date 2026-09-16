param(
    [string]$Src = (Join-Path $env:TEMP 'meepnet_decompile\MeepNetAI')
)

# Supplementary scan: catch user-facing literals the first pass missed -
# SideScreen GetTitle(), Notification popups, SetText/.text/.toolTip with short
# literals, and string-returning UI helper methods.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$exclude = @('MeepNetStrings.cs')
$pat = 'GetTitle\(\)|new Notification\(|\.SetText\(|\.text\s*=|\.toolTip\s*=|override string|return "'

Get-ChildItem $Src -Filter *.cs -File | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
    $file = $_
    $lines = [System.IO.File]::ReadAllLines($file.FullName)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match $pat)
        {
            foreach ($m in [regex]::Matches($line, '"([^"]{2,})"'))
            {
                $lit = $m.Groups[1].Value
                # keep human-readable text; drop ids/anims/keys/pure-format
                if ($lit -notmatch 'kanim|_anim|^MeepNet|^GRAVNet AI\]|STRINGS\.|http|^ui$|^object$|Sprites/|UI/Default|^[A-Za-z0-9_]+$' -and ($lit -match '[a-z]' -or $lit -match '\u2014|\u00b7|\u2192'))
                {
                    Write-Output ($file.Name + ':' + ($i + 1) + ': ' + $lit)
                }
            }
        }
    }
}
