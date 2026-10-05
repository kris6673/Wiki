# Guide: Begræns Mail.Send til udvalgte postkasser med Exchange RBAC for Applications

Formål: En app (fx en arkivrobot, et scanningsflow eller en integration) skal kunne sende mail via Microsoft Graph, men kun fra bestemte postkasser og ikke fra alle postkasser i kundens tenant.

Princip: Mail.Send tildeles IKKE som application permission i Entra. I stedet tildeles rollen "Application Mail.Send" i Exchange Online og afgrænses med en management scope.

Guiden kan bruges hos alle kunder. Udfyld variablerne i trin 0, og kør resten af kommandoerne uændret.

---

## Forudsætninger

- App registration findes i kundens Entra.
- Mail.Send er IKKE tildelt som application permission i Entra (API permissions). Fjern den, hvis den er der, og fjern også admin consent.
- Du har Exchange Administrator (eller tilsvarende) i kundens tenant og ExchangeOnlineManagement-modulet.

Vigtigt: Exchange giver appen summen af Entra-tilladelser og RBAC-tildelinger. Hvis Mail.Send også ligger i Entra, har appen adgang til alle postkasser, uanset scope.

---

## Trin 0: Forbind og udfyld variabler

```powershell
# Forbind til kundens tenant (brug -DelegatedOrganization ved GDAP/partneradgang)
Connect-ExchangeOnline
# Connect-ExchangeOnline -DelegatedOrganization kunde.onmicrosoft.com

# ---- Udfyld pr. kunde ----
$AppId        = "<Application (client) ID>"            # Entra > App registrations > Overview
$SpObjectId   = "<Enterprise Application Object ID>"   # Entra > Enterprise applications > Overview
$AppName      = "<Kunde>-<Appnavn>"                    # fx "FS-SharePoint-Arkivering"
$Mailbox      = "<postkasse@kundedomæne.dk>"           # Bruges ved metode A
$GroupName    = "$AppName-MailSend"                    # Bruges ved metode B
$GroupSmtp    = "<gruppe@kundedomæne.dk>"              # Bruges ved metode B
$ScopeName    = "$AppName-Scope"
$AssignName   = "$AppName-MailSend"
$TestMailbox  = "<anden.bruger@kundedomæne.dk>"        # Postkasse der IKKE må være i scope
```

Navnestandard: Start alle navne med kundeforkortelse og appnavn, så det er let at se, hvad der hører sammen, når man ser opsætningen igen senere.

---

## Trin 1: Opret service principal i Exchange

```powershell
New-ServicePrincipal -AppId $AppId -ObjectId $SpObjectId -DisplayName $AppName
```

Bemærk: $SpObjectId skal være Object ID fra Enterprise Application (service principal) og ikke fra App registration. De er forskellige og nemme at forveksle. Er den forkert, så fjern den og opret den igen:

```powershell
Remove-ServicePrincipal -Identity $SpObjectId
```

Findes service principal'en allerede (fx fra en tidligere opsætning), så spring trinnet over:

```powershell
Get-ServicePrincipal -Identity $SpObjectId
```

---

## Trin 2: Opret management scope

Vælg enten metode A eller metode B.

|              | Metode A: Én postkasse       | Metode B: Gruppe                                       |
| ------------ | ---------------------------- | ------------------------------------------------------ |
| Velegnet når | Der kun er én fast postkasse | Der er flere postkasser, eller der kan komme flere til |
| Vedligehold  | Ny scope pr. ændring         | Tilføj/fjern gruppemedlemmer                           |
| Risiko       | Lav                          | Gruppeejere kan reelt udvide appens adgang             |

### Metode A: Én bestemt postkasse

```powershell
New-ManagementScope -Name $ScopeName `
  -RecipientRestrictionFilter "PrimarySmtpAddress -eq '$Mailbox'"
