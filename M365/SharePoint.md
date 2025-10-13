# SharePoint

## Table of Contents <!-- omit in toc -->

1. [Enable automatic versioning for all SharePoint sites](#enable-automatic-versioning-for-all-sharepoint-sites)
   1. [Run a trim to remove old versions](#run-a-trim-to-remove-old-versions)

## Enable automatic versioning for all SharePoint sites

By default, version history on tenants is set to 500 versions and never expires.
This will take up a lot of space over time. Therefore, automatic management of version history is recommended.  
[Microsoft guide](https://learn.microsoft.com/en-us/sharepoint/site-version-limits#manage-version-history-limits-for-a-site-using-powershell)

```powershell
# Install the SharePoint Online Management Shell if you haven't already
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser

# If you're using PowerShell Core. (Please just use PowerShell 5.1 if you can, this module hates PowerShell Core)
Import-Module Microsoft.Online.SharePoint.PowerShell -UseWindowsPowerShell

# Tenant wide for new sites
Connect-SPOService -Url https://contoso-admin.sharepoint.com
Get-SPOTenant | select EnableAutoExpirationVersionTrim, ExpireVersionsAfterDays,MajorVersionLimit
Set-SPOTenant -EnableAutoExpirationVersionTrim $true

# For existing sites
Connect-SPOService -Url https://contoso-admin.sharepoint.com

# Show all sites with versioning
Get-SPOSite -Limit ALL | Select-Object Url, EnableAutoExpirationVersionTrim, ExpireVersionsAfterDays, MajorVersionLimit | Out-Gridview

# Enable automatic versioning on all sites
# The setting for existing document libraries may take 24 hours to take effect. Please run Get-SPOSiteVersionPolicyJobProgress to check
# the progress. The setting for existing libraries does not trim existing versions to meet the newly set limits
$Sites = Get-SPOSite -Limit ALL
$Counter = 0
$TotalSites = $Sites.Count
foreach ($Site in $Sites) {
    $Counter++
    Write-Progress -Activity 'Processing Sites' -Status "Processing Site $Counter of $TotalSites" -PercentComplete ($Counter / $TotalSites * 100)
    if ($Site | Where-Object { $_.EnableAutoExpirationVersionTrim -ne $true -and $_.LockState -eq 'Unlock' }) { } else { continue }
    Set-SPOSite -Identity $Site.Url -EnableAutoExpirationVersionTrim $true -Confirm:$false
}

# Check the progress of the version policy job
Get-SPOSite -Limit ALL | Where-Object {$_.EnableAutoExpirationVersionTrim -eq $true -and $_.LockState -eq 'Unlock'} | Get-SPOSiteVersionPolicyJobProgress | Out-Gridview
```

### Run a trim to remove old versions

Only run this after enabling automatic versioning, and wait for the setting to be applied to all sites.

```powershell

Connect-SPOService -Url https://contoso-admin.sharepoint.com


$AllSites = Get-SPOSite -Limit ALL | Where-Object {$_.EnableAutoExpirationVersionTrim -eq $true -and $_.LockState -eq 'Unlock'}
# Goes through every SharePoint Site to start trimjob
$Counter = 0
$TotalSites = $AllSites.Count
foreach ($site in $AllSites) {
    $Counter++
    Write-Progress -Activity 'Processing Sites' -Status "Processing Site $Counter of $TotalSites" -PercentComplete ($Counter / $TotalSites * 100)
    $SiteUrl = $site.Url
    $Sitename = $site.Title
    try {
        Write-host "Starting trimjob on: $SiteUrl" -ForegroundColor Cyan
        New-SPOSiteFileVersionBatchDeleteJob -Identity $SiteUrl -Automatic -Confirm:$false
        Write-host "Trimjob has begun for $SiteUrl | It can take days before the trimjob completes" -ForegroundColor Green
    } catch {
        Write-host "Could not start trimjob for: $SiteUrl. Error: $_" -ForegroundColor Red
    }
}

# Check the progress of the trimjob

$SiteProgress = Get-SPOSite -Limit ALL | Where-Object {$_.EnableAutoExpirationVersionTrim -eq $true -and $_.LockState -eq 'Unlock'} | Get-SPOSiteFileVersionBatchDeleteJobProgress
$SiteProgress | Out-Gridview
```
