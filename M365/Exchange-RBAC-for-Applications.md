# Guide: Restrict Mail.Send to specific mailboxes with Exchange RBAC for Applications

Purpose: An app (e.g. an archiving robot, a scanning flow or an integration) needs to send mail via Microsoft Graph, but only from specific mailboxes and not from every mailbox in the customer's tenant.

Principle: Mail.Send is NOT granted as an application permission in Entra. Instead, the "Application Mail.Send" role is assigned in Exchange Online and restricted with a management scope.

The guide can be used for any customer. Fill in the variables in step 0, and run the rest of the commands unchanged.

---

## Prerequisites

- An app registration exists in the customer's Entra.
- Mail.Send is NOT granted as an application permission in Entra (API permissions). Remove it if it is there, and also remove the admin consent.
- You have Exchange Administrator (or equivalent) in the customer's tenant and the ExchangeOnlineManagement module.

Important: Exchange gives the app the sum of its Entra permissions and RBAC assignments. If Mail.Send is also granted in Entra, the app has access to all mailboxes regardless of scope.

---

## Step 0: Connect and fill in variables

```powershell
# Connect to the customer's tenant (use -DelegatedOrganization with GDAP/partner access)
Connect-ExchangeOnline
# Connect-ExchangeOnline -DelegatedOrganization customer.onmicrosoft.com

# ---- Fill in per customer ----
$AppId        = "<Application (client) ID>"            # Entra > App registrations > Overview
$SpObjectId   = "<Enterprise Application Object ID>"   # Entra > Enterprise applications > Overview
$AppName      = "<Customer>-<AppName>"                 # e.g. "FS-SharePoint-Arkivering"
$Mailbox      = "<mailbox@customerdomain.com>"         # Used with method A
$GroupName    = "$AppName-MailSend"                    # Used with method B
$GroupSmtp    = "<group@customerdomain.com>"           # Used with method B
$ScopeName    = "$AppName-Scope"
$AssignName   = "$AppName-MailSend"
$TestMailbox  = "<other.user@customerdomain.com>"      # Mailbox that must NOT be in scope
```

Naming convention: Start all names with the customer abbreviation and app name, so it is easy to see what belongs together when you look at the setup again later.

---

## Step 1: Create the service principal in Exchange

```powershell
New-ServicePrincipal -AppId $AppId -ObjectId $SpObjectId -DisplayName $AppName
```

Note: $SpObjectId must be the Object ID from the Enterprise Application (service principal), not from the App registration. They are different and easy to mix up. If it is wrong, remove it and create it again:

```powershell
Remove-ServicePrincipal -Identity $SpObjectId
```

If the service principal already exists (e.g. from a previous setup), skip this step:

```powershell
Get-ServicePrincipal -Identity $SpObjectId
```

---

## Step 2: Create the management scope

Choose either method A or method B.

|             | Method A: Single mailbox      | Method B: Group                                       |
| ----------- | ----------------------------- | ----------------------------------------------------- |
| Suited when | There is only one fixed mailbox | There are several mailboxes, or more may be added   |
| Maintenance | New scope for each change     | Add/remove group members                              |
| Risk        | Low                           | Group owners can effectively expand the app's access  |

### Method A: One specific mailbox

```powershell
New-ManagementScope -Name $ScopeName `
  -RecipientRestrictionFilter "PrimarySmtpAddress -eq '$Mailbox'"
```

### Method B: Group

1. Create a mail-enabled security group, close it and hide it from the address book:

```powershell
New-DistributionGroup -Name $GroupName -Alias ($GroupName -replace '\s','') `
  -Type Security -PrimarySmtpAddress $GroupSmtp

Set-DistributionGroup -Identity $GroupName `
  -HiddenFromAddressListsEnabled $true `
  -MemberJoinRestriction Closed `
  -MemberDepartRestriction Closed
```

2. Add the mailboxes as direct members:

```powershell
Add-DistributionGroupMember -Identity $GroupName -Member "<mailbox1@customerdomain.com>"
Add-DistributionGroupMember -Identity $GroupName -Member "<mailbox2@customerdomain.com>"
```

3. Create the scope from the group's DistinguishedName (the filter requires the DN, not the name or email address):

```powershell
$GroupDN = (Get-DistributionGroup -Identity $GroupName).DistinguishedName

New-ManagementScope -Name $ScopeName `
  -RecipientRestrictionFilter "MemberOfGroup -eq '$GroupDN'"
```

Things to know about group scopes:

- Nested groups are not supported. The mailboxes must be direct members.
- Membership changes can take a while to take effect due to caching.
- Whoever can change the group's members can effectively let the app send as more mailboxes. Set owners deliberately (preferably admins only).

---

## Step 3: Assign the role to the app with the scope

```powershell
New-ManagementRoleAssignment -Name $AssignName `
  -Role "Application Mail.Send" `
  -App $SpObjectId `
  -CustomResourceScope $ScopeName
```

---

## Step 4: Test

A mailbox in scope should return InScope = True:

```powershell
Test-ServicePrincipalAuthorization -Identity $SpObjectId -Resource $Mailbox
```

A mailbox outside the scope should return InScope = False:

```powershell
Test-ServicePrincipalAuthorization -Identity $SpObjectId -Resource $TestMailbox
```

Test-ServicePrincipalAuthorization shows the result immediately. In Graph it can take from about 30 minutes to a couple of hours before the assignment works, because it is cached. If the app gets a 403 right after setup, wait before troubleshooting further.

---

## Overview

```powershell
Get-ServicePrincipal -Identity $SpObjectId
Get-ManagementScope -Identity $ScopeName | Format-List Name, RecipientFilter
Get-ManagementRoleAssignment -RoleAssignee $SpObjectId |
  Format-Table Name, Role, CustomResourceScope

# All apps with RBAC for Applications in the tenant
Get-ServicePrincipal | Format-Table DisplayName, AppId, ObjectId
```

## Cleanup (e.g. when offboarding an app or customer)

Run in this order:

```powershell
Remove-ManagementRoleAssignment -Identity $AssignName -Confirm:$false
Remove-ManagementScope -Identity $ScopeName -Confirm:$false
Remove-ServicePrincipal -Identity $SpObjectId -Confirm:$false

# Method B only
Remove-DistributionGroup -Identity $GroupName -Confirm:$false
```

---

## Checklist per customer

- [ ] Variables filled in with the customer's values
- [ ] Mail.Send is not granted in Entra (API permissions)
- [ ] Service principal created with the Enterprise Application Object ID
- [ ] Management scope created (method A or B)
- [ ] For method B: mailboxes are direct members, the group is hidden and closed
- [ ] Role assignment "Application Mail.Send" created with CustomResourceScope
- [ ] Test-ServicePrincipalAuthorization: True for the mailbox in scope, False for others
- [ ] Waited for the cache before testing from Graph
- [ ] The setup is documented in the customer's documentation (app, scope, mailboxes)
