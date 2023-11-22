# Ad sync for M365

**Note:** Both Cloud sync and Connect sync requires a Server 2016 as minimum

## Table of Contents <!-- omit in toc -->

1. [Cloud sync aka. the new one](#cloud-sync-aka-the-new-one)
   1. [Reset password on next login - Cloud Sync](#reset-password-on-next-login---cloud-sync)
2. [Connect sync aka. the old one](#connect-sync-aka-the-old-one)
   1. [In-place upgrade server the sync is on](#in-place-upgrade-server-the-sync-is-on)
   2. [Migrate to a new server](#migrate-to-a-new-server)
   3. [Reset password on next login - Connect Sync](#reset-password-on-next-login---connect-sync)
3. [Cloud Kerberos trust](#cloud-kerberos-trust)
4. [Breaking AD sync](#breaking-ad-sync)

## Cloud sync aka. the new one

This should run every 2 minutes, the [FAQ says it does](https://learn.microsoft.com/en-us/entra/identity/hybrid/cloud-sync/reference-cloud-sync-faq#how-often-does-cloud-sync-run-), MS says it does, but it does not. Only the password sync runs every 2 minutes, the identity sync runs every 30 minutes or so. Sometimes it runs every 2 minutes too, but other times it takes 5-30 minutes.

Installed as an agent on member servers of the domain, does not have to be on DC's.

I havn't figured out how to force it to run a sync yet. Something about finding the service principal called the FQDN of the local AD domain, and running a start sync command at it. :

### Reset password on next login - Cloud Sync

---

**Symptom:** You would like to know if the ForcePasswordChangeOnLogOn is supported in Cloud Sync.

**Answer:** Yes, but as of today,  the ForcePasswordChangeOnLogOn feature can only be set with ADSync cmdlet Set-ADSyncAADCompanyFeature -ForcePasswordChangeOnLogOn $true

**Resolution:** This can be done on another server other than the one that currently has the Cloud Sync agent.

1. Install AADConnect.

2. When the wizard starts, select "Customize". This will take the wizard through the custom installation experience: [Customize an installation of Azure Active Directory Connect - Microsoft Entra | Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-install-custom)

3. Make no selections in "**Install required components**". Click "Install"

4. In the page "**User sign-in**" select "**Do not configure**" Click "Next"

5. Connect to Azure AD with a GA user account

6. On the connect your directories page the user will need to connect to an active directory with which the server has line of sight to. Click "Next".

7. You can select to create a new account or pre-create an account in ad to delete later and use the option "**Use existing account**".

8. Go through the next section without making any changes. When reaching the page "Domain and OU filtering", select the radio button "Sync selected domains and OUs". Then remove the selection from the root of the domain. :warning: **_Make sure no OU's are selected_**.

9. Go through the rest of the wizard without making any changes. At the end of the wizard, in the "**Ready to configure**" page, select the option "Enable staging mode:.." to guarantee there will not be any exports from this server.

10. Once complete, you can open Windows PowerShell and import the ADSync module:

    1. `Import-Module ADSync`

11. And run the command to enable the required feature.

    1. `Set-ADSyncAADCompanyFeature -ForcePasswordChangeOnLogOn $true`

12. Once the command completes successfully (It will return the features current state), You can un-install AADConnect

## Connect sync aka. the old one

### In-place upgrade server the sync is on

When upgrading the server from 2012 R2 to a newer version, the installation does not survive and needs to be uninstalled and reconfigured afterward.

1. Exporting the settings
2. Noting the user sign-in options, since these don't get exported
3. [Breaking the synchronization](#breaking-ad-sync)
4. Waiting to make sure the sync is broken and users are converted to cloud only
5. Doing the in-place upgrade of the server
6. Reinstalling AD Connect specifying the export file during the reinstall.
7. Setting the user sign-in options to what they were before the upgrade

### Migrate to a new server

[Migration guide](https://www.alitajran.com/migrate-azure-ad-connect/)

### Reset password on next login - Connect Sync

[MS Documentation/Guide](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-password-hash-synchronization#synchronizing-temporary-passwords-and-force-password-change-on-next-logon)

:warning: **CAUTION:** You should only use this feature when SSPR and Password Writeback are enabled on the tenant. This is so that if a user changes their password via SSPR, it will be synchronized to Active Directory. :warning:

```powershell
# Run this on the AD Connect sync server

# Get the current state of the feature
Get-ADSyncAADCompanyFeature

# Enable the feature
Set-ADSyncAADCompanyFeature -ForcePasswordChangeOnLogOn $true
```

## Cloud Kerberos trust

**Note:** Windows Hello for Business, and some kind of AD sync is required for this to work.

[Microsoft guide](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/hello-hybrid-cloud-kerberos-trust-provision?tabs=intune)

[Lazyadmin.nl guide](https://lazyadmin.nl/it/windows-hello-for-business-cloud-trust/#implementing-hybrid-cloud-trust)

## Breaking AD sync

Breaking the sync converts all synced users into cloud only users. It's done with the following powershell commands:

```powershell
Connect-MsolService
Set-MsolDirSyncEnabled -EnableDirSync $false
```

:x: No known Graph replacement yet

[Source/Documentation](https://learn.microsoft.com/en-us/microsoft-365/enterprise/turn-off-directory-synchronization?view=o365-worldwide "Microsoft Docs")
