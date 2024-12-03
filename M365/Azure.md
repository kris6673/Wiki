# Azure

## Table of Contents <!-- omit in toc -->

1. [Elevate Global admin to be able to manage all Azure subscriptions](#elevate-global-admin-to-be-able-to-manage-all-azure-subscriptions)

---

## Elevate Global admin to be able to manage all Azure subscriptions

Sometimes the button to elevate to be able to manage all subscriptions is greyed out. To fix this the az powershell module is needed.

If you don't have the Az module installed, run the following command to install it:

```powershell
Install-Module -Name Az
```

Then run the following command to elevate the global admin to be able to manage all subscriptions.

```powershell
# To make sure you are logged in to the correct tenant
az account clear
az login --allow-no-subscriptions

# Elevate the global admin
az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"
```

Log in and out of the Azure portal and the Global admin should now be able to manage all subscriptions.
