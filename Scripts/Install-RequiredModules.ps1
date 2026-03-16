# Checks if modules in the list is installed and install if it's not.
$Modules = @(
    'ExchangeOnlineManagement'
    # 'MSOnline'
    @{ Name = 'Microsoft.Graph'; RequiredVersion = '2.26.1' }  # pinned example
    'Microsoft.Graph.Beta'
    # 'AzureAD'
    'AIPService'
    'ImportExcel'
    'MicrosoftTeams'
    'PnP.PowerShell'
    'Microsoft.Online.SharePoint.PowerShell'
    'Microsoft.WinGet.Client'
    'Az'
    'PassPushPosh'
    'Microsoft.PowerShell.GraphicalTools'
    'F7History'
    'PSWriteHTML'
)

function Install-RequiredModules {
    <#
.SYNOPSIS
    Installs or updates required modules.

.DESCRIPTION
    This function installs or updates a list of modules specified by the user. It checks if the module is already installed and if it needs updates. 
    If the module is not installed, it installs it. If the module needs updates, it updates the module to the latest version and uninstalls any old versions.

.PARAMETER Modules
    Specifies an array of module names that need to be installed or updated.

.EXAMPLE
    Install-RequiredModules -Modules 'Module1', 'Module2', 'Module3'
    This example installs or updates the modules 'Module1', 'Module2', and 'Module3'.

.EXAMPLE 
    $Modules = @('Module1', 'Module2', 'Module3')
    Install-RequiredModules -Modules $Modules
    This example installs or updates the module 'Module1', 'Module2', and 'Module3' using an array.
    
.NOTES
    Author: Kris6673
    Date: 2024-06-28
#>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [object[]]$Modules
    )

    begin {
        # Ensure NuGet is available
        try {
            $null = Get-PackageProvider -Name 'NuGet' -Force -ErrorAction Stop
        } catch {
            Write-Verbose 'Installing NuGet package provider'
            $null = Install-PackageProvider -Name 'NuGet' -Force
        }

        # Trust PSGallery if needed
        if ((Get-PSRepository -Name 'PSGallery').InstallationPolicy -ne 'Trusted') {
            Write-Verbose 'Setting PSGallery as trusted repository'
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
        }
    }

    
    # Install all modules in input list and handle errors
    process {
        foreach ($Module in $Modules) {
            # Resolve name and optional required version from string or hashtable
            if ($Module -is [string]) {
                $ModuleName      = $Module
                $RequiredVersion = $null
            } else {
                $ModuleName      = $Module.Name
                $RequiredVersion = $Module.RequiredVersion  # $null if not supplied
            }

            if ($RequiredVersion) {
                # --- Pinned-version path ---
                $InstalledVersions = Get-InstalledModule -Name $ModuleName -AllVersions -ErrorAction SilentlyContinue
                $ExactMatch = $InstalledVersions | Where-Object { $_.Version -eq $RequiredVersion }

                if ($ExactMatch) {
                    Write-Host "$ModuleName $RequiredVersion is already installed." -ForegroundColor Green
                } else {
                    Write-Host "Installing $ModuleName at required version $RequiredVersion..." -ForegroundColor Yellow
                    try {
                        Install-Module -Name $ModuleName -RequiredVersion $RequiredVersion -Force -AllowClobber -ErrorAction Stop
                        Write-Host "Success. $ModuleName $RequiredVersion installed." -ForegroundColor Green

                        # Uninstall all other versions
                        $OtherVersions = Get-InstalledModule -Name $ModuleName -AllVersions -ErrorAction SilentlyContinue |
                            Where-Object { $_.Version -ne $RequiredVersion }
                        foreach ($OldVersion in $OtherVersions) {
                            try {
                                Uninstall-Module -Name $ModuleName -RequiredVersion $OldVersion.Version -Force -ErrorAction Stop
                                Write-Host "Uninstalled $ModuleName $($OldVersion.Version)." -ForegroundColor Green
                            } catch {
                                Write-Host "ERROR: Could not uninstall $ModuleName $($OldVersion.Version). Run manually: Uninstall-Module $ModuleName -RequiredVersion $($OldVersion.Version)" -ForegroundColor Red
                            }
                        }
                    } catch {
                        Write-Host "Could not install $ModuleName $RequiredVersion. Please install manually: Install-Module $ModuleName -RequiredVersion $RequiredVersion" -ForegroundColor Red
                    }
                }
            } else {
                # --- Update-to-latest path (existing behavior) ---
                $InstalledModule = Get-InstalledModule -Name $ModuleName -ErrorAction SilentlyContinue
                if ($InstalledModule) {
                    Write-Host "$ModuleName module already installed. Testing if it needs updates." -ForegroundColor Yellow
                    # Test if module needs updates
                    $OnlineModule = Find-Module -Name $ModuleName -Repository PSGallery
                    if ([version]$OnlineModule.version -gt [version]$InstalledModule.Version) {
                        Write-Host "$ModuleName module needs to be updated from version $($InstalledModule.Version) to version $($OnlineModule.Version)." -ForegroundColor Yellow

                        # Update module and alert the user if it fails.
                        try {
                            Write-Host "Updating $ModuleName module. Please wait, this could take a while." -ForegroundColor Yellow
                            Update-Module -Name $ModuleName -Force -ErrorAction Stop
                            Write-Host "Success. $ModuleName module was updated." -ForegroundColor Green

                            # Try uninstalling old module
                            $OldVersions = Get-InstalledModule -Name $ModuleName -AllVersions -ErrorAction Stop | Where-Object { $_.Version -ne $OnlineModule.Version }
                            Write-Host "Uninstalling old versions of $ModuleName." -ForegroundColor Yellow
                            foreach ($OldVersion in $OldVersions) {
                                try {
                                    Uninstall-Module $ModuleName -RequiredVersion $OldVersion.Version -Force -ErrorAction Stop
                                    Write-Host "Success. Old version $($OldVersion.Version) of $ModuleName uninstalled." -ForegroundColor Green
                                } catch {
                                    Write-Host "ERROR. Old version $($InstalledModule.Version) of $ModuleName was not uninstalled." -ForegroundColor Red
                                    Write-Host "Please uninstall the module manually with: Uninstall-Module $ModuleName -RequiredVersion $($InstalledModule.Version)"
                                }
                            }
                        } # Catch if update fails
                        catch {
                            Write-Host "Could not update $ModuleName. Please update it manually with: Update-Module $ModuleName" -ForegroundColor Red
                        }
                    } else {
                        Write-Host "$ModuleName module is up to date. Moving on." -ForegroundColor Green
                    }
                } else {
                    Write-Host "$ModuleName module is not installed. Installing module..." -ForegroundColor Yellow
                    try {
                        Install-Module $ModuleName -Force -AllowClobber -ErrorAction Stop
                        Write-Host "$ModuleName successfully installed." -ForegroundColor Green
                    } catch {
                        Write-Host "Could not install $ModuleName. Please install it manually with: Install-Module $ModuleName and rerun the script." -ForegroundColor Red
                        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                        exit
                    }
                }
            }
        }
    }
}
Install-RequiredModules -Modules $Modules