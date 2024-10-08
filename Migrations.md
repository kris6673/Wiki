# Migrations

This is a help page for the different types of migrations that can be done.

## Table of Contents <!-- omit in toc -->

1. [Bittitan](#bittitan)
   1. [General info](#general-info)
   2. [Disable throttling in EXO](#disable-throttling-in-exo)
   3. [Timeout issues causing migration to fail](#timeout-issues-causing-migration-to-fail)
   4. [Turn off Calendar assistant](#turn-off-calendar-assistant)
2. [Links to guides](#links-to-guides)

## Bittitan

Everything useful I've found for Bittitan migrations.

### General info

Mailbox data is migrated from newest to oldest items. So the user gets their newest emails first.

### Disable throttling in EXO

[Disabled via support request in the admin center.](https://help.bittitan.com/hc/en-us/articles/12001669149851-How-to-Disable-EWS-Throttling-in-Exchange-Online)

1. Log into the admin center as a GA for the customer.
2. Write "Increase EWS Throttling Policy" in the support search field.
3. Run tests and set the days to 90 and press "Update settings".

### Timeout issues causing migration to fail

Add the following to the advanced options of the project.

```text
ExtendedEwsTimeout=1
InitializationTimeout=8
```

Read more about the support options [here](#links-to-guides)

### Turn off Calendar assistant

**Note:** This will disable the calendar assistant for all users in the tenant. This will need to be turned back on after the migration is complete. This is done to ensure that the calendar assistant doesn't interfere with the migration and break meetings and recurring meetings.

```powershell
Get-EXOMailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $true
```

**Note:** Turn back on Calendar assistant for all users.

```powershell
Get-EXOMailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $false
```

## Links to guides

[IP lockdown of migrations](https://help.bittitan.com/hc/en-us/articles/115008252928-IP-Addresses-Connected-to-During-IP-LockDown#set-advanced-options-for-the-project-in-migrationwiz-0-0)  
[Mailboxes over 100 GB/Large mailboxes](https://help.bittitan.com/hc/en-us/articles/360044916654-Microsoft-365-Mailbox-Migration-FAQ#-migrating-mailboxes-larger-than-100gb-0-22)  
[M365 to M365](https://help.bittitan.com/hc/en-us/articles/6488570876955-Exchange-Online-Microsoft-365-to-Exchange-Online-Microsoft-365-Mailbox-Migration-Guide)  
[On-Prem and Hosted Exchange to M365](https://help.bittitan.com/hc/en-us/articles/115008266088-Exchange-2007-Hosted-and-On-Premises-to-Microsoft-365-Migration-Guide)  
[Scoped inpersonation](https://help.bittitan.com/hc/en-us/articles/115015661147-MigrationWiz-Impersonation-and-Delegation-for-Microsoft-365-Exchange-Migrations#scoped-impersonation-with-ews-0-3)  
[OneDrive to OneDrive](https://help.bittitan.com/hc/en-us/articles/360011172673-OneDrive-to-OneDrive-for-Business-without-Versions-and-Metadata-migration-guide)  
[All Bititan support options](https://help.bittitan.com/hc/en-us/articles/360043369293-MigrationWiz-Support-Options)  
[MigrationWiz - Advanced Options & General Options](https://help.bittitan.com/hc/en-us/articles/360043891714-MigrationWiz-Advanced-Options-General-Options#h_01HC38V3KNNRY4TEJG0AW70QVC)  
[Set MailboxGUID to null/User is stuck as MailUser and cant get mailbox](https://www.alitajran.com/hard-delete-mailbox-microsoft-365)
