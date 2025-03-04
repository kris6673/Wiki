# SharePoint

## Table of Contents <!-- omit in toc -->

1. [Enable automatic versioning for all SharePoint sites](#enable-automatic-versioning-for-all-sharepoint-sites)
   1. [Run a trim to remove old versions](#run-a-trim-to-remove-old-versions)

## Enable automatic versioning for all SharePoint sites

By default, version history on tenants is set to 500 versions and never expires.
This will take up a lot of space over time. Therefore, automatic management of version history is recommended.  
[Microsoft guide](https://learn.microsoft.com/en-us/sharepoint/site-version-limits#manage-version-history-limits-for-a-site-using-powershell)

```powershell
# Tenant wide for new sites
Connect-SPOService -Url https://contoso-admin.sharepoint.com
Get-SPOTenant | select EnableAutoExpirationVersionTrim, ExpireVersionsAfterDays,MajorVersionLimit
Set-SPOTenant -EnableAutoExpirationVersionTrim $true

# For existing sites
Connect-SPOService -Url https://contoso-admin.sharepoint.com

# Show all sites with versioning
Get-SPOSite | Select-Object Url, EnableAutoExpirationVersionTrim, ExpireVersionsAfterDays, MajorVersionLimit | Out-Gridview

# Enable automatic versioning on all sites
# The setting for existing document libraries may take 24 hours to take effect. Please run Get-SPOSiteVersionPolicyJobProgress to check
# the progress. The setting for existing libraries does not trim existing versions to meet the newly set limits
Get-SPOSite | Where-Object -Property EnableAutoExpirationVersionTrim -ne $true | Set-SPOSite -EnableAutoExpirationVersionTrim $true -Verbose
```

### Run a trim to remove old versions

Only run this after enabling automatic versioning, and wait for the setting to be applied to all sites.

```powershell

Connect-SPOService -Url https://contoso-admin.sharepoint.com


$AllSites = Get-SPOSite | Where-Object -Property EnableAutoExpirationVersionTrim -eq $true
# Goes through every SharePoint Site to start trimjob
foreach ($site in $AllSites) {
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

$SiteProgress = Get-SPOSite | Get-SPOSiteFileVersionBatchDeleteJobProgress
$SiteProgress | Out-Gridview
```
