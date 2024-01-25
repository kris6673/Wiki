# Active Directory Domain Services

## Table of Contents <!-- omit in toc -->

1. [Group Managed Service Accounts (gMSA)](#group-managed-service-accounts-gmsa)

## Group Managed Service Accounts (gMSA)

There is a specific order to make these work.

- Install the Kerberos Root Key on the server you need to use the gMSA on. Before you use the service account, 10 hours needs to have passed, to make sure the key has been replicated to all DCs.

```powershell
Add-KdsRootKey -EffectiveImmediately
```

- Create the group that will be allowed to use the gMSA. Should be named something like "GMSA_ServiceName". This is the group that the computer account objects that can use the gMSA will be added to.

- Create the gMSA account. The account will be created in the default OU for Managed Service Accounts.

```powershell
$gMSAName = 'gMSA_PS_add-kioskcomputer'
$gMSAFQDN = ($gMSAName + '.' + (Get-ADDomain).DNSRoot).ToString()
$gMSAGroupName = (Get-ADGroup -Filter * | Out-GridView -OutputMode Single -Title 'Select the group that will be allowed to use the gMSA').Name
New-ADServiceAccount -Name $gMSAName -DNSHostName $gMSAFQDN -PrincipalsAllowedToRetrieveManagedPassword GMSA_PS_add-kioskcomputer -ServicePrincipalNames http/svc_ps_mgmt01.domain.local
```

- Install the gMSA on the server you need to use the gMSA on.

```powershell
$gMSAName = 'gMSA_PS_add-kioskcomputer'
Install-ADServiceAccount -Identity $gMSAName
```

- Add the permissions to the gMSA service account. NTFS rights for shares if it needs to access files, SQL permissions if it needs to access a SQL database and rights to add accounts to groups and so on.

- Either restart the server or purge the Kerberos ticket cache.

```powershell
$gMSAName = 'gMSA_PS_add-kioskcomputer'
Install-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDirectory
klist -li 0x3e7 purge
gpupdate /force
Install-ADServiceAccount -Identity $gMSAName
Test-ADServiceAccount -Identity $gMSAName
```
