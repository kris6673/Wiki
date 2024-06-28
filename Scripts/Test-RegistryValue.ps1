
function Test-RegistryValue {
    <#
.SYNOPSIS
    Tests if a registry value matches a specified value.

.DESCRIPTION
    The Test-RegistryValue function is used to check if a registry value matches a specified value. It retrieves the value of a specified registry key and compares it with the provided value. 
    If the values match, the function returns $true; otherwise, it returns $false.

.PARAMETER Path
    Specifies the path to the registry key.

.PARAMETER KeyName
    Specifies the name of the registry key.

.PARAMETER Value
    Specifies the value to compare against the registry value.

.EXAMPLE
    Test-RegistryValue -Path "HKCU:\Software\MyApp" -KeyName "Version" -Value "1.0"
    This example tests if the registry value "Version" under the "HKCU:\Software\MyApp" key matches the value "1.0".

.EXAMPLE
    Below is an example of how to use this function in a script:
    $Keys = [System.Collections.Generic.List[Object]]::new()
$Keys.Add([PSCustomObject]@{
        Path    = 'HKLM:\SOFTWARE\WOW6432Node\Lenovo\Dock Manager\User Settings\General'
        KeyName = 'AskBeforeFirmwareUpdate'
        Value   = 'NO'
    })
    $ErrorCount = 0
foreach ($Key in $Keys) {
    if (-not (Test-RegistryValue -Path $Key.Path -KeyName $Key.KeyName -Value $Key.Value)) {
        $ErrorCount++
    }
}
.OUTPUTS
    System.Boolean
    This function returns a Boolean value indicating whether the registry value matches the specified value.

.NOTES
    Author: Kris6673
    Date:   2024-01-26
#>
    param (
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]$Path,
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]$KeyName,
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()]$Value
    )
    try {
        $KeyValue = Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $KeyName -ErrorAction Stop
        if ($KeyValue -eq $Value) {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
    
}