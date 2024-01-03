# Exclaimer - Email Signature Management

## Table of Contents <!-- omit in toc -->

1. [Recommended setup](#recommended-setup)
2. [Server side](#server-side)
3. [Client side](#client-side)
   1. [Add-in for Outlook](#add-in-for-outlook)
   2. [Exclaimer Signature Manager Outlook Edition](#exclaimer-signature-manager-outlook-edition)
   3. [Custom fonts in signatures](#custom-fonts-in-signatures)
4. [Troubleshooting](#troubleshooting)

## Recommended setup

- Cloud and server side signatures enabled.
- Signatures controlled via AD synced signature groups.
- Add-in for outlook deployed via dynamic group in Entra ID or synced signature groups.
- Set sync details to "All users"
- Enable "Sent items update".

## Server side

**NOTE:** Remember to update the customers SPF record to include Exclaimer, if you are using server side. [See this guide](https://support.exclaimer.com/hc/en-gb/articles/4404775962641-How-to-update-the-Sender-Policy-Framework-SPF) for how to do it. Otherwise email flow will very likely break/be disrupted.

The most used SPF record is this one:

```html
include:spf.EU.exclaimer.net
```

## Client side

### Add-in for Outlook

---

[Deployment guide from exclaimer](https://support.exclaimer.com/hc/en-gb/articles/360020741398-Install-Exclaimer-Cloud-Outlook-Add-in-Public-channel)

**TL;DR:** "I dont wanna read the guide, just tell me what to do"

1. Open the admin centre as the customer.
2. Go to Settings -> Integrated apps and find "Exclaimer Cloud for Outlook"
3. Deploy to desired signature groups. See the note below.
4. Press next and accept the permissions until the wizard is done.
5. Wait up to 8 hours for the add-in to be deployed to the users.

**NOTE:** Deployment/Integrated apps in M365, cannot use nested groups. So, a separate dynamic group needs to be created in Entra ID, which looks at the members of the signature groups, and this is used to deploy the add-in

### Exclaimer Signature Manager Outlook Edition

---

[Documentation](https://support.exclaimer.com/hc/en-gb/articles/7238574049437-Exclaimer-Cloud-Signature-Update-Agent)

**NOTE:** This install type does not support server side and client side signatures at the same time. You have to choose one or the other. Deploy the add-in instead if you want both.

This is because the check/test to see if the signature has already been applied, does not work correctly when it gets to the server side, and you end up with double signatures.

### Custom fonts in signatures

You do this by either uploading a font file to Exclaimer, or by using a font stack/Font fallback. [See this guide](https://support.exclaimer.com/hc/en-gb/articles/4587213492637-How-to-use-custom-fonts-without-rendering-as-bitmaps-) for more info.  
**Example:** Adding the Aptos font to the signature, uses a font stack that could look like this:

```html
Aptos, Calibri, Candara, Segoe, Segoe UI, Optima, Arial, sans-serif
```

This font stack is added to the Font Family field in the signature editor, and causes it to try the first font in the list, and if it is not available, it tries the next one, and so on.

## Troubleshooting

Nothing here yet.
