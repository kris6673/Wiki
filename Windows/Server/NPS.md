# NPS server

## NPS extension for Azure MFA

:warning: **CAUTION:** Installing the plugin takes over the entire NPS server and requires ALL NPS requests to it must go through Azure MFA. This behavior cannot be changed.

### Fallback to approve/deny without number matching

To setup fallback to approve/deny without number matching setup the following reg key on the NPS server:

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\AzureMfa
    String/REG_SZ: OVERRIDE_NUMBER_MATCHING_WITH_OTP
    Value: FALSE

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

## Troubleshooting

Go to the Event log and find the error codes.  
Check both the NPS and AzureMFA logs for errors.
Lookup the NPS extension error codes in the Microsoft docs [here](https://learn.microsoft.com/en-us/entra/identity/authentication/howto-mfa-nps-extension-errors)
