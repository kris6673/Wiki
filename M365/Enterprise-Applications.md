# App registrations / Enterprise applications

## Table of Contents <!-- omit in toc -->

1. [Grant tenant-wide admin consent to an application](#grant-tenant-wide-admin-consent-to-an-application)
   1. [Commonly used application ID's](#commonly-used-application-ids)

## Grant tenant-wide admin consent to an application

[Docs](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent?pivots=portal)

Fill out the blanks: `https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={application-id}`

### Commonly used application ID's

| Application                    | Application ID                       | Description                         |
| ------------------------------ | ------------------------------------ | ----------------------------------- |
| Apple Internet Accounts        | f8d98a96-0999-43f5-8af3-69971c7bb423 | Apple Mail / iOS accounts           |
| Gmail                          | 2cee05de-2b8f-45a2-8289-2a06ca32c4c8 |                                     |
| Samsung Email                  | 8acd33ea-7197-4a96-bc33-d7cc7101262f |                                     |
| Email                          | e0ee12cb-2032-40fc-a44f-d6d9f3fad1eb | Android default mail app            |
| Miralix Sign-in                | 2d7bb325-1664-4951-9d37-188ad4d4bf9c | SSO app for Miralix phone platform  |
| Exclaimer Cloud Single Sign-On | c94a8380-d458-4869-84c3-33bef46a49de | SSO app for Exclaimer mail platform |
