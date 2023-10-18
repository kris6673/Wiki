# Change UPN suffix for all users in domain

Remember to change the 2 first variables before running

```powershell
$OldUPNDomain = "bobby.local"
$NewUPNDomain = "bobby.dk"

$LocalUsers = Get-ADUser -Filter "UserPrincipalName -like '*$OldUPNDomain'" -Properties userPrincipalName -ResultSetSize $null
$LocalUsers | ForEach-Object {$newUpn = $_.UserPrincipalName.Replace("@$OldUPNDomain","@$NewUPNDomain"); $_ | Set-ADUser -UserPrincipalName $newUpn}
```

---
[This MS Learn article](https://docs.microsoft.com/en-us/microsoft-365/enterprise/prepare-a-non-routable-domain-for-directory-synchronization?view=o365-worldwide) describes the use of the command and has been "borrowed" from there.
