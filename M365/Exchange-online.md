# Exchange Online

## Table of Contents <!-- omit in toc -->

1. [Start managed folder assistant](#start-managed-folder-assistant)
2. [Force enable SMTP AUTH for a user](#force-enable-smtp-auth-for-a-user)
3. [Make dyniamic distribution group for all UserMailboxes in a tenant](#make-dyniamic-distribution-group-for-all-usermailboxes-in-a-tenant)

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

### Make dyniamic distribution group for all UserMailboxes in a tenant

This makes sure that you don't get any shared mailboxes, room mailboxes, mail contacts, mail distribution groups or equipment mailboxes in the group.

```powershell
New-DynamicDistributionGroup -IncludedRecipients MailboxUsers -Name "Everyone - Company name" -PrimarySmtpAddress Everyone@contoso.com

Set-DynamicDistributionGroup -identity {alle@celectas.dk} -RecipientFilter {(-not(RecipientTypeDetailsValue -eq 'SharedMailbox')) -and (-not(RecipientTypeDetailsValue -eq 'RoomMailbox')) -and (-not(RecipientType -eq 'MailContact')) -and (-not(RecipientType -eq 'MailUniversalDistributionGroup'))  -and (-not(RecipientTypeDetailsValue -eq 'EquipmentMailbox'))}
```

You can then go to the Exchange Admin Center to add who is allowed to send to it, and who can approve emails sent to it. It's under the tab Dynamic Distribution Group.
