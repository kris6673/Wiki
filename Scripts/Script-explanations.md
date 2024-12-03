# Explanation for scripts in this folder

## Table of contents <!-- omit in toc -->

1. [Install-RequiredModules.ps1](#install-requiredmodulesps1)
2. [Download-GithubRelease.ps1](#download-githubreleaseps1)
3. [Test-RegistryValue.ps1](#test-registryvalueps1)
4. [Invoke-GraphRequestNoPagination.ps1](#invoke-graphrequestnopaginationps1)
5. [Add-Shortcut.ps1](#add-shortcutps1)
6. [Get-IconFromExe.ps1](#get-iconfromexeps1)
7. [Logging.ps1](#loggingps1)
8. [Write-ToEventLog.ps1](#write-toeventlogps1)

## [Install-RequiredModules.ps1](/Scripts/Install-RequiredModules.ps1)

This PowerShell script is designed to automate the process of installing and updating a list of specified PowerShell modules. The script will check if the module is installed, and if it is, it will check if it is up to date. If it is not installed, or if it is not up to date, it will install/update the module.  
It's designed to be copied into the top of the script you want to use the modules in.

Script requires to be run in a PowerShell 5.1+ environment. Make sure to run it with administrative privileges to avoid permission issues.

## [Download-GithubRelease.ps1](/Scripts/Download-GithubRelease.ps1)

Downloads the latest release of the specified software from GitHub.  
Rustdesk is used as an example in the script.

## [Test-RegistryValue.ps1](/Scripts/Test-RegistryValue.ps1)

Tests if a registry value exists and has a specific value.
Examples are provided in the synopsis of the script.

## [Invoke-GraphRequestNoPagination.ps1](/Scripts/Invoke-GraphRequestNoPagination.ps1)

This script is designed to make a request to the Microsoft Graph API without pagination.  
Returns the results of the request as a PSObject and not a Hashtable, like it would if you used the `Invoke-GraphRequest` function from the `Microsoft.Graph` module.
Otherwise it's only gonna return the first 100 items.

## [Add-Shortcut.ps1](/Scripts/Add-Shortcut.ps1)

Creates a shortcut on the desktop to the specified file.  
This is mostly useful for scripts that are run as a scheduled task or in Intune.  
If the process is running in system context, the shortcut will be created in the public desktop folder.  
If the process is running in user context, the shortcut will be created in the user's desktop folder.
Requires the 2 helper functions Test-RunningAsSystem and Get-DesktopDir to work.

## [Get-IconFromExe.ps1](/Scripts/Get-IconFromExe.ps1)

This script is designed to extract the icon from an executable file and save it as a .png file.

## [Logging.ps1](/Scripts/Logging.ps1)

This script is designed to provide a simple logging function that can be used in other scripts.
The script will create a log file in a sub directory called "Logs" as the script that is calling the logging function.
Has built in support for cleaning up old log files, and handles log rotation/size.

## [Write-ToEventLog.ps1](/Scripts/Write-ToEventLog.ps1)

Writes a message to the specified Windows Event Log.
Creates a new event log source if it doesn't exist.

- **Message**: The message to be written.
- **LogSource**: The source of the event log entry.
- **LogName**: The name of the event log (default: 'Application').
- **Level**: The level of the event log entry (default: 'Information').
- **EventID**: The event ID for the log entry (default: 9376).
- **Category**: The category for the log entry (default: 1).
- **WriteToHost**: Optional flag to write the message to the host.
