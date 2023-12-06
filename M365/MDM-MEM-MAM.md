# Intune

## Table of Contents<!-- omit in toc -->

1. [Maps drives via Intune script](#maps-drives-via-intune-script)
   1. [Notes](#notes)
   2. [Remove any wrong drive mappings](#remove-any-wrong-drive-mappings)
2. [Win32 apps](#win32-apps)
   1. [Find ProductCode for detection method for MSI Win32 apps](#find-productcode-for-detection-method-for-msi-win32-apps)
   2. [Find uninstall string for installed programs](#find-uninstall-string-for-installed-programs)
3. [Apple things](#apple-things)
   1. [Apple Business Manager](#apple-business-manager)
      1. [VPP token](#vpp-token)
      2. [Apple Push Certifikat](#apple-push-certifikat)
      3. [MDM server certifikat](#mdm-server-certifikat)
4. [Autopilot](#autopilot)
   1. [Danish writeup about Autopilot](#danish-writeup-about-autopilot)

## Maps drives via Intune script

[Map network drives via Intune](https://tech.nicolonsky.ch/next-level-network-drive-mapping-with-intune/)

### Notes

- Does not require hybrid join/device writeback to the local AD to work.
- Making updates to the script and having it apply to the machine again, will overwrite the current scheduled task.
- If the users password is expired, the script will fail to map the drives.
- You can add multiple groups as a filter like this: "GroupFilter":"Adgang_Faelles_F_ReadWrite,Adgang_Faelles_F_Read" aka separated with a comma.
- **Important:** Requires Windows Pro, an equivalent or above edition. (Since Intune scripts cant run on Windows Home edition)

### Remove any wrong drive mappings

Add the following to the script to remove any wrong drive mappings:

```powershell
    Write-Host "Testing if drives are mapped correctly..."
    $WrongDrives = Get-PSDrive | Where-Object { $_.DisplayRoot -ne "$($drive.Path)" -and $_.Name -eq $drive.Driveletter }
    if ($WrongDrives) {
     foreach ($WrongDrive in $WrongDrives) {
      Write-Host "Wrong drive config for $($WrongDrive.Name) found. Removing it..." -ForegroundColor Yellow
      cmd /r "net use $($WrongDrive.Name): /delete"
      Start-Sleep 3
     }
    }
```

This needs to be added between:

```powershell
if ($process) {
   # Add it here
   Write-Output "Mapping network drive $($drive.Path)"
```

## Win32 apps

Detection method runs as SYSTEM, so the user folder and user variables are not available to use.

### Find ProductCode for detection method for MSI Win32 apps

```powershell
$Installer = New-Object -ComObject WindowsInstaller.Installer; $InstallerProducts = $Installer.ProductsEx("", "", 7); $InstalledProducts = ForEach($Product in $InstallerProducts){[PSCustomObject]@{ProductCode = $Product.ProductCode(); LocalPackage = $Product.InstallProperty("LocalPackage"); VersionString = $Product.InstallProperty("VersionString"); ProductPath = $Product.InstallProperty("ProductName")}} $InstalledProducts
```

### Find uninstall string for installed programs

Find the uninstall string key in one of these paths.

For x64 apps:

```batch
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
```

For x86 apps:

```batch
KEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
```

If its an MSI app, the uninstall string will be something like:

```batch
MsiExec.exe /X "{c803ba69-51e1-4dcd-b432-6f652f7ba684}"
```

Add /qn to the end of the string to make it silent.

## Apple things

### Apple Business Manager

Bruges til at designere en MDM platform der bruges.
Skal enheder DEP'es manuelt kan de meldes ud i 30 dage.
Derfor foretrækkes det at forhandler vi køber gennem gør dette.
Man kan enrolle dem manuelt med enten Apple Configurator 2 appen, eller med Apple Configurator på MacOS

#### VPP token

Er bundet på moms nummer for virksomheden og kræver et tilknyttet kort.
**OBS:** Man kan ikke browse app storen, uden at søge efter noget.

#### Apple Push Certifikat

LAV FOR GUDS SKYLD DETTE MED EN IKKE-PERSONLIG APPLE ID.
Udstedes til ét specifik apple id og kan ikke skiftes medmindre alle enheder genenrolles i MDM'en/Intune.

#### MDM server certifikat

Laves under Apple enrollment fanen.

## Autopilot

It's not the same as Intune!

### Danish writeup about Autopilot

Først, AutoPilot servicen har INTET at gøre med Intune, MEN AutoPilot kan opsættes til at enrolle enheden i Intune. Dette gøres i 99,99% af alle tilfælde.
AutoPilot er KUN for Windows enheder.
Enheder kan registreres i AutoPilot på 4 måder:

1. Via OEM køb.
   - Her registrer selve firmaet vi køber enheden hos, enheden i Autopilot. Dette vil ske inden nogen får hænderne på PC'en fysisk. Vil være hvis vi køber direkte fra eks Dell, HP eller Lenovo.
2. Via Partner portal.
   - Her laves der en CSV fil med følgende info i: Device serial number,Windows product ID*(optional)*,Hardware hash*(optional)*,Manufacturer name,Device Model. Info fåes her fra der hvor den er købt, såsom Computersalg/CBC. Preben eller Søren vil kunne fremskaffe denne info, ellers skal den indhentes fra hvad der står på kasserne som PC'erne blev leveret i. Dette er en god mulighed hvis kunden skal have mange PC'er skiftet på én gang, eller hvis de køber mange PC'er ad gangen, og stille og roligt bruger dem som de skiftes.
3. Via manuel registrering med CSV fil i kunden Intune portal.
   - Powershell command installeres på PC til at lave et hardware hash, som kan uploades til Intune portalen. Kommanoerne til dette kan findes i SupportScripts mappen, under scriptet Enroll-ComputerInAutopilot.ps1. Det kan være lidt besværligt, da man skal have en CSV fil ud af PC'en, inden den er kommet forbi OOBE'en. Efter upload af CSV fil kan det tage op til 1 time inden sync er færdig og AutoPilot profil er tildelt.
     Denne mulighed anbefales kun hvis man ikke har mulighed for at bruge kommandoen i næste step.
   - **Reminder:** Shift+F10 i OOBE'en får en cmd frem hvor du kan skrive "powershell" + enter i, så har du en powershell shell.
4. Via manuel registrering i kundens tenant med powershell + login i 365.
   - Her installes powershell command ligesom i step 3, men der bruges i stedet direkte login og registrering i 365. Her vil der skulle logges ind med en Intune admin/global admin konto, og så venter den på at den får en AutoPilot profil tildelt og genstarter automatisk når den er klar. Herefter er den klar til at logge ind og blive Azure AD joined + Intune enrolled. Kommanoerne til dette kan findes i SupportScripts mappen, under scriptet Enroll-ComputerInAutopilot.ps1.
     Denne metode anbefales hvis der ikke er voldsomt mange PC'er som skal enrolles/deployes samtidigt.
   - **Reminder:** Shift+F10 i OOBE'en får en cmd frem hvor du kan skrive "powershell" + enter i, så har du en powershell shell.
