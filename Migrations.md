# Migrations

This is a help page for the different types of migrations that can be done.

## Table of Contents <!-- omit in toc -->

1. [Genreral info and help](#genreral-info-and-help)
   1. [Setting MsExchangeMailboxGuid to NULL / AD synced users have no mailbox in the cloud, but have in on-prem exchange server](#setting-msexchangemailboxguid-to-null--ad-synced-users-have-no-mailbox-in-the-cloud-but-have-in-on-prem-exchange-server)
2. [Bittitan](#bittitan)
   1. [General info](#general-info)
   2. [Disable throttling in EXO](#disable-throttling-in-exo)
   3. [Timeout issues causing migration to fail - This migration has failed because the source or destination endpoint](#timeout-issues-causing-migration-to-fail---this-migration-has-failed-because-the-source-or-destination-endpoint)
   4. [Add logging to failed items](#add-logging-to-failed-items)
   5. [Turn off Calendar assistant](#turn-off-calendar-assistant)
   6. [Links to guides](#links-to-guides)
3. [Movebot](#movebot)
4. [PST import to EXO](#pst-import-to-exo)
   1. [**AND FOR THE LOVE OF GOD AND ALL THAT IS HOLY, PLEASE DONT FORGET THE '/' IN THE TargetRootFolder PROPERTY IN THE CSV FILE** ](#and-for-the-love-of-god-and-all-that-is-holy-please-dont-forget-the--in-the-targetrootfolder-property-in-the-csv-file-)
5. [ProfWiz](#profwiz)
   1. [Steps for migration to Entra ID](#steps-for-migration-to-entra-id)
      1. [Pre-migration steps](#pre-migration-steps)
      2. [Migration steps](#migration-steps)

## Genreral info and help

### Setting MsExchangeMailboxGuid to NULL / AD synced users have no mailbox in the cloud, but have in on-prem exchange server

Guide for this is found [here](.//Good-links.md#ad-sync)

## Bittitan

Everything useful I've found for Bittitan migrations.

---

### General info

Mailbox data is migrated from newest to oldest items. So the user gets their newest emails first.

### Disable throttling in EXO

[Disabled via support request in the admin center.](https://help.bittitan.com/hc/en-us/articles/12001669149851-How-to-Disable-EWS-Throttling-in-Exchange-Online)

1. Log into the admin center as a GA for the customer.
2. Write "Increase EWS Throttling Policy" in the support search field.
3. Run tests and set the days to 90 and press "Update settings".

### Timeout issues causing migration to fail - This migration has failed because the source or destination endpoint

Add the following to the advanced options of the project.  
Both mailbox and document migrations.

```text
ExtendedEwsTimeout=1
InitializationTimeout=8
```

Read more about the support options [here](#links-to-guides)

### Add logging to failed items

Check the following checkmark in the advanced options of the project, under **Maintenance -> Log subjects of failed items.**

### Turn off Calendar assistant

**Note:** This will disable the calendar assistant for all users in the tenant. This will need to be turned back on after the migration is complete. This is done to ensure that the calendar assistant doesn't interfere with the migration and break meetings and recurring meetings.

```powershell
Get-EXOMailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $true
```

**Note:** Turn back on Calendar assistant for all users.

```powershell
Get-EXOMailbox -ResultSize unlimited | Set-Mailbox -CalendarRepairDisabled $false
```

### Links to guides

[IP lockdown of migrations](https://help.bittitan.com/hc/en-us/articles/115008252928-IP-Addresses-Connected-to-During-IP-LockDown#set-advanced-options-for-the-project-in-migrationwiz-0-0)  
[Mailboxes over 100 GB/Large mailboxes](https://help.bittitan.com/hc/en-us/articles/360044916654-Microsoft-365-Mailbox-Migration-FAQ#-migrating-mailboxes-larger-than-100gb-0-22)  
[M365 to M365](https://help.bittitan.com/hc/en-us/articles/6488570876955-Exchange-Online-Microsoft-365-to-Exchange-Online-Microsoft-365-Mailbox-Migration-Guide)  
[On-Prem and Hosted Exchange to M365](https://help.bittitan.com/hc/en-us/articles/115008266088-Exchange-2007-Hosted-and-On-Premises-to-Microsoft-365-Migration-Guide)  
[Scoped inpersonation](https://help.bittitan.com/hc/en-us/articles/115015661147-MigrationWiz-Impersonation-and-Delegation-for-Microsoft-365-Exchange-Migrations#scoped-impersonation-with-ews-0-3)  
[OneDrive to OneDrive](https://help.bittitan.com/hc/en-us/articles/360011172673-OneDrive-to-OneDrive-for-Business-without-Versions-and-Metadata-migration-guide)  
[All Bititan support options](https://help.bittitan.com/hc/en-us/articles/360043369293-MigrationWiz-Support-Options)  
[MigrationWiz - Advanced Options & General Options](https://help.bittitan.com/hc/en-us/articles/360043891714-MigrationWiz-Advanced-Options-General-Options#h_01HC38V3KNNRY4TEJG0AW70QVC)

<!-- [Set MailboxGUID to null/User is stuck as MailUser and cant get mailbox](https://www.alitajran.com/hard-delete-mailbox-microsoft-365) -->

## Movebot

Everything useful I've found for Movebot migrations.

## PST import to EXO

Everything useful I've found for PST import to EXO migrations.  
[PST Import Guide from MS](https://learn.microsoft.com/da-dk/purview/importing-pst-files-to-office-365)

1. Add the Mailbox Import Export role to Organization Management role group, at least 24 hours before the import process.
2. Follow the above guide to create a PST import job.
3. Create the PST import CSV file.

### **AND FOR THE LOVE OF GOD AND ALL THAT IS HOLY, PLEASE DONT FORGET THE '/' IN THE TargetRootFolder PROPERTY IN THE CSV FILE** <!-- omit in TOC -->

```csv
Workload,FilePath,Name,Mailbox,IsArchive,TargetRootFolder,ContentCodePage,SPFileContainer,SPManifestContainer,SPSiteUrl
Exchange,,NameOfPST.pst,projekter@domain.dk,FALSE,/,,,,
```

If needed to import into a subfolder in the mailbox, add the subfolder name to the TargetRootFolder property.

```csv
Workload,FilePath,Name,Mailbox,IsArchive,TargetRootFolder,ContentCodePage,SPFileContainer,SPManifestContainer,SPSiteUrl
Exchange,,NameOfPST.pst,projekter@domain.dk,FALSE,FolderToImportTo,,,,
```

4. [Upload](https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-blobs-upload) the PST files to Azure blob storage.

```powershell
# For only folder contents add \* on the end of the path
# For uploading a full folder leave only the foldername on the end of the path, like E:\UploadFolder. Edit the FilePath in the CSV to your needs.
#  --recursive can be added if the PST files are in subfolders
azcopy copy 'E:\Batch1\*' 'https://b59aa7f2cf2e46b1bc82282.blob.core.windows.net/ingestiondata?skoid=IDSomeThingHere'
```

5. Finish the import job in the Purview portal, by validating the CSV file and creating the job.
6. Wait for the job to finish.
7. Press the "Import to M365" button and do the thing.

## ProfWiz

Everything useful I've found for ProfWiz migrations.

### Steps for migration to Entra ID

#### Pre-migration steps

1. Create the config files for the migration.
   1. Use the onmicrosoft.com domain for the config file.
   2. Create a ForensiTAzureID.xml file via the script that is found here. Save-AzureADUser.ps1 can be downloaded from: <https://github.com/ForensiT/PowerShell.>
   3. Create the provisioning file for the migration. Guide is found in the ProfWiz Corporate user guide too. This is the file that will be used to Entra join the machine.

#### Migration steps

1. Check if the computer is a Home edition. If it is, upgrade to Pro edition.
2. Make a local administrator account on the computer.
3. Suspend BitLocker on the computer.
4. If the browser is not synced, either sync it or create an export of the bookmarks and import them after the migration.
5. Copy the ProfWiz config files to the computer.
6. Log into the local administrator account.
7. **If using a provisioning package, skip to step 11.**
8. Remove the computer from the domain.
9. Reboot the computer.
10. Join the computer to the Azure AD/Entra domain.
11. Run the ProfWiz migration tool.
12. Log into the migrated account.
13. Import the bookmarks into the browser, if needed.
14. Make sure the computer is enrolled correctly in Intune via the Company portal.
15. Run the command "sfc /scannow" in an elevated command prompt.
16. Reboot the computer.
17. Enable BitLocker on the computer.
18. Reboot the computer.
19. Delete the local administrator account.
