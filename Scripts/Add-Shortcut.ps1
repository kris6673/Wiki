function Test-RunningAsSystem {
    <#
.SYNOPSIS
    Checks if the current user is running as the SYSTEM account.

.DESCRIPTION
    The Test-RunningAsSystem function determines if the current user is the SYSTEM account by comparing the user SID to 'S-1-5-18'.

.OUTPUTS
    [bool] True if the current user is the SYSTEM account, otherwise False.
.
.EXAMPLE
    PS C:\> Test-RunningAsSystem
    True

.NOTES
    The function uses the 'whoami -user' command to retrieve the current user's SID and checks if it matches 'S-1-5-18', which is the SID for the SYSTEM account.
#>
    [CmdletBinding()]
    param()
    process {
        return [bool]($(whoami -user) -match 'S-1-5-18')
    }
}
function Get-DesktopDir {
    <#
    .SYNOPSIS
    Retrieves the path to the desktop directory.

    .DESCRIPTION
    The Get-DesktopDir function determines the path to the desktop directory. 
    If the script is running as the SYSTEM user, it returns the public desktop directory path.
    Otherwise, it returns the current user's desktop directory path.

    .OUTPUTS
    String
    The path to the desktop directory.

    .EXAMPLE 
    When running as a regular user
    PS> Get-DesktopDir
    C:\Users\CurrentUser\Desktop

    .EXAMPLE
    When running as SYSTEM
    PS> Get-DesktopDir
    C:\Users\Public\Desktop

    .NOTES
    This function uses the Test-RunningAsSystem function to check if the script is running as the SYSTEM user.
    #>
    [CmdletBinding()]
    param()
    process {
        if (Test-RunningAsSystem) {
            $desktopDir = Join-Path -Path $env:PUBLIC -ChildPath 'Desktop'
        } else {
            $desktopDir = $([Environment]::GetFolderPath('Desktop'))
        }
        return $desktopDir
    }
}

function Add-Shortcut {
    <#
    .SYNOPSIS
    Creates a shortcut on the desktop.

    .DESCRIPTION
    This script creates a shortcut on the desktop with the specified target path, display name, optional arguments, and optional icon file. 
    The script determines the file extension based on whether the target path is a URL (uses .url) or a file path (uses .lnk).

    .PARAMETER ShortcutTargetPath
    The target path for the shortcut. This can be a URL or a file path.

    .PARAMETER ShortcutDisplayName
    The display name for the shortcut. This will be the name of the shortcut file on the desktop.

    .PARAMETER ShortcutArguments
    Optional. The arguments to pass to the shortcut target when it is executed.

    .PARAMETER IconFile
    Optional. The path to the icon file to use for the shortcut.

    .EXAMPLE
    .\Add-Shortcut.ps1 -ShortcutTargetPath "C:\Program Files\Example\example.exe" -ShortcutDisplayName "Example App"

    .EXAMPLE
    .\Add-Shortcut.ps1 -ShortcutTargetPath "https://www.example.com" -ShortcutDisplayName "Example Website" -IconFile "C:\Icons\example.ico"

    .EXAMPLE
    .\Add-Shortcut.ps1 -ShortcutTargetPath '\\server\share\Shared Folder' -ShortcutDisplayName 'Shared Folder' -IconFile "$env:SystemRoot\System32\shell32.dll,13"
    Adds a shortcut to a shared folder with a custom icon from shell32.dll.

    .NOTES
    The script uses the WScript.Shell COM object to create the shortcut and sets the appropriate properties based on the provided parameters.
    This function requires the Test-RunningAsSystem and Get-DesktopDir functions to be defined.
    Originally found from Andrew Taylor: https://andrewstaylor.com/
    Modified by Kris6673 aka me.
    #>
    param (
        [Parameter(Mandatory = $true)][string]$ShortcutTargetPath,
        [Parameter(Mandatory = $true)][string]$ShortcutDisplayName,
        [string]$ShortcutArguments,
        [string]$IconFile
    )

    # Test if the shortcut target path has https:// or http:// and if so, use .url file extension
    $Extension = if ($ShortcutTargetPath -match '^https?:\/\/') { '.url' } else { '.lnk' }

    $destinationPath = Join-Path -Path $(Get-DesktopDir) -ChildPath "$shortcutDisplayName$($Extension)"
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($destinationPath)
    $Shortcut.TargetPath = $ShortcutTargetPath
    
    # Set the shortcut arguments, if any
    if ($ShortcutArguments) {
        $Shortcut.Arguments = $ShortcutArguments
    }
    # Set the icon file, if any
    if ($IconFile) {
        $Shortcut.IconLocation = $IconFile
    }
    # Create the shortcut
    $Shortcut.Save()
    # Cleanup
    [Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null
}

Add-Shortcut -ShortcutTargetPath '\\Server01.domain.local\Printers' -ShortcutDisplayName 'Printers' -IconFile "$env:SystemRoot\System32\shell32.dll,58"