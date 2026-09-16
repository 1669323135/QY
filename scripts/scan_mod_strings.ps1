param(
    [Parameter(Mandatory = $true)]
    [string]$Root,
    [Parameter(Mandatory = $true)]
    [string[]]$Dirs
)

# Scan each mod folder's DLLs for user-facing localization keys (STRINGS.*),
# reporting which mods still contain untranslated string keys.
foreach ($d in $Dirs)
{
    $folder = Join-Path $Root $d
    if (-not (Test-Path $folder))
    {
        continue
    }
    $dlls = Get-ChildItem $folder -Filter *.dll -File
    foreach ($dll in $dlls)
    {
        $keys = & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'extract_mod_strings.ps1') -DllPath $dll.FullName -Filter 'STRINGS\.'
        if ($keys)
        {
            Write-Output ("### " + $d + " / " + $dll.Name)
            $keys | Select-Object -First 30 | ForEach-Object { Write-Output ("  " + $_) }
        }
    }
}
