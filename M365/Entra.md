# Entra things

1. [Dynamic groups](#dynamic-groups)
   1. [All Users group](#all-users-group)
   2. [Based off membership in another group](#based-off-membership-in-another-group)

## Dynamic groups

Add these to the Dynamic membership rules in Azure AD for the groups.

### All Users group

Made by checking if the user has the Exchange component service attached to them, and adds them if they do. Component service ID's can be found [here.](/Good-links.md#m365)

```bash
(user.assignedPlans -any (assignedPlan.servicePlanId -eq "9aaf7827-d63c-4b61-89c3-182f06f82e5c" -and assignedPlan.capabilityStatus -eq "Enabled")) or (user.assignedPlans -any (assignedPlan.servicePlanId -eq "efb87545-963c-4e0d-99df-69c6916d9eb0" -and assignedPlan.capabilityStatus -eq "Enabled")) or (user.assignedPlans -any (assignedPlan.servicePlanId -eq "4a82b400-a79f-41a4-b4e2-e94f5787b113" -and assignedPlan.capabilityStatus -eq "Enabled")) and (user.accountEnabled -eq true)
```

### Based off membership in another group

Microsoft documentation about this feature is found [here.](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-member-of)  
TL;DR: Only looks at direct members of group and not nested groups. Just like the rest of AAD pretty much.

**User:**

```bash
user.memberof -any (group.objectId -in ['objectID of group here'])
```

**Device:**

```bash
device.memberof -any (group.objectId -in ['objectID of group here'])
```
