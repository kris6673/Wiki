# Migrations

This is a help page for the different types of migrations that can be done.

## Table of Contents

- [Migrations](#migrations)
  - [Table of Contents](#table-of-contents)
  - [Bittitan](#bittitan)
    - [Disable throttling in EXO](#disable-throttling-in-exo)
    - [Turn off Calendar assistant](#turn-off-calendar-assistant)
  - [Links to guides](#links-to-guides)

## Bittitan

Everything useful I've found for Bittitan migrations.

### Disable throttling in EXO

[Disabled via support request in the admin center.](https://help.bittitan.com/hc/en-us/articles/12001669149851-How-to-Disable-EWS-Throttling-in-Exchange-Online)

1. Log into the admin center as a GA for the customer.
2. Write "Increase EWS Throttling Policy" in the support search field.
3. Run tests and set the days to 90 and press "Update settings".

### Turn off Calendar assistant

**Note:** This will disable the calendar assistant for all users in the tenant. This will need to be turned back on after the migration is complete.

```powershell
Get-Mailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $true
```

**Note:** Turn back on Calendar assistant for all users.

```powershell
Get-Mailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $false
```

## Links to guides

[IP lockdown of migrations](https://help.bittitan.com/hc/en-us/articles/115008252928-IP-Addresses-Connected-to-During-IP-LockDown#set-advanced-options-for-the-project-in-migrationwiz-0-0)

[Mailboxes over 100 GB/Large mailboxes](https://help.bittitan.com/hc/en-us/articles/360044916654-Microsoft-365-Mailbox-Migration-FAQ#-migrating-mailboxes-larger-than-100gb-0-22)

[M365 to M365](https://help.bittitan.com/hc/en-us/articles/6488570876955-Exchange-Online-Microsoft-365-to-Exchange-Online-Microsoft-365-Mailbox-Migration-Guide)

[On-Prem Exchange to M365](https://help.bittitan.com/hc/en-us/articles/115008266088-Exchange-2007-Hosted-and-On-Premises-to-Microsoft-365-Migration-Guide)
