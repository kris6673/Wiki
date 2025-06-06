# Exchange Online

## Table of Contents <!-- omit in toc -->

1. [Start managed folder assistant](#start-managed-folder-assistant)
2. [Force enable SMTP AUTH for a user](#force-enable-smtp-auth-for-a-user)
3. [Make dynamic distribution group for all UserMailboxes in a tenant](#make-dynamic-distribution-group-for-all-usermailboxes-in-a-tenant)
4. [Audit log search](#audit-log-search)
   1. [Links to documentation](#links-to-documentation)

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

### Make dynamic distribution group for all UserMailboxes in a tenant

This makes sure that you don't get any shared mailboxes, room mailboxes, mail contacts, mail distribution groups or equipment mailboxes in the group.

```powershell
$EmailAddress = "Everyone@contoso.com"
New-DynamicDistributionGroup -IncludedRecipients MailboxUsers -Name "Everyone - Company name" -PrimarySmtpAddress $EmailAddress

Set-DynamicDistributionGroup -Identity $EmailAddress -RecipientFilter {(-not(RecipientTypeDetailsValue -eq 'SharedMailbox')) -and (-not(RecipientTypeDetailsValue -eq 'RoomMailbox')) -and (-not(RecipientType -eq 'MailContact')) -and (-not(RecipientType -eq 'MailUniversalDistributionGroup'))  -and (-not(RecipientTypeDetailsValue -eq 'EquipmentMailbox'))}
```

You can then go to the Exchange Admin Center to add who is allowed to send to it, and who can approve emails sent to it. It's under the tab Dynamic Distribution Group.

### Audit log search

**Note:** The following examples are for Exchange Online. You need to connect to Exchange Online PowerShell to run these commands.
In general these commands take a long time to run, so be prepared to wait for a while.  
Searching the audit log for Exchange Admin operations. This will return the last 180 days of operations for all admin operations that are related to permissions on mailboxes and calendars.

```powershell
$StartDate = (Get-Date).AddDays(-180)
$AuditLogs = Search-UnifiedAuditLog -StartDate $StartDate -EndDate (Get-Date) -RecordType "ExchangeAdmin" -Operations "Add-MailboxPermission", "Get-MailboxPermission", "Remove-MailboxPermission", "Set-Mailbox", "Add-RecipientPermission", "Remove-RecipientPermission", "Get-RecipientPermission", AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, Add-MailboxFolderPermission, Set-MailboxFolderPermission, Remove-MailboxFolderPermission -ResultSize 5000
$AuditLogs | ogv
```

**HighCompleteness version**

```powershell
$StartDate = (Get-Date).AddDays(-180)
$AuditLogs = Search-UnifiedAuditLog -StartDate $StartDate -EndDate (Get-Date) -RecordType "ExchangeAdmin" -Operations "Add-MailboxPermission", "Get-MailboxPermission", "Remove-MailboxPermission", "Set-Mailbox", "Add-RecipientPermission", "Remove-RecipientPermission", "Get-RecipientPermission", AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, Add-MailboxFolderPermission, Set-MailboxFolderPermission, Remove-MailboxFolderPermission -HighCompleteness -Formatted -Verbose
$AuditLogs = $AuditLogs | Sort-Object { $_.CreationDate -as [datetime] }
$AuditLogs | ogv
```

---

The following is a more specific search for operations related to folder permissions on mailboxes and calendars. This will return the last 180 days of operations for all admin operations that are related to permissions on calendars.

```powershell
$AuditLogs = Search-UnifiedAuditLog -StartDate ((Get-Date).AddDays(-180)) -EndDate (Get-Date) -RecordType "ExchangeAdmin" -Operations AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, Add-MailboxFolderPermission, Set-MailboxFolderPermission, Remove-MailboxFolderPermission -ResultSize 5000
$AuditLogs | ogv
```

**HighCompleteness version**

```powershell
$AuditLogs = Search-UnifiedAuditLog -StartDate ((Get-Date).AddDays(-180)) -EndDate (Get-Date) -RecordType "ExchangeAdmin" -Operations AddFolderPermissions, ModifyFolderPermissions, RemoveFolderPermissions, Add-MailboxFolderPermission, Set-MailboxFolderPermission, Remove-MailboxFolderPermission -HighCompleteness -Formatted -Verbose
$AuditLogs = $AuditLogs | Sort-Object { $_.CreationDate -as [datetime] }
$AuditLogs | ogv
```

---

General search for all operations in the Exchange Admin audit log. **Note:** This will return a lot of data and will take a long time to run.

```powershell
$AuditLogs = Search-UnifiedAuditLog -StartDate ((Get-Date).AddDays(-30)) -EndDate (Get-Date) -RecordType "ExchangeAdmin" -ResultSize 5000 | Where-Object {$_.Operations -ne "Set-ConditionalAccessPolicy" -and $_.Operations -ne "Set-TransportRule"}
$AuditLogs | ogv
```

**HighCompleteness version**

```powershell
$AuditLogs = Search-UnifiedAuditLog -StartDate ((Get-Date).AddDays(-30)) -EndDate (Get-Date) -RecordType "ExchangeAdmin" -HighCompleteness -Formatted -Verbose | Where-Object {$_.Operations -ne "Set-ConditionalAccessPolicy" -and $_.Operations -ne "Set-TransportRule"}
$AuditLogs = $AuditLogs | Sort-Object { $_.CreationDate -as [datetime] }
$AuditLogs | ogv
```

---

If you want to export to a CSV file, you can use the following command:

```powershell
$AuditLogs | Export-Csv -Path C:\path\to\file.csv -NoTypeInformation -Delimiter ";" -Encoding UTF8
```

#### Links to documentation

[Audited event types and defaults](https://learn.microsoft.com/en-us/purview/audit-mailboxes#mailbox-actions-for-user-mailboxes-and-shared-mailboxes)  
[Audited events with friendly names too](https://learn.microsoft.com/en-us/purview/audit-log-activities#exchange-mailbox-activities)
