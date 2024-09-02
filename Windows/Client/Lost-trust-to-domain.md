# Machine has lost trust to the domain and can't log in

<https://theitbros.com/fix-trust-relationship-failed-without-domain-rejoining/>
<https://redmondmag.com/articles/2014/04/21/domain-trust-issues.aspx>

Kør følgende i powershell (kør som admin)

## The fix

Test trust to domain:

```powershell
Test-ComputerSecureChannel -Verbose
```

If trust is lost/bad, run the following command to fix it:  
**The specified user needs to have permissions to reset computer passwords in the domain**

```powershell
# Dosnt require reboot
Test-ComputerSecureChannel -Repair -Credential DomainName\Administrator
```

If the above dosnt work

```powershell
Reset-ComputerMachinePassword -Server "AD-Server-Hostname" -navn -Credential domain\server-administrator-user
# Reboot machine and test trust to domain again
```
