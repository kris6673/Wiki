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
    Installs or updates required modules with scope-aware install and cross-scope cleanup.

.DESCRIPTION
    Installs or updates a list of modules. When running elevated, installs to AllUsers and
    removes stale CurrentUser copies (falling back to CurrentUser if the AllUsers install
    fails). When running non-elevated, installs to CurrentUser and shadows outdated AllUsers
    copies without touching them. Accepts either module name strings or hashtables of the
    form @{ Name = 'X'; RequiredVersion = '1.2.3' }.

.PARAMETER Modules
    An array of module names (strings) or @{ Name; RequiredVersion } hashtables.

.EXAMPLE
    Install-RequiredModules -Modules 'Module1', 'Module2', 'Module3'

.EXAMPLE
    $Modules = @('Module1', @{ Name = 'Module2'; RequiredVersion = '1.2.3' })
    Install-RequiredModules -Modules $Modules

.NOTES
    Author: Kris6673
    Date: 2026-04-23
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

        $script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        $script:AllUsersPrefixes = @(
            (Join-Path $env:ProgramFiles 'PowerShell\Modules'),
            (Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules')
        )

        function Get-ModuleScope {
            param([string]$ModuleBase)
            foreach ($p in $script:AllUsersPrefixes) {
                if ($ModuleBase -like "$p*") { return 'AllUsers' }
            }
            return 'CurrentUser'
        }

        function Get-ModuleInstallations {
            param([string]$Name)
            Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue | ForEach-Object {
                [pscustomobject]@{
                    Name       = $_.Name
                    Version    = $_.Version
                    ModuleBase = $_.ModuleBase
                    Scope      = Get-ModuleScope $_.ModuleBase
                }
            } | Sort-Object Version -Descending
        }

        function Remove-ModuleInstallation {
            param(
                [string]$Name,
                [version]$Version,
                [string]$ModuleBase
            )
            # Uninstall-Module may target the wrong scope when copies exist in both, so verify
            # the specific ModuleBase is gone afterwards and delete it directly if not.
            try { Uninstall-Module -Name $Name -RequiredVersion $Version -Force -ErrorAction Stop } catch {}
            if (Test-Path -LiteralPath $ModuleBase) {
                Remove-Item -LiteralPath $ModuleBase -Recurse -Force -ErrorAction Stop
            }
        }

        function Install-ToScope {
            param(
                [string]$Name,
                [version]$RequiredVersion,
                [ValidateSet('AllUsers', 'CurrentUser')][string]$Scope
            )
            $params = @{
                Name         = $Name
                Scope        = $Scope
                Force        = $true
                AllowClobber = $true
                ErrorAction  = 'Stop'
            }
            if ($RequiredVersion) { $params.RequiredVersion = $RequiredVersion }
            Install-Module @params
        }
    }

    process {
        foreach ($Module in $Modules) {
            # Resolve name and optional required version from string or hashtable
            if ($Module -is [string]) {
                $ModuleName      = $Module
                $RequiredVersion = $null
            } else {
                $ModuleName      = $Module.Name
                $RequiredVersion = $Module.RequiredVersion
            }

            # Determine target version
            try {
                if ($RequiredVersion) {
                    $Target = [version]$RequiredVersion
                } else {
                    $Online = Find-Module -Name $ModuleName -Repository PSGallery -ErrorAction Stop
                    $Target = [version]$Online.Version
                }
            } catch {
                Write-Host "Could not determine target version for ${ModuleName}: $_" -ForegroundColor Red
                continue
            }

            $Installs = Get-ModuleInstallations -Name $ModuleName
            $AU       = @($Installs | Where-Object Scope -EQ 'AllUsers')
            $CU       = @($Installs | Where-Object Scope -EQ 'CurrentUser')
            $AuTarget = $AU | Where-Object Version -EQ $Target | Select-Object -First 1
            $CuTarget = $CU | Where-Object Version -EQ $Target | Select-Object -First 1

            if ($script:IsAdmin) {
                # Admin path: prefer AllUsers at $Target, fall back to CurrentUser on failure.
                if ($AuTarget) {
                    Write-Host "$ModuleName $Target is already installed (AllUsers)." -ForegroundColor Green
                    $InstalledScope = 'AllUsers'
                } else {
                    Write-Host "Installing $ModuleName $Target to AllUsers..." -ForegroundColor Yellow
                    try {
                        Install-ToScope -Name $ModuleName -RequiredVersion $Target -Scope AllUsers
                        Write-Host "Success. $ModuleName $Target installed (AllUsers)." -ForegroundColor Green
                        $InstalledScope = 'AllUsers'
                    } catch {
                        Write-Host "AllUsers install of $ModuleName $Target failed: $_" -ForegroundColor Red
                        Write-Host "Falling back to CurrentUser scope..." -ForegroundColor Yellow
                        try {
                            Install-ToScope -Name $ModuleName -RequiredVersion $Target -Scope CurrentUser
                            Write-Host "Success. $ModuleName $Target installed (CurrentUser fallback)." -ForegroundColor Green
                            $InstalledScope = 'CurrentUser'
                        } catch {
                            Write-Host "CurrentUser fallback also failed for ${ModuleName}: $_" -ForegroundColor Red
                            Write-Host "Install $ModuleName manually and rerun the script." -ForegroundColor Red
                            continue
                        }
                    }
                }

                # Refresh inventory after any install.
                $Installs = Get-ModuleInstallations -Name $ModuleName
                $AU = @($Installs | Where-Object Scope -EQ 'AllUsers')
                $CU = @($Installs | Where-Object Scope -EQ 'CurrentUser')

                if ($InstalledScope -eq 'AllUsers') {
                    # Remove every AU copy != target, and every CU copy (redundant now).
                    foreach ($copy in ($AU | Where-Object Version -NE $Target)) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed AllUsers $ModuleName $($copy.Version)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove AllUsers $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                    foreach ($copy in $CU) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed CurrentUser $ModuleName $($copy.Version) (superseded by AllUsers)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove CurrentUser $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                } else {
                    # Fallback landed in CU; only clean our own scope.
                    foreach ($copy in ($CU | Where-Object Version -NE $Target)) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed CurrentUser $ModuleName $($copy.Version)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove CurrentUser $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                }
            } else {
                # Non-admin path: install to CurrentUser, never touch AllUsers.
                if ($AuTarget) {
                    Write-Host "$ModuleName $Target is already installed (AllUsers). Leaving AllUsers alone." -ForegroundColor Green
                    foreach ($copy in $CU) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed CurrentUser $ModuleName $($copy.Version) (shadowed by AllUsers)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove CurrentUser $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                } elseif ($CuTarget) {
                    Write-Host "$ModuleName $Target is already installed (CurrentUser)." -ForegroundColor Green
                    foreach ($copy in ($CU | Where-Object Version -NE $Target)) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed CurrentUser $ModuleName $($copy.Version)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove CurrentUser $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "Installing $ModuleName $Target to CurrentUser..." -ForegroundColor Yellow
                    try {
                        Install-ToScope -Name $ModuleName -RequiredVersion $Target -Scope CurrentUser
                        Write-Host "Success. $ModuleName $Target installed (CurrentUser)." -ForegroundColor Green
                    } catch {
                        Write-Host "Could not install ${ModuleName}: $_" -ForegroundColor Red
                        Write-Host "Install manually with: Install-Module $ModuleName -Scope CurrentUser" -ForegroundColor Red
                        # Hard-stop only when no working copy exists anywhere.
                        if (-not ($AU -or $CU)) {
                            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                            exit
                        }
                        continue
                    }
                    $CU = @((Get-ModuleInstallations -Name $ModuleName) | Where-Object Scope -EQ 'CurrentUser')
                    foreach ($copy in ($CU | Where-Object Version -NE $Target)) {
                        try {
                            Remove-ModuleInstallation -Name $ModuleName -Version $copy.Version -ModuleBase $copy.ModuleBase
                            Write-Host "Removed CurrentUser $ModuleName $($copy.Version)." -ForegroundColor Green
                        } catch {
                            Write-Host "Could not remove CurrentUser $ModuleName $($copy.Version) at $($copy.ModuleBase): $_" -ForegroundColor Red
                        }
                    }
                }
            }
        }
    }
}
Install-RequiredModules -Modules $Modules
