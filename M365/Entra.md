# Entra things

1. [Dynamic groups](#dynamic-groups)
   1. [All Users group](#all-users-group)
   2. [Based off membership in another group](#based-off-membership-in-another-group)
   3. [Based off a device manufacturer](#based-off-a-device-manufacturer)
   4. [Based off a device operating system](#based-off-a-device-operating-system)
2. [Elevate Global admin to be able to manage all Azure subscriptions](#elevate-global-admin-to-be-able-to-manage-all-azure-subscriptions)

## Dynamic groups

Add these to the Dynamic membership rules in Azure AD for the groups.  
[Microsoft documentation](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership) about dynamic groups, usable properties and operators.

### All Users group

Made by checking if the user has the Exchange component service attached to them, and adds them if they do. Component service ID's can be found [here.](/Good-links.md#m365)

```bash
((user.assignedPlans -any (assignedPlan.servicePlanId -eq "9aaf7827-d63c-4b61-89c3-182f06f82e5c" -and assignedPlan.capabilityStatus -eq "Enabled")) or (user.assignedPlans -any (assignedPlan.servicePlanId -eq "efb87545-963c-4e0d-99df-69c6916d9eb0" -and assignedPlan.capabilityStatus -eq "Enabled")) or (user.assignedPlans -any (assignedPlan.servicePlanId -eq "4a82b400-a79f-41a4-b4e2-e94f5787b113" -and assignedPlan.capabilityStatus -eq "Enabled"))) and (user.accountEnabled -eq true)
```

### Based off membership in another group

Microsoft documentation about this feature is found [here.](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-member-of)  
TL;DR: Only looks at direct members of group and not nested groups. Just like the rest of AAD pretty much.

**User:**

```bash
user.memberof -any (group.objectId -in ['objectID of group 1 here', 'objectID of group 2 here'])
```

**Device:**

```bash
device.memberof -any (group.objectId -in ['objectID of group 1 here', 'objectID of group 2 here'])
```

### Based off a device manufacturer

HP  
Group name: Intune-AllHPComputers

```bash
(device.deviceOSVersion -startsWith "10.0") -and (device.DeviceOSType -startsWith "Windows") -and (device.managementType -eq "MDM") -and (device.deviceManufacturer -contains "HP")
```

Lenovo  
Group name: Intune-AllLenovoComputers

```bash
(device.deviceOSVersion -startsWith "10.0") -and (device.DeviceOSType -startsWith "Windows") -and (device.managementType -eq "MDM") -and (device.deviceManufacturer -contains "Lenovo")
```

Dell  
Group name: Intune-AllDellComputers

```bash
(device.deviceOSVersion -startsWith "10.0") -and (device.DeviceOSType -startsWith "Windows") -and (device.managementType -eq "MDM") -and (device.deviceManufacturer -contains "Dell")
```

### Based off a device operating system

iOS Personal

```bash
((device.deviceOSType -eq "iPad") or (device.deviceOSType -eq "iPhone")) -and (device.deviceOwnership -eq "Personal")
```

iOS Corporate

```bash
((device.deviceOSType -eq "iPad") or (device.deviceOSType -eq "iPhone")) -and (device.deviceOwnership -eq "Company")
```

## Elevate Global admin to be able to manage all Azure subscriptions

Sometimes the button to elevate to be able to manage all subscriptions is greyed out. To fix this the az powershell module is needed.

If you don't have the Az module installed, run the following command to install it:

```powershell
Install-Module -Name Az
```

Then run the following command to elevate the global admin to be able to manage all subscriptions.

```powershell
# To make sure you are logged in to the correct tenant
az account clear
az login --allow-no-subscriptions

# Elevate the global admin
az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
```

Log in and out of the Azure portal and the Global admin should now be able to manage all subscriptions.
