param(
    [Parameter(Mandatory = $true)]
    [string]$DllPath,
    [string]$TypeFilter = ''
)

# Enumerate types and public/internal methods of a .NET assembly using
# ReflectionOnly load (metadata only, no execution), to choose Harmony patch points.
$asm = [System.Reflection.Assembly]::ReflectionOnlyLoadFrom($DllPath)
$types = $null
try
{
    $types = $asm.GetTypes()
}
catch [System.Reflection.ReflectionTypeLoadException]
{
    # Referenced game assemblies are absent; use the subset that did load.
    $types = $_.Exception.Types | Where-Object { $_ -ne $null }
}
foreach ($t in $types)
{
    if ($TypeFilter -and ($t.FullName -notmatch $TypeFilter))
    {
        continue
    }
    Write-Output ("TYPE " + $t.FullName)
    foreach ($m in $t.GetMethods([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly))
    {
        $ps = @()
        try
        {
            foreach ($p in $m.GetParameters())
            {
                $ps += ($p.ParameterType.Name + " " + $p.Name)
            }
        }
        catch
        {
            $ps = @("<unresolved>")
        }
        $rt = "?"
        try
        {
            $rt = $m.ReturnType.Name
        }
        catch
        {
            $rt = "<unresolved>"
        }
        Write-Output ("    " + $rt + " " + $m.Name + "(" + ($ps -join ", ") + ")")
    }
    foreach ($pr in $t.GetProperties([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly))
    {
        $pt = "?"
        try
        {
            $pt = $pr.PropertyType.Name
        }
        catch
        {
            $pt = "<unresolved>"
        }
        Write-Output ("    PROP " + $pt + " " + $pr.Name)
    }
    foreach ($f in $t.GetFields([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::DeclaredOnly))
    {
        $ft = "?"
        try
        {
            $ft = $f.FieldType.Name
        }
        catch
        {
            $ft = "<unresolved>"
        }
        Write-Output ("    FIELD " + $ft + " " + $f.Name)
    }
}
