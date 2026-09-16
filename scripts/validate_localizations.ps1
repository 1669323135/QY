param(
    [Parameter(Mandatory = $true)]
    [string]$LocDir
)

# Validate every zh.json / config.json under the localizations directory parses as JSON.
$files = Get-ChildItem -Path $LocDir -Recurse -Filter *.json -File
$bad = 0
foreach ($f in $files)
{
    try
    {
        Get-Content -Raw -Encoding UTF8 $f.FullName | ConvertFrom-Json | Out-Null
        Write-Output ("OK   " + $f.Name + "  [" + $f.Directory.Name + "]")
    }
    catch
    {
        $bad++
        Write-Output ("BAD  " + $f.FullName + "  :: " + $_.Exception.Message)
    }
}
Write-Output ("Total JSON files: " + $files.Count + " ; invalid: " + $bad)
