# Microsoft Entra Password Protection on-premises

## Table of Contents <!-- omit in toc -->

1. [Overview](#overview)
2. [Pre-requisites](#pre-requisites)
3. [Installation](#installation)
4. [Testing](#testing)
5. [FAQ / Troubleshooting](#faq--troubleshooting)
6. [Links](#links)

## Overview

Normally there is no way to enforce a banned password list on-premises, but with the Entra Password Protection on-premises agent, you can.
Passwords are evaluated against a custom per-tenant banned word list, the common banned word list from Microsoft and using the Entra identity engine.
In other words, most of the same checks that are done in Azure AD are now also done on-premises.

## Pre-requisites

- Windows Server 2012 R2 or newer
- Firewall enabled on the server
- .NET Framework 4.7.2 or newer
- DFSR used for SYSVOL replication
- Global admin to the Entra tenant
- Outbound internet access from the server on port 80 and 443

## Installation

The installation is split into two parts. A proxy agent and a DC agent. The proxy agent only needs to be installed on a member server, and the DC agent needs to be installed on all DC's.  
Microsoft recommends that to ensure high availability, you install the proxy agent on two servers and not on DC's. Installing the proxy agent on DC's is not supported for production and only for testing.

The installation steps are as follows:

1. Check if prerequisites are met
2. Download the agent from the [Microsoft download center](https://www.microsoft.com/en-us/download/details.aspx?id=57071)
3. Install the proxy agent on a member server
   1. Can be installed quietly with the following command: .\AzureADPasswordProtectionProxySetup.exe /quiet
4. Test if installation is successful

   - ```powershell
      Import-Module AzureADPasswordProtection
      Get-Service AzureADPasswordProtectionProxy | fl
     ```

5. Register and test the proxy agent with the tenant

   - ```powershell
        $GlobalAdmin = 'yourglobaladmin@yourtenant.onmicrosoft.com'
        Register-AzureADPasswordProtectionProxy -AccountUpn $GlobalAdmin
        Test-AzureADPasswordProtectionProxyHealth -TestAll

        Register-AzureADPasswordProtectionForest -AccountUpn $GlobalAdmin
        Test-AzureADPasswordProtectionProxyHealth -TestAll

     ```

6. Install the DC agent on all DC's. **Note:** This requires a reboot
   - Can be installed quietly with the following command: msiexec.exe /i AzureADPasswordProtectionDCAgentSetup.msi /quiet /qn /norestart
7. Test if installation is successful

   - ```powershell
      Test-AzureADPasswordProtectionDCAgentHealth -TestAll
     ```

## Testing

Change a password on a user using only words from the banned word list, and see if it gets blocked.
You can see the blocked password in the event log on the DC where the password change was made.

## FAQ / Troubleshooting

- "It only works some of the time. What is going on?"
  - You probably didn't install the agent on all your DC's. If the password change didn't hit the DC with the installed agent, there will be no way of blocking banned words.
- "What if the proxy agent server is down?"
  - Even if all registered proxy servers become unavailable, the Microsoft Entra Password Protection DC agents continue to enforce their cached password policy
- "My password contained words that was banned, but it still got through. What is going on?"
  - See the following explanation from Microsoft: [How are passwords evaluated](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad#score-calculation)

## Links

- [Microsoft guide](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-password-ban-bad-on-premises-deploy)
- [How passwords are evaluated/Score calculation](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-password-ban-bad#how-are-passwords-evaluated)
- [Download link for the agents](https://www.microsoft.com/en-us/download/details.aspx?id=57071)
- [Trouble shooting page from Microsoft](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-password-ban-bad-on-premises-troubleshoot)
