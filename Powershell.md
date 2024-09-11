# Powershell Notes

## Table of Contents <!-- omit in toc -->

1. [Error handling in Powershell](#error-handling-in-powershell)
2. [Run as system](#run-as-system)
3. [Powershell modules](#powershell-modules)

### Error handling in Powershell

This gets the type of the exception from the first error in the error list. The output is the full name of the exception type, that can be used to catch the exception in the square brackets of the catch block.

```powershell
$Error[0].Exception.GetType().FullName
```

The most useful properties are:

- $\_.Exception.Message: The error message text.
- $\_.Exception.ItemName: The input that caused the error.
- $\_.Exception.PSMessageDetails: Additional info about the error.
- $\_.CategoryInfo: The category of the error, such as InvalidArgument.
- $\_.FullyQualifiedErrorId: The full ID of the error, such as NativeCommandError.
- $\_.Exception.GetType().FullName – Gets you the full name of the exception

### Run as system

Sometimes you need to run a script as system to test. This is usually to test a script that will be run as a scheduled task, or a script for Intune. To do this, you can use the following command:

```powershell
Invoke-WebRequest -Uri 'https://live.sysinternals.com/PsExec64.exe'-OutFile $env:TEMP\PsExec64.exe
Start-Process $env:TEMP\PsExec64.exe '-i -s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe'
Start-Sleep -Seconds 5
# After you are done with the script, remove the PsExec64.exe file
Remove-Item $env:TEMP\PsExec64.exe
```

Bit hacky, but meh.

### Powershell modules

| Module name                                                                                                                 | Description                                                        | Commands                                                                                            |
| --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement)                             | Connect to Exchange Online                                         | Connect-ExchangeOnline                                                                              |
| [MSOnline](https://www.powershellgallery.com/packages/MSOnline)                                                             | Connect to Azure AD                                                | Connect-MsolService                                                                                 |
| [Microsoft.Graph](https://www.powershellgallery.com/packages/Microsoft.Graph)                                               | Connect to Microsoft Graph                                         | Connect-MgGraph -Scopes                                                                             |
| [Microsoft.Graph.Beta](https://www.powershellgallery.com/packages/Microsoft.Graph.Beta)                                     | Connect to Microsoft Graph Beta                                    | Same as above, but commands use MgGraphBeta                                                         |
| [AzureAD](https://www.powershellgallery.com/packages/AzureAD)                                                               | Connect to Azure AD                                                | Connect-AzureAD                                                                                     |
| [AIPService](https://www.powershellgallery.com/packages/AIPService)                                                         | Connect to Azure Information Protection                            | Connect-AipService                                                                                  |
| [ImportExcel](https://www.powershellgallery.com/packages/ImportExcel)                                                       | Import and export Excel files                                      |                                                                                                     |
| [MicrosoftTeams](https://www.powershellgallery.com/packages/MicrosoftTeams)                                                 | Connect to Microsoft Teams                                         | Connect-MicrosoftTeams                                                                              |
| [PnP.PowerShell](https://www.powershellgallery.com/packages/PnP.PowerShell)                                                 | Connect to SharePoint Online                                       | Connect-PnPOnline                                                                                   |
| [Microsoft.Online.SharePoint.PowerShell](https://www.powershellgallery.com/packages/Microsoft.Online.SharePoint.PowerShell) | Connect to SharePoint Online                                       | Connect-SPOService                                                                                  |
| [PSDKit](https://www.powershellgallery.com/packages/PSDKit)                                                                 | Convert JSON to PsCustomObject                                     | ConvertFrom-Json -InputObject $JSONInputString \| ConvertTo-Psd                                     |
| [MSGraphStuff](https://www.powershellgallery.com/packages/MSGraphStuff/1.0.9)                                               | Module to find needed Graph modules to install + permission scopes | Get-CodeGraphModuleDependency -scriptPath C:\path\to\script.ps1                                     |
| [Microsoft.WinGet.Client](https://www.powershellgallery.com/packages/Microsoft.WinGet.Client)                               | Repair-WinGetPackageManager                                        | Install WinGet as use as a powershell module. Works only in user context in PS5.1, both in PS7/core |
| [Microsoft.PowerShell.SecretManagement](https://www.powershellgallery.com/packages/Microsoft.PowerShell.SecretManagement)   | Manage secrets in a secure way                                     | Get-Secret, Set-Secret, Remove-Secret                                                               |
| [PassPushPosh](https://www.powershellgallery.com/packages/PassPushPosh)                                                     | Manage secrets in a secure way                                     | Initialize-PassPushPosh, New-Push, "blabla" \| New-Push                                             |
