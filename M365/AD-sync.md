# Ad sync for M365

**Note:** Both Cloud sync and Connect sync requires a Server 2016 as minimum

## Table of Contents <!-- omit in toc -->

1. [Both old and new](#both-old-and-new)
   1. [Comply your AD password expiration policy with Entra/M365](#comply-your-ad-password-expiration-policy-with-entram365)
2. [Cloud sync aka. the new one](#cloud-sync-aka-the-new-one)
   1. [Single Sign-On with Cloud Sync](#single-sign-on-with-cloud-sync)
   2. [Reset password on next login - Cloud Sync](#reset-password-on-next-login---cloud-sync)
   3. [Set MsExchangeMailboxGuid to NULL - Cloud Sync](#set-msexchangemailboxguid-to-null---cloud-sync)
3. [Connect sync aka. the old one](#connect-sync-aka-the-old-one)
   1. [In-place upgrade server the sync is on](#in-place-upgrade-server-the-sync-is-on)
   2. [Troubleshooting](#troubleshooting)
   3. [Permission errors when trying to sync users to M365 via AD sync](#permission-errors-when-trying-to-sync-users-to-m365-via-ad-sync)
      1. [Azure AD Connect must modify the DCOM security registry values to grant access to the required operator roles](#azure-ad-connect-must-modify-the-dcom-security-registry-values-to-grant-access-to-the-required-operator-roles)
   4. [Migrate to a new server](#migrate-to-a-new-server)
   5. [Reset password on next login - Connect Sync](#reset-password-on-next-login---connect-sync)
   6. [Set MsExchangeMailboxGuid to NULL - Connect Sync](#set-msexchangemailboxguid-to-null---connect-sync)
4. [Cloud Kerberos trust](#cloud-kerberos-trust)
   1. [Troubleshooting](#troubleshooting-1)
5. [Breaking AD sync](#breaking-ad-sync)

## Both old and new

### Comply your AD password expiration policy with Entra/M365

[Guide](https://www.bilalelhaddouchi.nl/index.php/2020/09/24/enforcecloudpasswordpolicyforpasswordsyncedusers/)  
[MS guide](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization#cloudpasswordpolicyforpasswordsyncedusersenabled)

:warning: **CAUTION:** You should only use this feature when SSPR and Password Writeback are enabled on the tenant. :warning:  
This feature ensures that on-premises Active Directory password expiration policies are properly enforced in Azure AD for password hash synchronized users. Without this enabled, users with expired passwords in AD can still access cloud resources via Azure AD.

To enable the feature:

```powershell
# Check if feature is enabled and sign in to Graph with a global admin account
Connect-Graph -Scopes 'User.ReadWrite.All, Directory.ReadWrite.All'
(Get-MgDirectoryOnPremiseSynchronization).Features.CloudPasswordPolicyForPasswordSyncedUsersEnabled

# Using Microsoft Graph PowerShell
$OnPremSync = Get-MgDirectoryOnPremiseSynchronization
$OnPremSync.Features.CloudPasswordPolicyForPasswordSyncedUsersEnabled = $true
Update-MgDirectoryOnPremiseSynchronization -OnPremisesDirectorySynchronizationId $OnPremSync.Id -Features $OnPremSync.Features

# Check users' password expiration settings
(Get-MgUser -Property UserPrincipalName, PasswordPolicies) | select UserPrincipalName, PasswordPolicy

# Set password policy to "None" for a specific user
Update-MgUser -UserID <User Object ID> -PasswordPolicies "None"

# Set password policy to "DisablePasswordExpiration" for a specific user
Update-MgUser -UserID <User Object ID> -PasswordPolicies "DisablePasswordExpiration"
```

**Note:** For service and break-glass accounts that require non-expiring passwords in Azure AD, explicitly set the PasswordPolicies attribute to "DisablePasswordExpiration".

The next time the user changes password on the On-Premise AD, the password expiration policy will be enforced in Azure AD. This is not great, since the user has to change the password to get the new policy enforced. To force the policy to be enforced, you can either set the password policy to "None" for the user, or run an initial sync on the AD sync server or a full sync in the cloud sync configuration.

The password expiration policy in the tenant, now needs to be aligned to the On-Premise AD password policy. This setting is found in the M365 admin portal under **Settings** -> **Org settings** -> **Security & privacy** -> **Password expiration policy**.  
**If the password policy is set to "Never expire" in the tenant, the above changes will have done nothing.**

## Cloud sync aka. the new one

This should run every 2 minutes, the [FAQ says it does](https://learn.microsoft.com/en-us/entra/identity/hybrid/cloud-sync/reference-cloud-sync-faq#how-often-does-cloud-sync-run-), MS says it does, but it does not. Only the password sync runs every 2 minutes, the identity sync runs every 30 minutes or so. Sometimes it runs every 2 minutes too, but other times it takes 5-30 minutes.

Installed as an agent on member servers of the domain, does not have to be on DC's.

I havn't figured out how to force it to run a sync yet. Something about finding the service principal called the FQDN of the local AD domain, and running a start sync command at it. :

### Single Sign-On with Cloud Sync

Annoying process compared to the old one, but it works.
[SSO enablement](https://www.cloudpilot.no/blog/Using-Single-Sign-On-with-Azure-AD-Connect-Cloud-Sync/)

### Reset password on next login - Cloud Sync

---

[Guide](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-password-hash-synchronization#synchronizing-temporary-passwords-and-force-password-change-on-next-logon)

```powershell
Connect-Graph -Scopes 'User.ReadWrite.All, Directory.ReadWrite.All, Directory.AccessAsUser.All'
$OnPremSync = Get-MgDirectoryOnPremiseSynchronization
$OnPremSync.Features.UserForcePasswordChangeOnLogonEnabled = $true

Update-MgDirectoryOnPremiseSynchronization -OnPremisesDirectorySynchronizationId $OnPremSync.Id -Features $OnPremSync.Features
```

### Set MsExchangeMailboxGuid to NULL - Cloud Sync

[Guide](../Good-links.md#ad-sync)

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

### Troubleshooting

### Permission errors when trying to sync users to M365 via AD sync

Inheritance is probably not enabled on the OU where the users are located.  
Enable inheritance on the OU where the users are located, via this:
[Enable inheritance on all users in a specific OU](../Windows/Server/AD.md#enable-inheritance-on-all-users-in-a-specific-ou) and run a sync again.

#### Azure AD Connect must modify the DCOM security registry values to grant access to the required operator roles

**Error message is:** :x:Repair the following registry values:x:

- MachineAccessRestriction
- MachineLaunchRestriction

There can be a number of things wrong here.
Open Component Services and navigate to the following path:

```text
    Component Services > Computers > My Computer > Permissions > DCOM Config
```

1. See if there is multiple unknown SIDs in the permissions, and if there is, try removing them and try again.
2. ADsync groups are most likely missing from the DCOM permissions in Component Services.  
   You can try adding them to the DCOM permissions manually.  
   You need to add the following groups to all 4 of the DCOM permissions:

   - ADSyncAdmins
   - ADSyncOperators
   - ADSyncBrowse
   - ADSyncPasswordSet

   If when you add the groups and press OK, and the groups are removed again, probalby have corrupt permissions on the reg keys.

3. If it still does not work, goto the registry and find the following keys on the server:  
   Path: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole

   - MachineLaunchRestrictionOld
   - MachineAccessRestrictionOld

Make a backup/export of the keys. Try renaming them to without the "Old" at the end, and try changing permissions again. If the name changes back to "Old" you need to export the keys, rename them in the exported file to without the "Old" at the end, and import them again. This should fix the issue.

### Migrate to a new server

[Migration guide](https://www.alitajran.com/migrate-azure-ad-connect/)  
[Export current config if GUI is broken/Via powershell](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-import-export-config).
Command to extract the MSI is:

```powershell
msiexec /a "C:\path\to\your\installer.msi" /qb TARGETDIR="C:\output\extracted_files"
```

### Reset password on next login - Connect Sync

[MS Documentation/Guide](https://learn.microsoft.com/en-us/azure/active-directory/hybrid/connect/how-to-connect-password-hash-synchronization#synchronizing-temporary-passwords-and-force-password-change-on-next-logon)

:warning: **CAUTION:** You should only use this feature when SSPR and Password Writeback are enabled on the tenant. :warning:

```powershell
# Run this on the AD Connect sync server

# Get the current state of the feature
Get-ADSyncAADCompanyFeature

# Enable the feature
Set-ADSyncAADCompanyFeature -ForcePasswordChangeOnLogOn $true
```

### Set MsExchangeMailboxGuid to NULL - Connect Sync

[Guide](../Good-links.md#ad-sync)

## Cloud Kerberos trust

**Note:** Windows Hello for Business, and some kind of AD sync is required for this to work. If the users dont use Windows Hello for Business, the Cloud Kerberos trust is not needed since Kerberos auth works without it, but nice to have anyway for future use.

[Microsoft guide](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust?tabs=intune)

[Lazyadmin.nl guide](https://lazyadmin.nl/it/windows-hello-for-business-cloud-trust/#implementing-hybrid-cloud-trust) that has the powershell commands in a more readable format.

**Run this from a at least 2016 DC:**
The important ones are:

```powershell
# Install the required module
Install-Module -Name AzureADHybridAuthenticationManagement -AllowClobber

$Domain = $env:USERDNSDOMAIN
# UserPrincipalName of an Azure AD Global Administrator
$userPrincipalName = "Admin@devtenant.onmicrosoft.com"
# Create the new Azure AD Kerberos Server object in Active Directory
Set-AzureADKerberosServer -Domain $Domain -UserPrincipalName $userPrincipalName

# Verify the Azure AD Kerberos Server object
Get-AzureADKerberosServer -Domain $Domain -UserPrincipalName $userPrincipalName
```

[Peter van der Woude guide](https://www.petervanderwoude.nl/post/configuring-windows-hello-for-business-cloud-kerberos-trust/) that has the last config needed for the cloud trust to work, specifically this:

1. Open the Microsoft Intune admin center portal and navigate to Devices > Windows > Configuration profiles
2. On the Windows | Configuration profiles blade, click Create profile
3. On the Create a profile blade, provide the following information and click Create
   1. Platform: Select Windows 10 and later to create a profile for Windows 10 and Windows 11 devices
   2. Profile: Select Settings Catalog to select the required setting from the catalog
4. On the Basics page, provide the following information and click Next
   1. Name: Provide a name for the profile to distinguish it from other similar profiles
   2. Description: (Optional) Provide a description for the profile to further differentiate profiles
   3. Platform: (Greyed out) Windows 10 and later
5. On the Configuration settings page, as shown below in Figure 2, perform the following actions
   1. Click Add settings and perform the following in Settings picker
   2. Select Windows Hello for Business as category
   3. Select Use Cloud Trust For On Prem Auth as settings
   4. Switch the slider to Enabled with Use Cloud Trust For On Prem Auth and click Next

### Troubleshooting

Test with the following command, to see if it can get a ticket:

```powershell
klist
```

if that does not work, try the following command and look in the event logs for errors:

```powershell
klist get krbtgt
```

You have probably forgotten to deploy this setting in some way: **Use Cloud Trust For On Prem Auth**

## Breaking AD sync

Breaking the sync converts all synced users into cloud only users. It's done with the following powershell commands:

Found in this [guide](https://www.alitajran.com/disable-active-directory-synchronization/)

```powershell
Connect-MgGraph -Scopes "Organization.ReadWrite.All"
Get-MgOrganization | Select-Object DisplayName, OnPremisesSyncEnabled
$OrgID = (Get-MgOrganization).Id

$params = @{
    onPremisesSyncEnabled = $false
}

Update-MgBetaOrganization -OrganizationId $OrgID -BodyParameter $params
```

[Source/Documentation](https://learn.microsoft.com/en-us/microsoft-365/enterprise/turn-off-directory-synchronization?view=o365-worldwide "Microsoft Docs")
