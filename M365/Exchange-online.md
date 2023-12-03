# Exchange Online

## Table of Contents <!-- omit in toc -->

1. [Start managed folder assistant](#start-managed-folder-assistant)

### Start managed folder assistant

Start the managed folder assistant to force the retention policy to run. This runs every 7 days by default.  
For all users in the tenant:

```powershell

Get-Mailbox -ResultSize unlimited | ForEach-Object { Start-ManagedFolderAssistant -Identity $_.UserPrincipalName }

```

For one user:

```powershell
Start-ManagedFolderAssistant -Identity <user UPN>
```
