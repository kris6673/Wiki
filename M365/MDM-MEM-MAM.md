# Intune

## Table of Contents

- [Intune](#intune)
  - [Table of Contents](#table-of-contents)
  - [Maps drives via Intune script](#maps-drives-via-intune-script)
  - [Win32 apps](#win32-apps)
  - [Apple things](#apple-things)
    - [Apple Business Manager](#apple-business-manager)
      - [VPP token](#vpp-token)
      - [Apple Push Certifikat](#apple-push-certifikat)
      - [MDM server certifikat](#mdm-server-certifikat)
  - [Autopilot](#autopilot)
    - [Danish writeup about Autopilot](#danish-writeup-about-autopilot)

## Maps drives via Intune script

[Map network drives via Intune](https://tech.nicolonsky.ch/next-level-network-drive-mapping-with-intune/)

Does not require hybrid join/device writeback to the local AD to work.  
Making updates to the script and having it apply to the machine again, will overwrite the current scheduled task.

**Important:** Requires Windows Pro, an equivalent or above edition.

## Win32 apps

Detection method runs as SYSTEM, so the user folder and user variables are not available to use.

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
