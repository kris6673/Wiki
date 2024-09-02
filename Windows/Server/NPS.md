# NPS server

## NPS extension for Azure MFA

:warning: **CAUTION:** Installing the plugin takes over the entire NPS server and requires ALL NPS requests to it must go through Azure MFA. This behavior cannot be changed.

:x::x: **ATTENTION:** :x::x: If using a firewall that requires RADIUS attributes to be set, to grant access to the VPN, any text based MFA methods (SMS, mobile app verification code, or OATH hardware token), will not work. If using a text based MFA method, any RADIUS attributes set in the Network Access Policy are not forwarded. Any RADIUS attributes set in the Connection Request Policy will be passed correctly. [See the purple note box for the full explanation](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-nps-extension#determine-which-authentication-methods-your-users-can-use)  
As a workaround you can use the [Approve/Deny push notifications](#fallback-to-approvedeny-without-number-matching) via the MS Authenticator app.

[Microsoft install guide](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-nps-extension#install-the-nps-extension)

1. Ensure the server has Powershell 5.1 or later installed

   1. Open powershell as admin and run the following command:

      ```powershell
      $PSVersionTable.PSVersion
      ```

   2. If the version is lower than 5.1, download and install the appropriate version from the [Microsoft download center](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

2. Download the NPS extension from the [Microsoft download center](https://www.microsoft.com/en-us/download/details.aspx?id=54688)
3. Install the NPS extension on the NPS server
4. Find the tenant ID in the Entra admin portal and note it down
5. Open powershell as admin and configure the NPS extension by running the following commands:

   ```powershell
   # Open powershell as admin and configure the NPS extension
   cd "C:\Program Files\Microsoft\AzureMfa\Config"
   .\AzureMfaNpsExtnConfigSetup.ps1
   ```

6. **Optional:** Setup approved/deny without number matching by setting the following [reg key](#fallback-to-approvedeny-without-number-matching) on the NPS server

```powershell
New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\AzureMfa" -Name "OVERRIDE_NUMBER_MATCHING_WITH_OTP" -Value "FALSE" -PropertyType String -Force
Restart-Service IAS
```

### Fallback to approve/deny without number matching

To setup fallback to approve/deny without number matching setup the following reg key on the NPS server:

```vb
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\AzureMfa
String/REG_SZ: OVERRIDE_NUMBER_MATCHING_WITH_OTP
Value: FALSE
```

[MS docs/source](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-mfa-number-match#nps-extension)

### VPN - Cisco Anyconnect

The VPN NPS server should be its own dedicated server that can only be used for VPN authentication.
The following Authentication methods can be used:

1. SMS
2. OTP from the Microsoft Authenticator app, if enabled in the Authentication methods in the Entra ID admin portal
3. Approve/Deny push notifications, if the following [reg key](#fallback-to-approvedeny-without-number-matching) is set on the NPS server.

### RDP / RDS Gateway

Can be set up to be used instead of an SMS passcode.  
However, this requires that the primary configured method is one you 'wait' for. In other words, it should be a phone call or a [push notification](#fallback-to-approvedeny-without-number-matching)

:no_entry: **Note:** Do not put the RDP NPS server on the RD gateway server. This will cause the authentication to fail, since the localhost and network protocols are different in the RD gateway.

### Renew the certificate

The certificate used for the NPS extension will expire after 2 years. To renew the certificate, follow the steps below:

```powershell
# Open powershell as admin, and follow the steps.
# Since its a renewal the tenant ID is already known, so no need to find it again.
cd "C:\Program Files\Microsoft\AzureMfa\Config"
.\AzureMfaNpsExtnConfigSetup.ps1
```

## Troubleshooting

Go to the Event log and find the error codes.  
Check both the NPS and AzureMFA logs for errors.
Lookup the NPS extension error codes in the Microsoft docs [here](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-nps-extension-errors)
