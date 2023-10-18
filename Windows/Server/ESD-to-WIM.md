# Convert ESD to WIM

Change the first command to be whereever your mountpoint is for the ISO file.

```powershell
D:
cd ESD\sources\
dism /Get-WimInfo /WimFile:install.esd
Dism /export-image /SourceImageFile:install.esd /SourceIndex:5 /DestinationImageFile:install.wim /Compress:max /CheckIntegrity
```
