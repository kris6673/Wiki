# Checks if modules in the list is installed and install if it's not.
$Modules = @(
    'ExchangeOnlineManagement',
    'MSOnline',
    'Microsoft.Graph',
    'Microsoft.Graph.Beta',
    'AzureAD',
    'AIPService',
    'ImportExcel',
    'MicrosoftTeams',
    'PnP.PowerShell',
    'Microsoft.Online.SharePoint.PowerShell',
    'Microsoft.WinGet.Client'
)
function Install-RequiredModules {
    param (
        [parameter(Mandatory = $true)][System.Array]$Modules
    )
    # Set PSGallery to trusted
    if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -eq 'Trusted') {
        Write-Host 'PSGallery already trusted'
    } else {
        Write-Host 'PSGallery not trusted, setting it to trusted. Please wait...' -ForegroundColor Yellow
        Write-Host 'Trusting PS Gallery' -ForegroundColor Yellow
        $null = Install-PackageProvider -Name 'NuGet' -Force
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    }

    $null = Install-PackageProvider -Name 'NuGet' -Force
    # Install all modules in input list and handle errors
    foreach ($Module in $Modules) {
        $InstalledModule = Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue
        if ($InstalledModule) {
            Write-Host "$Module module already installed. Testing if it needs updates." -ForegroundColor Yellow
            # Test if module needs updates
            $OnlineModule = Find-Module -Name $Module -Repository PSGallery
            if ($OnlineModule.version -gt $InstalledModule.Version) {
                Write-Host "$Module module needs to be updated from version $($InstalledModule.Version) to version $($OnlineModule.Version)." -ForegroundColor Yellow
                
                # Update module and alert the user if it fails.
                try {
                    Write-Host "Updating $Module module. Please wait, this could take a while." -ForegroundColor Yellow
                    Update-Module -Name $Module -Force -ErrorAction Stop
                    Write-Host "Success. $Module module was updated." -ForegroundColor Green
                    
                    # Try uninstalling old module
                    $OldVersions = Get-InstalledModule -Name $Module -AllVersions -ErrorAction Stop | Where-Object { $_.Version -ne $OnlineModule.Version }
                    Write-Host "Uninstalling old versions of $Module." -ForegroundColor Yellow
                    foreach ($OldVersion in $OldVersions) {
                        try {
                            Uninstall-Module $Module -RequiredVersion $OldVersion.Version -Force -ErrorAction Stop
                            Write-Host "Success. Old version $($OldVersion.Version) of $Module uninstalled." -ForegroundColor Green
                        } catch {
                            Write-Host "ERROR. Old version $($InstalledModule.Version) of $Module was not uninstalled." -ForegroundColor Red
                            Write-Host "Please uninstall the module manually with: Uninstall-Module $Module -RequiredVersion $($InstalledModule.Version)"
                        }
                    }
                } # Catch if update fails
                catch {
                    Write-Host "Could not update $Module. Please update it manually with: Update-Module $Module" -ForegroundColor Red
                }
            } else {
                Write-Host "$Module module is up to date. Moving on." -ForegroundColor Green
            }
        } else {
            Write-Host "$Module module is not installed. Installing module..." -ForegroundColor Yellow
            try {
                Install-Module $Module -ErrorAction Stop
                Write-Host "$Module sucessfully installed." -ForegroundColor Green
            } catch {
                Write-Host "Could not install $Module. Please install it manually with: Install-Module $Module and rerun the script." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                Exit
            }
        }
    }
}
Install-RequiredModules -Modules $Modules