# Active Directory Domain Services

## Table of Contents <!-- omit in toc -->

1. [Group Managed Service Accounts (gMSA)](#group-managed-service-accounts-gmsa)
2. [Enable inheritance on all users in a specific OU](#enable-inheritance-on-all-users-in-a-specific-ou)
3. [Add custom attribute in AD](#add-custom-attribute-in-ad)

## Group Managed Service Accounts (gMSA)

There is a specific order to make these work correctly.

1. Install the Kerberos Root Key on the server you need to use the gMSA on. Before you use the service account, 10 hours needs to have passed, to make sure the key has been replicated to all DCs.

   ```powershell
   Add-KdsRootKey -EffectiveImmediately
   ```

2. Create the group that will be allowed to use the gMSA. Should be named something like "GMSA_ServiceName". This is the group that the computer account objects that can use the gMSA will be added to.
3. Create the gMSA account. The account will be created in the default OU for Managed Service Accounts.

   ```powershell
   $gMSAName = 'gMSA_PS_add-kioskcomputer'
   $gMSAFQDN = ($gMSAName + '.' + (Get-ADDomain).DNSRoot).ToString()
   $gMSAGroupName = (Get-ADGroup -Filter * | Out-GridView -OutputMode Single -Title 'Select the group that will be allowed to use the gMSA').Name

   New-ADServiceAccount -Name $gMSAName -DNSHostName $gMSAFQDN -PrincipalsAllowedToRetrieveManagedPassword $gMSAGroupName ManagedPasswordIntervalInDays 30
   ```

4. Install the gMSA on the server you need to use the gMSA on. You cannot install the gMSA without importing the ActiveDirectory module. You will need to install and import the RSAT-AD-Powershell module using these commands:

   ```powershell
   Install-WindowsFeature RSAT-AD-PowerShell
   Import-Module ActiveDirectory

   Install-ADServiceAccount -Identity $gMSAName
   Test-ADServiceAccount -Identity $gMSAName
   ```

5. Add the permissions to the gMSA service account. NTFS rights for shares if it needs to access files, SQL permissions if it needs to access a SQL database and rights to add accounts to groups and so on.

6. Either restart the server or purge the Kerberos ticket cache.  
   To purge and refresh your kerberos ticket cache, run the following commands:

   ```bash
   klist -li 0x3e7 purge
   gpupdate /force
   ```

:warning: **ONLY DO THIS IN A LAB ENVIRONMENT** :warning:  
Will make the KdsRootKey effective immediately without the 10h wait, but the DC will not have time to replicate to the other DC's.

```powershell
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
```

## Enable inheritance on all users in a specific OU

The following script will enable inheritance on all users in a specific OU.
This is usually needed when you get permission errors when trying to sync users to M365 via AD sync.

```powershell
# Source: https://techontip.wordpress.com/2021/12/21/enable-bulk-ad-security-permissions-inheritance-powershell/
# Enable inheritance on all users in a specific OU
$DistinguishedName = (Get-ADOrganizationalUnit -Filter * | Select-Object Name, distinguishedName | Out-GridView -Title "Pick OU" -Outputmode Single).distinguishedName
$ADusers = Get-ADUser -LDAPFilter '(objectclass=user)' -SearchBase $DistinguishedName
ForEach ($user in $ADusers) {
    # Binding the users to DS
    $ou = [ADSI]('LDAP://' + $user)
    $sec = $ou.psbase.objectSecurity

    try {
      if ($sec.get_AreAccessRulesProtected()) {
          $isProtected = $false ## allows inheritance
          $preserveInheritance = $true ## preserver inhreited rules
          $sec.SetAccessRuleProtection($isProtected, $preserveInheritance)
          $ou.psbase.commitchanges()
          Write-Host "$user is now inherting permissions" -ForegroundColor Green
      } else {
          Write-Host "$User Inheritable Permission already set" -ForegroundColor Blue
      }
    }
    catch {
         Write-Host "Error occurred while enabling inheritance for $user" -ForegroundColor Red
         Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
```

## Add custom attribute in AD

Can be made if the attribute is already in the schema, but not on the group/user, otherwise the schema needs to be extended with the wanted attribute.

```powershell
Get-ADGroup -Identity GroupNameHere | Set-ADGroup -Replace @{ReportToOriginator=$true}
```
