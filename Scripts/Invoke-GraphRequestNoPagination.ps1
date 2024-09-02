function Invoke-GraphRequestNoPagination {
    <#
    .SYNOPSIS
    Invokes a Microsoft Graph request and retrieves all pages of data.
    Converts the result to a PSCustomObject with type casting.

    .DESCRIPTION
    The Invoke-GraphRequestNoPagination function is used to invoke a Microsoft Graph request and retrieve all pages of data. 
    It takes a mandatory parameter, $Uri, which specifies the URI of the Graph request.

    .PARAMETER Uri
    Specifies the URI of the Microsoft Graph request.

    .EXAMPLE
    $result = Invoke-GraphRequestNoPagination -Uri "https://graph.microsoft.com/v1.0/users"
    $result | Select-Object -Property displayName, mail
    .NOTES
    Author: Kris6673
    Date:   2024-03-12
    #>
    param (
        [Parameter(Mandatory = $true)][string]$Uri
    )
    $AllPages = @()
    $GraphRequest = (Invoke-MgGraphRequest -Method Get -Uri $Uri)
    $AllPages += $GraphRequest.value
    if ($GraphRequest.'@odata.nextLink') {

        do {
            $GraphRequest = (Invoke-MgGraphRequest -Method Get -Uri $GraphRequest.'@odata.nextLink')
            Write-Verbose "Getting next page of users. Count: $($AllPages.Count)"
            $AllPages += $GraphRequest.value
        } until (
            $null -eq $GraphRequest.'@odata.nextLink'
        )
    }
    $AllPages = foreach ($Page in $AllPages) {
        [PsCustomObject]$Page
    }
    Return $AllPages
}
