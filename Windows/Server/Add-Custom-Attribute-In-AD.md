# Add custom attribute in AD

Can be made if the attribute is already in the schema, but not on the group/user, otherwise the schema needs to be extended with the wanted attribute.

```powershell
Get-ADGroup -Identity GroupNameHere | Set-ADGroup -Replace @{ReportToOriginator=$true}
```