```

### Metode B: Gruppe

1. Opret en mail-enabled security group, luk den og skjul den fra adressebogen:

```powershell
New-DistributionGroup -Name $GroupName -Alias ($GroupName -replace '\s','') `
  -Type Security -PrimarySmtpAddress $GroupSmtp

Set-DistributionGroup -Identity $GroupName `
  -HiddenFromAddressListsEnabled $true `
  -MemberJoinRestriction Closed `
  -MemberDepartRestriction Closed
```

2. Tilføj postkasserne som direkte medlemmer:

```powershell
Add-DistributionGroupMember -Identity $GroupName -Member "<postkasse1@kundedomæne.dk>"
Add-DistributionGroupMember -Identity $GroupName -Member "<postkasse2@kundedomæne.dk>"
```

3. Opret scope ud fra gruppens DistinguishedName (filteret kræver DN og ikke navn eller mailadresse):

```powershell
$GroupDN = (Get-DistributionGroup -Identity $GroupName).DistinguishedName

New-ManagementScope -Name $ScopeName `
  -RecipientRestrictionFilter "MemberOfGroup -eq '$GroupDN'"
```

Ting at vide om gruppe-scope:

- Nested groups understøttes ikke. Postkasserne skal være direkte medlemmer.
- Ændringer i medlemskab kan tage tid om at slå igennem pga. caching.
- Den, der kan ændre gruppens medlemmer, kan reelt give appen adgang til at sende som flere postkasser. Sæt ejere bevidst (helst kun admins).

---

## Trin 3: Tildel rollen til appen med scope

```powershell
New-ManagementRoleAssignment -Name $AssignName `
  -Role "Application Mail.Send" `
  -App $SpObjectId `
  -CustomResourceScope $ScopeName
```

---

## Trin 4: Test

Postkasse i scope skal give InScope = True:

```powershell
Test-ServicePrincipalAuthorization -Identity $SpObjectId -Resource $Mailbox
```

Postkasse uden for scope skal give InScope = False:

```powershell
Test-ServicePrincipalAuthorization -Identity $SpObjectId -Resource $TestMailbox
```

Test-ServicePrincipalAuthorization viser resultatet med det samme. I Graph kan der gå fra ca. 30 minutter til et par timer, før tildelingen virker, fordi den caches. Får appen 403 lige efter opsætningen, så vent, før du fejlsøger videre.

---

## Overblik

```powershell
Get-ServicePrincipal -Identity $SpObjectId
Get-ManagementScope -Identity $ScopeName | Format-List Name, RecipientFilter
Get-ManagementRoleAssignment -RoleAssignee $SpObjectId |
  Format-Table Name, Role, CustomResourceScope

# Alle apps med RBAC for Applications i tenanten
Get-ServicePrincipal | Format-Table DisplayName, AppId, ObjectId
```

## Oprydning (fx ved offboarding af app eller kunde)

Kør i denne rækkefølge:

```powershell
Remove-ManagementRoleAssignment -Identity $AssignName -Confirm:$false
Remove-ManagementScope -Identity $ScopeName -Confirm:$false
Remove-ServicePrincipal -Identity $SpObjectId -Confirm:$false

# Kun ved metode B
Remove-DistributionGroup -Identity $GroupName -Confirm:$false
```

---

## Tjekliste pr. kunde

- [ ] Variabler udfyldt med kundens værdier
- [ ] Mail.Send er ikke tildelt i Entra (API permissions)
- [ ] Service principal oprettet med Enterprise Application Object ID
- [ ] Management scope oprettet (metode A eller B)
- [ ] Ved metode B: postkasser er direkte medlemmer, gruppen er skjult og lukket
- [ ] Role assignment "Application Mail.Send" oprettet med CustomResourceScope
- [ ] Test-ServicePrincipalAuthorization: True for postkasse i scope, False for andre
- [ ] Ventet på cache før test fra Graph
- [ ] Opsætningen er dokumenteret i kundens dokumentation (app, scope, postkasser)
