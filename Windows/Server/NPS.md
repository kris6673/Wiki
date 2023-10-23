# NPS server

## NPS extension

To setup fallback to approve/deny without numbermatching setup the following reg key

    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\AzureMfa
    String/REG_SZ: OVERRIDE_NUMBER_MATCHING_WITH_OTP
    Value: FALSE

[Source](https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-mfa-number-match#nps-extension)
