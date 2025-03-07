﻿function Get-IconFromExe {
    <#
.SYNOPSIS
Extracts an icon from an executable file and saves it in a specified format.

.DESCRIPTION
The Get-IconFromExe function extracts an icon from a specified executable file and saves it to a specified destination folder in a chosen image format. 
The function supports various image formats including ico, bmp, png, jpg, and gif.

.PARAMETER Path
Specifies the path to the executable file from which the icon will be extracted. This parameter is mandatory.

.PARAMETER Destination
Specifies the folder where the extracted icon will be saved. The default is the current directory.

.PARAMETER Name
Specifies an alternate base name for the new image file. If not provided, the source file name will be used.

.PARAMETER Format
Specifies the format of the extracted icon image. The default format is png. Supported formats are ico, bmp, png, jpg, and gif.

.EXAMPLE
PS C:\> Get-IconFromExe -Path "C:\Path\To\YourApp.exe"

This command extracts the icon from "YourApp.exe" and saves it as a PNG file in the current directory.

.EXAMPLE
PS C:\> Get-IconFromExe -Path "C:\Path\To\YourApp.exe" -Destination "C:\Icons" -Format "png"

This command extracts the icon from "YourApp.exe" and saves it as a PNG file in the "C:\Icons" directory.

.EXAMPLE
PS C:\> Get-IconFromExe -Path "C:\Path\To\YourApp.exe" -Destination "C:\Icons" -Name "AppIcon" -Format "ico"

This command extracts the icon from "YourApp.exe" and saves it as an ICO file named "AppIcon.ico" in the "C:\Icons" directory.

.NOTES
Requires PowerShell version 5.1 or higher.
#>
    #requires -version 5.1
    # inspired by https://community.spiceworks.com/topic/592770-extract-icon-from-exe-powershell
    # Found here: https://jdhitsolutions.com/blog/powershell/7931/extracting-icons-with-powershell/
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = 'Specify the path to the file.')]
        [ValidateScript({ Test-Path $_ })]
        [string]$Path,
    
        [Parameter(HelpMessage = 'Specify the folder to save the file.')]
        [ValidateScript({ Test-Path $_ })]
        [string]$Destination = '.',
    
        [parameter(HelpMessage = 'Specify an alternate base name for the new image file. Otherwise, the source name will be used.')]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
    
        [Parameter(HelpMessage = 'What format do you want to use? The default is png.')]
        [ValidateSet('ico', 'bmp', 'png', 'jpg', 'gif')]
        [string]$Format = 'png'
    )
    
    Write-Verbose "Starting $($MyInvocation.MyCommand)"
    
    Try {
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    } Catch {
        Write-Warning 'Failed to import System.Drawing'
        Throw $_
    }
    
    Switch ($format) {
        'ico' { $ImageFormat = 'icon' }
        'bmp' { $ImageFormat = 'Bmp' }
        'png' { $ImageFormat = 'Png' }
        'jpg' { $ImageFormat = 'Jpeg' }
        'gif' { $ImageFormat = 'Gif' }
    }
    
    $file = Get-Item $path
    Write-Verbose "Processing $($file.fullname)"
    #convert destination to file system path
    $Destination = Convert-Path -Path $Destination
    
    if ($Name) {
        $base = $Name
    } else {
        $base = $file.BaseName
    }
    
    #construct the image file name
    $out = Join-Path -Path $Destination -ChildPath "$base.$format"
    
    Write-Verbose "Extracting $ImageFormat image to $out"
    $ico = [System.Drawing.Icon]::ExtractAssociatedIcon($file.FullName)
    
    if ($ico) {
        #WhatIf (target, action)
        if ($PSCmdlet.ShouldProcess($out, 'Extract icon')) {
            $ico.ToBitmap().Save($Out, $Imageformat)
            Get-Item -Path $out
        }
    } else {
        #this should probably never get called
        Write-Warning "No associated icon image found in $($file.fullname)"
    }
    
    Write-Verbose "Ending $($MyInvocation.MyCommand)"
}