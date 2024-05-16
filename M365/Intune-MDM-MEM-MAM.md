# Intune

## Table of Contents<!-- omit in toc -->

1. [Map drives via Intune script](#map-drives-via-intune-script)
   1. [Notes](#notes)
   2. [Remove any wrong drive mappings](#remove-any-wrong-drive-mappings)
2. [Install printer drivers via Intune](#install-printer-drivers-via-intune)
3. [Win32 apps](#win32-apps)
   1. [Powershell install script for MSI Win32 apps](#powershell-install-script-for-msi-win32-apps)
   2. [Find ProductCode for detection method for MSI Win32 apps](#find-productcode-for-detection-method-for-msi-win32-apps)
   3. [Find MSI ProductCode for digitally signed MSI files without installing the program](#find-msi-productcode-for-digitally-signed-msi-files-without-installing-the-program)
   4. [Find uninstall string for installed programs](#find-uninstall-string-for-installed-programs)
   5. [Run script in 64bit PowerShell if running from 32bit](#run-script-in-64bit-powershell-if-running-from-32bit)
   6. [Troubleshooting](#troubleshooting)
4. [Hybrid Join](#hybrid-join)
   1. [Troubleshooting](#troubleshooting-1)
5. [Apple things](#apple-things)
   1. [Apple Business Manager](#apple-business-manager)
      1. [VPP token](#vpp-token)
      2. [Apple Push Certifikat](#apple-push-certifikat)
      3. [MDM server certifikat](#mdm-server-certifikat)
      4. [User VS Device enrollment](#user-vs-device-enrollment)
6. [Autopilot](#autopilot)
   1. [Links](#links)
   2. [Skip App install during Autopilot ESP](#skip-app-install-during-autopilot-esp)
   3. [Danish writeup about Autopilot](#danish-writeup-about-autopilot)
7. [Links to stuff](#links-to-stuff)

## Map drives via Intune script

[Map network drives via Intune](https://tech.nicolonsky.ch/next-level-network-drive-mapping-with-intune/)
[GitHub wiki page the creator made](https://github.com/nicolonsky/IntuneDriveMapping/wiki)
[Trigger on VPN connection](https://github.com/nicolonsky/IntuneDriveMapping/wiki/Trigger-Script-on-VPN-Connection)

### Notes

- Does not require hybrid join/device writeback to the local AD to work.
- Making updates to the script and having it apply to the machine again, will overwrite the current scheduled task.
- If the users password is expired, the script will fail to map the drives.
- If you want to use environment variables use PowerShell environment variables: \\\lan.customer.local\homes\$env:username
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

## Install printer drivers via Intune

[This blog has the answers](https://powershellisfun.com/2022/12/05/adding-printer-drivers-and-printers-using-microsoft-intune-and-powershell/)

## Win32 apps

Detection method runs as SYSTEM, so the user folder and user variables are not available to use.

### Powershell install script for MSI Win32 apps

```powershell
# Get msi file
$File = Get-ChildItem -Path $PSScriptRoot -Filter *.msi
# Prepare log file
$DataStamp = Get-Date -Format yyyy-MM-dd-THHmmss
$logFile = "$env:ALLUSERSPROFILE\$($File.Name)-$DataStamp.log"
# List of arguments for msi file install
$MSIArguments = @(
    '/i'
    $File.FullName
    '/qn'
    '/norestart'
    '/L*v'
    '{0}' -f $logFile
    'ALLUSERS=1'
)
# Install msi file with arguments and wait for it to finish
Write-Host "Installing $($File.Name)..."
Start-Process 'msiexec.exe' -ArgumentList $MSIArguments -Wait -NoNewWindow

if ($LASTEXITCODE -ne 0) {
    Write-Host "MSI install failed with ExitCode:$LASTEXITCODE. See log file: $logFile"
    Exit $LASTEXITCODE
}
Write-Host "Success: MSI install exit code: $LASTEXITCODE"
Return $LASTEXITCODE

```

### Find ProductCode for detection method for MSI Win32 apps

```powershell
$Installer = New-Object -ComObject WindowsInstaller.Installer; $InstallerProducts = $Installer.ProductsEx("", "", 7); $InstalledProducts = ForEach($Product in $InstallerProducts){[PSCustomObject]@{ProductCode = $Product.ProductCode(); LocalPackage = $Product.InstallProperty("LocalPackage"); VersionString = $Product.InstallProperty("VersionString"); ProductPath = $Product.InstallProperty("ProductName")}} $InstalledProducts
```

### Find MSI ProductCode for digitally signed MSI files without installing the program

```powershell
$MSIPath = "C:\Path\To\MSI.msi"
Get-AppLockerFileInformation -Path $MSIPath | select -ExpandProperty Publisher | Select BinaryName
```

### Find uninstall string for installed programs

Find the uninstall string key in one of these paths.

For x64 apps:

```batch
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
```

For x86 apps:

```batch
HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall
```

If its an MSI app, the uninstall string will be something like:

```batch
MsiExec.exe /X "{c803ba69-51e1-4dcd-b432-6f652f7ba684}"
```

Add /qn to the end of the string to make it silent.

### Run script in 64bit PowerShell if running from 32bit

Intune Management Extension runs in 32bit mode, so some commands are not available. Use this to run the script in 64bit mode.This fixes issues with the following commands not being found:

- pnputil.exe
- query.exe

```powershell
# Run script in 64bit PowerShell if running from 32bit to avoid issues with 64bit only commands/functions
# $ENV:PROCESSOR_ARCHITEW6432 is only available in 32bit PowerShell
If ($ENV:PROCESSOR_ARCHITEW6432 -eq 'AMD64') {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH @PSBoundParameters
    } Catch {
        Write-Error "Failed to start $PSCOMMANDPATH"
        Write-Warning "$($_.Exception.Message)"
    }
   Exit
}
```

### Troubleshooting

[Win32 logs and how to decipher the logs](/Good-links.md#intune)
[Intune management extension logs diagnostics](/Good-links.md#intune)  
[CMtrace download link](/Good-links.md#intune)

## Hybrid Join

### Troubleshooting

If the following error is seen in the event log under Applications and Services Logs > Microsoft > Windows > DeviceManagement-Enterprise-Diagnostic-Provider > Admin:

```plaintext
MDM Session: OMA-DM message failed to be sent. Result: (Unknown Win32 Error code: 0x80072ee7).
```

You can rejoin the device to Azure AD with the following script: [Rejoin script](https://github.com/AdamGrossTX/Toolbox/blob/master/Intune/Intune-UnHybridJoin.ps1)  
This needs to be run as SYSTEM, so you can use the following command to run it as SYSTEM:

```powershell
Invoke-WebRequest -Uri 'https://live.sysinternals.com/PsExec64.exe'-OutFile $env:TEMP\PsExec64.exe

# Run the script as SYSTEM on local machine
Start-Process $env:TEMP\PsExec64.exe '-s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe'
# Run the script as SYSTEM on remote machine
Start-Process $env:TEMP\PsExec64.exe '\\RemoteMachineName' '-s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe'

```

Download the script and run it in the SYSTEM shell.

```powershell
# Download the script from GitHub
$URI = "https://raw.githubusercontent.com/AdamGrossTX/Toolbox/master/Intune/Intune-UnHybridJoin.ps1"
Invoke-WebRequest -Uri $URI -OutFile "$env:TEMP\Intune-UnHybridJoin.ps1"
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
& $env:TEMP\Intune-UnHybridJoin.ps1 -Remediate 1 -Rejoin 1
# Remove the script after running it
Remove-Item -Path "$env:TEMP\Intune-UnHybridJoin.ps1" -Force
```

This should rejoin the PC and fix the issue.

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
Udstedes til ét specifik apple id og kan ikke skiftes medmindre **alle** enheder genenrolles i MDM'en/Intune.

#### MDM server certifikat

Laves under Apple enrollment fanen.

#### User VS Device enrollment

**User enrollment:** requires iOS 13.0 or later, and crucially needs to have a managed Apple ID to work. Otherwise the device management profile cannot be installed to the device. Federated authentication and automatic sync of Entra ID identities is recommended for this, otherwise all users will have to be created manually in Apple Business Manager. User enrollment is considered the more user friendly option, as it allows the user to keep their personal data separate from the company data.

**Device enrollment:** requires iOS 5.0 or later. This was the default and only way of enrolling BYOD devices before 2023. [Webbased device enrollment](https://www.petervanderwoude.nl/post/getting-started-with-web-based-device-enrollment-for-ios-devices/) or Company portal app enrollment are the 2 options for this. This is pretty much the "I don't wanna deal with managed Apple ID's" option.

## Autopilot

It's not the same as Intune!

### Links

[Autopilot, ESP and extra login/reboots](https://blog.onevinn.com/autopilot-esp-and-extra-login-reboots)
[Autopilot extra sign-ins](https://www.reddit.com/r/Intune/comments/10y3715/autopilot_oobe_is_requiring_3_sign_ins_and_the/)

### [Skip App install during Autopilot ESP](https://call4cloud.nl/2022/08/autopilot-is-mine-all-others-pay-time/)

Add this to the requirement section of the app in Intune, if the app is unable to install silently during ESP:

```powershell
$ProcessActive = Get-Process "WWAHost" -ErrorAction silentlycontinue
$CheckNull = $ProcessActive -eq $null
$CheckNull
```

Requirement settings should be setup like this:
![Requirements script settings](/Pics/Intune_MDM_Requirement.png)

### Danish writeup about Autopilot

Først, AutoPilot servicen har INTET at gøre med Intune, MEN AutoPilot kan opsættes til at enrolle enheden i Intune. Dette gøres i 99,99% af alle tilfælde.
AutoPilot er KUN for Windows enheder.
Enheder kan registreres i AutoPilot på 4 måder:

1. Via OEM køb.
   - Her registrer selve firmaet vi køber enheden hos, enheden i Autopilot. Dette vil ske inden nogen får hænderne på PC'en fysisk. Vil være hvis vi køber direkte fra eks Dell, HP eller Lenovo.
2. Via Partner portal.
   - Her laves der en CSV fil med følgende info i: Device serial number,Windows product ID*(optional)*,Hardware hash*(optional)*,Manufacturer name,Device Model. Info fåes her fra der hvor den er købt, såsom Computersalg/CBC. Preben eller Søren vil kunne fremskaffe denne info, ellers skal den indhentes fra hvad der står på kasserne som PC'erne blev leveret i. Dette er en god mulighed hvis kunden skal have mange PC'er skiftet på én gang, eller hvis de køber mange PC'er ad gangen, og stille og roligt bruger dem som de skiftes.
3. Via manuel registrering med CSV fil i kunden Intune portal.
   - Powershell command installeres på PC til at lave et hardware hash, som kan uploades til Intune portalen. Kommandoerne til dette kan findes i SupportScripts mappen, under scriptet Enroll-ComputerInAutopilot.ps1. Det kan være lidt besværligt, da man skal have en CSV fil ud af PC'en, inden den er kommet forbi OOBE'en. Efter upload af CSV fil kan det tage op til 1 time inden sync er færdig og AutoPilot profil er tildelt.
     Denne mulighed anbefales kun hvis man ikke har mulighed for at bruge kommandoen i næste step.
   - **Reminder:** Shift+F10 i OOBE'en får en cmd frem hvor du kan skrive "powershell" + enter i, så har du en powershell shell.
4. Via manuel registrering i kundens tenant med powershell + login i 365.
   - Her installes powershell command ligesom i step 3, men der bruges i stedet direkte login og registrering i 365. Her vil der skulle logges ind med en Intune admin/global admin konto, og så venter den på at den får en AutoPilot profil tildelt og genstarter automatisk når den er klar. Herefter er den klar til at logge ind og blive Azure AD joined + Intune enrolled. Kommandoerne til dette kan findes i SupportScripts mappen, under scriptet Enroll-ComputerInAutopilot.ps1.
     Denne metode anbefales hvis der ikke er voldsomt mange PC'er som skal enrolles/deployes samtidigt.
   - **Reminder:** Shift+F10 i OOBE'en får en cmd frem hvor du kan skrive "powershell" + enter i, så har du en powershell shell.

![Autopilot chart](/Pics/AutoPilotDeployment.png)

## Links to stuff

[WindowsHardening - CIS standard for Windows computers](https://github.com/R33Dfield/WindowsHardening)  
[More CIS standard stuff](https://www.everything365.online/2023/09/18/cis-microsoft-intune-for-windows-11-benchmark-in-settings-catalog-json/)
