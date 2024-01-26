# Random nice links to stuff

## Table of Contents <!-- omit in toc -->

1. [M365](#m365)
   1. [Intune](#intune)
2. [Markdown](#markdown)
3. [Timezones](#timezones)
4. [Drawing and diagramming](#drawing-and-diagramming)
5. [Git](#git)
6. [Powershell](#powershell)
   1. [Powershell modules](#powershell-modules)
7. [Development tools](#development-tools)

## M365

[Microsoft 365 Roadmap](https://www.microsoft.com/en-us/microsoft-365/roadmap?filters=&searchterms=)  
[Admin roles and what they do](https://learn.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#domain-name-administrator)  
[Microsoft 365 IP ranges via API](https://endpoints.office.com/endpoints/worldwide?clientrequestid=b10c5ed1-bad1-445f-b386-b919946339a7)  
[Hybrid join vs AAD join](https://wiki.winadmins.io/en/autopilot/hybrid-join-vs-aad-join)  
[Component service ID's](https://learn.microsoft.com/en-us/entra/identity/users/licensing-service-plan-reference)

### Intune

[Intunewin file / Content prep tool](https://svrooij.io/2023/10/19/open-source-intune-content-prep/)  
<https://api.vdwegen.app/api/reverseAADapp?appid={ApplicationID-here}> - Get info on apps in M365 via API
[Intune install commands for Win32 apps](https://silentinstallhq.com/)

## Markdown

[Emoji cheat sheet](https://github.com/ikatyang/emoji-cheat-sheet#table-of-contents)

## Timezones

[List of timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

## Drawing and diagramming

[Excalidraw](https://excalidraw.com/) - Great for quick drawings

## Git

[Oh shit git / Un-fucking your git repo when mistakes were made](https://ohshitgit.com/)

## Powershell

[PowerShell Gallery](https://www.powershellgallery.com/)  
[Online HTML editor](https://html5-editor.net/)

### Powershell modules

| Module name                                                                                                                 | Description                             | Commands                                                        |
| --------------------------------------------------------------------------------------------------------------------------- | --------------------------------------- | --------------------------------------------------------------- |
| [ExchangeOnlineManagement](https://www.powershellgallery.com/packages/ExchangeOnlineManagement)                             | Connect to Exchange Online              | Connect-ExchangeOnline                                          |
| [MSOnline](https://www.powershellgallery.com/packages/MSOnline)                                                             | Connect to Azure AD                     | Connect-MsolService                                             |
| [Microsoft.Graph](https://www.powershellgallery.com/packages/Microsoft.Graph)                                               | Connect to Microsoft Graph              | Connect-MgGraph -Scopes                                         |
| [Microsoft.Graph.Beta](https://www.powershellgallery.com/packages/Microsoft.Graph.Beta)                                     | Connect to Microsoft Graph Beta         | Same as above, but commands use MgGraphBeta                     |
| [AzureAD](https://www.powershellgallery.com/packages/AzureAD)                                                               | Connect to Azure AD                     | Connect-AzureAD                                                 |
| [AIPService](https://www.powershellgallery.com/packages/AIPService)                                                         | Connect to Azure Information Protection | Connect-AipService                                              |
| [ImportExcel](https://www.powershellgallery.com/packages/ImportExcel)                                                       | Import and export Excel files           |                                                                 |
| [MicrosoftTeams](https://www.powershellgallery.com/packages/MicrosoftTeams)                                                 | Connect to Microsoft Teams              | Connect-MicrosoftTeams                                          |
| [PnP.PowerShell](https://www.powershellgallery.com/packages/PnP.PowerShell)                                                 | Connect to SharePoint Online            | Connect-PnPOnline                                               |
| [Microsoft.Online.SharePoint.PowerShell](https://www.powershellgallery.com/packages/Microsoft.Online.SharePoint.PowerShell) | Connect to SharePoint Online            | Connect-SPOService                                              |
| [PSDKit](https://www.powershellgallery.com/packages/PSDKit)                                                                 | Convert JSON to PsCustomObject          | ConvertFrom-Json -InputObject $JSONInputString \| ConvertTo-Psd |

## Development tools

[Webhook.site](https://webhook.site/) - Great for testing webhooks
