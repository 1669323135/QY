param([string]$DllPath)

$bytes = [System.IO.File]::ReadAllBytes($DllPath)
$text = [System.Text.Encoding]::Unicode.GetString($bytes)
$lines = $text -split "`0" | Where-Object { $_.Length -ge 10 -and $_ -match '[\x20-\x7E]' }

# Search for specific English description texts
$searchTerms = @(
    'Grants a Bionic Duplicant the ability to dream',
    'Allows the installation of another power bank',
    'Actively coats the internal electric components',
    'Repairs both the organic tissue',
    'Installs small subdermal solar arrays'
)

foreach ($term in $searchTerms)
{
    $found = $lines | Where-Object { $_ -like "*$term*" }
    if ($found)
    {
        Write-Host "FOUND: $term"
        Write-Host "  Context: $($found.Substring(0,[Math]::Min(100, $found.Length)) )..."
    }
    else
    {
        Write-Host "NOT FOUND: $term"
    }
}
