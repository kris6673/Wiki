#Region Functions
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
# Logging function
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')]
        [string]$ForegroundColor = 'White'
    )

    $TimeGenerated = $(Get-Date -Format 'dd/MM/yy HH:mm:ss:fff')
    $Line = "$TimeGenerated : $Message"
    Write-Host $Line -ForegroundColor $ForegroundColor
}
function Get-DesktopDirectory {
    <#
    .SYNOPSIS
    Retrieves the path to the desktop directory.

    .DESCRIPTION
    The Get-DesktopDirectory function determines the path to the desktop directory. 
    If the script is running as the SYSTEM user, it returns the public desktop directory path.
    Otherwise, it returns the current user's desktop directory path.

    .OUTPUTS
    String
    The path to the desktop directory.

    .EXAMPLE 
    When running as a regular user
    PS> Get-DesktopDirectory
    C:\Users\CurrentUser\Desktop

    .EXAMPLE
    When running as SYSTEM
    PS> Get-DesktopDirectory
    C:\Users\Public\Desktop

    .NOTES
    This function uses the Test-RunningAsSystem function to check if the script is running as the SYSTEM user.
    #>
    [CmdletBinding()]
    param()
    process {
        if (Test-RunningAsSystem) {
            $DesktopDir = Join-Path -Path $env:PUBLIC -ChildPath 'Desktop'
        } else {
            $DesktopDir = $([Environment]::GetFolderPath('Desktop'))
        }
        return $DesktopDir
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
    This function requires the Test-RunningAsSystem and Get-DesktopDirectory functions to be defined.
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
    try {
        $Extension = if ($ShortcutTargetPath -match '^https?:\/\/') { '.url' } else { '.lnk' }
    
        $destinationPath = Join-Path -Path $(Get-DesktopDirectory) -ChildPath "$shortcutDisplayName$($Extension)"
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($destinationPath)
        $Shortcut.TargetPath = $ShortcutTargetPath
        
        # Set the shortcut arguments, if any
        if ($ShortcutArguments) {
            $Shortcut.Arguments = $ShortcutArguments
        }
        # Set the icon file, if any
        if ($IconFile -and $Extension -eq '.lnk') {
            $Shortcut.IconLocation = $IconFile
        }
        # Create the shortcut
        $Shortcut.Save()
        # Cleanup
        [Runtime.InteropServices.Marshal]::ReleaseComObject($WshShell) | Out-Null
        Write-Log "Successfully created shortcut $ShortcutDisplayName pointing to $ShortcutTargetPath."
        return 0
    } catch {
        Write-Log "Failed to create shortcut $ShortcutDisplayName pointing to $ShortcutTargetPath."
        Write-Log "Error is: $($_.Exception.Message)"
        return 1
    }
}

function Remove-Shortcut {
    <#
    .SYNOPSIS
    Removes a shortcut from the desktop.

    .DESCRIPTION
    This script removes a shortcut from the desktop based on the provided display name. Optionally, a target path can be supplied to determine the expected shortcut extension. 
    If no target path is provided, the script attempts to remove both .lnk and .url shortcuts with the given display name.

    .PARAMETER ShortcutDisplayName
    The display name for the shortcut. This is the name of the shortcut file on the desktop (without extension).

    .PARAMETER Force
    Optional. Forces deletion of the shortcut if set.

    .EXAMPLE
    .\Remove-Shortcut.ps1 -ShortcutDisplayName "Example App"

    .NOTES
    This function requires the Test-RunningAsSystem and Get-DesktopDirectory functions to be defined.
    Originally based on the Add-Shortcut script.
    #>
    param (
        [Parameter(Mandatory = $true)][string]$ShortcutDisplayName,
        [string]$ShortcutTargetPath,
        [switch]$Force
    )

    $DesktopDir = Get-DesktopDirectory
    $CandidatePaths = [System.Collections.Generic.List[string]]::new()

    $CandidatePaths.Add((Join-Path -Path $DesktopDir -ChildPath "$ShortcutDisplayName.lnk"))
    $CandidatePaths.Add((Join-Path -Path $DesktopDir -ChildPath "$ShortcutDisplayName.url"))

    $Removed = $false

    foreach ($path in $CandidatePaths | Sort-Object -Unique) {
        if (-not (Test-Path -Path $path -ErrorAction SilentlyContinue)) {
            continue
        }
        try {
            Remove-Item -Path $path -Force:$Force.IsPresent -ErrorAction Stop
            Write-Log "Successfully removed shortcut at $path"
            $Removed = $true
        } catch {
            Write-Log "Failed to remove shortcut at $path"
            Write-Log "Error is: $($_.Exception.Message)"
        }
        
    }

    if ($Removed -eq $false) {
        Write-Log "Shortcut '$ShortcutDisplayName' was not found on the desktop."
    }
    if ($Removed -eq $true) {
        return 0
    } else {
        return 1
    }
}


function Copy-Files {
    param (
        # Input path to files in the intunewin file. Should be something like: $PSScriptRoot\FolderName
        [Parameter(Mandatory = $true)]
        [string]$Source,
        # Input path to where files should be copied to. Should be something like: $Env:USERPROFILE\Pictures
        [Parameter(Mandatory = $true)]
        [string]$Target
    )
    $ErrorCount = 0
    # Make sure target folder exists
    if (!(Test-Path $Target)) { 
        Write-Log "Target folder $Target does not exist, creating it"
        New-Item -Path $Target -ItemType Directory -Force
    }

    # Copy files to target
    Write-Log "About to copy contents from $Source to $Target"
    try {
        Copy-Item -Path "$Source\*" -Destination $Target -Recurse -Force -ErrorAction Stop
        Write-Log "Contents of $Source successfully copied to $Target"

    } catch {
        $ErrorCount++
        Write-Log "Failed to copy $Source to $Target."
        Write-Log "Error is: $($_.Exception.Message))"
    }
    if ($ErrorCount -eq 0) {
        return 0
    } else {
        return 1
    }
}
function Remove-Files {
    param (
        # Input path to files in the intunewin file. Should be something like: $PSScriptRoot\FolderName
        [Parameter(Mandatory = $true)]
        [string]$Source,
        # Input path to where files should be removed from. Should be something like: $Env:USERPROFILE\Pictures
        [Parameter(Mandatory = $true)]
        [string]$Target
    )
    $ErrorCount = 0
    # Get files that needs to be removed, from the source folder
    $FilesToRemove = (Get-ChildItem -Path $Source).Name
    Write-Log "About to delete contents from $Source to $Target"
    
    # Remove files from target
    foreach ($File in $FilesToRemove) {
        try {
            Remove-Item -Path "$Target\$File" -Force -Confirm:$false -ErrorAction Stop
            Write-Log "Successfully deleted $File"
        } catch {
            $ErrorCount++
            Write-Log "Failed to delete $File"
            Write-Log "Error is: $($_.Exception.Message))"
        }
    }
    if ($ErrorCount -eq 0) {
        return 0
    } else {
        return 1
    }
}


#EndRegion Functions

#Region How to use
<#
Remove-Shortcut -ShortcutDisplayName 'Printers'

Add-Shortcut -ShortcutTargetPath '\\Server01.domain.local\Printers' -ShortcutDisplayName 'Printers' -IconFile "$env:SystemRoot\System32\shell32.dll,58"

Copy the files. Function can be called multiple times.
Use [Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyPictures) syntax to get the system paths like pictures and documents
"$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\" is the start menu folder
"$env:public\Desktop" is the public desktop folder

$Destination = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyPictures)
Copy-Files -Source "$PSScriptRoot\Icons" -Target "$Destination"
Remove-Files -Source "$PSScriptRoot\Icons" -Target "$Destination"

#>
#EndRegion