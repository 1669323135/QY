# Inspect StringEntry structure
$asmPath = 'D:\Steam\steamapps\common\OxygenNotIncluded\OxygenNotIncluded_Data\Managed\Assembly-CSharp.dll'

try
{
    $asm = [System.Reflection.Assembly]::LoadFrom($asmPath)

    # Find StringEntry type
    $stringEntryType = $null
    foreach ($type in $asm.GetExportedTypes())
    {
        if ($type.Name -eq 'StringEntry')
        {
            $stringEntryType = $type
            break
        }
    }

    if ($stringEntryType)
    {
        Write-Output "=== StringEntry type found ==="
        Write-Output "Full name: $( $stringEntryType.FullName )"
        Write-Output ""

        Write-Output "=== All fields ==="
        $stringEntryType.GetFields([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance) | ForEach-Object {
            $visibility = if ($_.IsPublic)
            {
                'public'
            }
            else
            {
                'private'
            }
            Write-Output "$( $_.FieldType.Name ) $( $_.Name ) ($visibility)"
        }
        Write-Output ""

        Write-Output "=== All properties ==="
        $stringEntryType.GetProperties([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance) | ForEach-Object {
            Write-Output "$( $_.PropertyType.Name ) $( $_.Name ) (get:$( $_.CanRead ), set:$( $_.CanWrite ))"
        }
        Write-Output ""

        Write-Output "=== Constructors ==="
        $stringEntryType.GetConstructors([System.Reflection.BindingFlags]::Public -bor [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance) | ForEach-Object {
            $params = $_.GetParameters() | ForEach-Object { "$( $_.ParameterType.Name ) $( $_.Name )" }
            $visibility = if ($_.IsPublic)
            {
                'public'
            }
            else
            {
                'private'
            }
            Write-Output "$visibility StringEntry($( $params -join ', ' ))"
        }
    }
    else
    {
        Write-Output "StringEntry type not found"
    }
}
catch
{
    Write-Output "Error: $( $_.Exception.Message )"
}
