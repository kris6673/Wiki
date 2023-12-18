# Exchange Online

## Table of Contents <!-- omit in toc -->

1. [Start managed folder assistant](#start-managed-folder-assistant)
2. [Force enable SMTP AUTH for a user](#force-enable-smtp-auth-for-a-user)

### Start managed folder assistant

Start the managed folder assistant to force the retention policy to run. This runs every 7 days by default.  
For all users in the tenant:

```powershell

Get-Mailbox -ResultSize unlimited | ForEach-Object { Start-ManagedFolderAssistant -Identity $_.UserPrincipalName }

```

For one user:

```powershell
Start-ManagedFolderAssistant -Identity <User UPN>
```

### Force enable SMTP AUTH for a user

If SMTP auth is disabled on tenant level, but not blocked by a CA policy, you can force enable it for a user:

```powershell
Set-CASMailbox <User UPN> -SmtpClientAuthenticationDisabled $false
```
