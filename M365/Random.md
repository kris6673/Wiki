# Random links / Tips and tricks

## Table of Contents<!-- omit in toc -->

Random stuff I dont know where to put

1. [Add M365/Azure group to computer](#add-m365azure-group-to-computer)
2. [Add M365/Azure user to computer local admin group](#add-m365azure-user-to-computer-local-admin-group)

## Add M365/Azure group to computer

## Add M365/Azure user to computer local admin group

```powershell
Add-LocalGroupMember -SID S-1-5-32-544 -Member 'AzureAD\UserUpn@domain.com'
```

or

```bash
net localgroup Administrators /add "AzureAD\UserUPN@domain.com"
```
