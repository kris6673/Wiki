function ConvertTo-DkWhoisKey {
    <#
.SYNOPSIS
    Internal helper: turns a WHOIS field label like "Registration period" or "ID status"
    into a PascalCase property name ("RegistrationPeriod", "IDStatus").
#>
    param ([parameter(Mandatory = $true)] [string]$Label)
    ($Label -split '\s+' | ForEach-Object {
        if ($_ -cmatch '^[A-Z0-9]+$') { $_ } else { $_.Substring(0, 1).ToUpper() + $_.Substring(1).ToLower() }
    }) -join ''
}

function Get-DkWhois {
    <#
.SYNOPSIS
    Looks up a .dk domain via the public WHOIS protocol and returns the full record as an object.

.DESCRIPTION
    Queries whois.punktum.dk on port 43 (the classic WHOIS protocol, RFC 3912) with
    --show-handles (includes registrant details) and --charset=utf-8, then parses the plain-text
    response into a PSCustomObject: top-level fields (Domain, Registered, Expires, Registrar,
    Status, ...) become properties, a labelled block like "Registrant" becomes a nested object,
    and a block with only one repeated field, like "Nameservers" (repeated "Hostname:" lines),
    becomes a plain string array.
    Internationalized domains (e.g. "æøå.dk") are converted to punycode ("xn--5cab8c.dk")
    before querying, since that's the ASCII form the WHOIS service expects.
    Returns $null if the domain doesn't exist or the query fails/times out.

    Punktum dk (formerly DK Hostmaster) also offers a WHOIS REST API
    (https://github.com/Punktum-dk/whois-rest-service-specification) that returns clean JSON,
    but it requires registrars to be whitelisted (see "Technical services" on punktum.dk) - the
    plain WHOIS protocol used here is the one explicitly documented as open to the public with
    no integration/whitelisting needed.
    RDAP (the modern HTTP/JSON WHOIS successor) is not an option either - .dk has no RDAP server
    registered in IANA's bootstrap (data.iana.org/rdap/dns.json).

.PARAMETER Domain
    The .dk domain name to look up, e.g. "example.dk".

.OUTPUTS
    PSCustomObject, or $null if the domain isn't found / the query failed.

.EXAMPLE
    Get-DkWhois -Domain "google.dk"

    Domain             : google.dk
    Registered         : 1999-01-10
    Expires            : 2027-03-31
    Registrar          : MarkMonitor Inc.
    RegistrationPeriod : 1 year
    VID                : no
    DNSSEC             : Unsigned delegation
    Status             : Active
    Registrant         : @{Handle=DATA REDACTED; Name=Google LLC; Address=...; City=Mountain View; Country=US; ...}
    Nameservers        : {ns1.google.com, ns2.google.com, ns3.google.com, ns4.google.com}

.EXAMPLE
    (Get-DkWhois "google.dk").Registrar
    Returns just the registrar name, e.g. "MarkMonitor Inc." (empty/absent if registrant-managed).

.EXAMPLE
    Get-DkWhois "æøå.dk"
    Converts to punycode internally and returns the record for xn--5cab8c.dk.

.EXAMPLE
    Import-Excel report.xlsx | ForEach-Object {
        $_ | Add-Member -NotePropertyName Registrar -NotePropertyValue (Get-DkWhois $_.Domain).Registrar -Force
        Start-Sleep -Milliseconds 1100   # rate limit: 1 request/sec/source IP, see NOTES
    }

.NOTES
    Author: Kris6673
    Date:   2026-07-03
    Rate limit: 1 request per second per source IP. Exceeding it triggers a temporary ban
    (see whois-service-specification on GitHub, "Implementation Limitations"). Callers doing
    bulk lookups must throttle themselves - this function does not throttle internally.
#>
    param (
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Domain
    )
    try {
        $ascii = [System.Globalization.IdnMapping]::new().GetAscii($Domain.Trim())

        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect('whois.punktum.dk', 43)
        $stream = $client.GetStream()
        $bytes = [Text.Encoding]::ASCII.GetBytes("--charset=utf-8 --show-handles $ascii`r`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()

        $ms = New-Object System.IO.MemoryStream
        $buffer = New-Object byte[] 4096
        $deadline = (Get-Date).AddSeconds(10)
        while ((Get-Date) -lt $deadline) {
            if ($stream.DataAvailable) {
                $read = $stream.Read($buffer, 0, 4096)
                if ($read -le 0) { break }
                $ms.Write($buffer, 0, $read)
            } elseif ($ms.Length -gt 0) {
                break   # got data, quiet since -> done
            } else {
                Start-Sleep -Milliseconds 200
            }
        }
        $client.Close()

        $text = [Text.Encoding]::UTF8.GetString($ms.ToArray())

        $result = [ordered]@{}
        $section = $null
        $sectionFields = $null
        foreach ($line in ($text -split "\r?\n")) {
            if ($line -match '^\s*#' -or $line.Trim() -eq '') { continue }
            if ($line -match '^(\S.*?):\s*(.*)$') {
                $key = ConvertTo-DkWhoisKey $matches[1].Trim()
                $value = $matches[2].Trim()
                $target = if ($section) { $sectionFields } else { $result }
                if ($target.Contains($key)) { $target[$key] = @($target[$key]) + $value }
                else { $target[$key] = $value }
            } else {
                if ($section) { $result[$section] = ConvertTo-DkWhoisSectionValue $sectionFields }
                $section = ConvertTo-DkWhoisKey $line.Trim()
                $sectionFields = [ordered]@{}
            }
        }
        if ($section) { $result[$section] = ConvertTo-DkWhoisSectionValue $sectionFields }

        if (-not $result.Contains('Domain')) { return $null }   # e.g. "No entries found ..." for an unregistered domain
        [PSCustomObject]$result
    } catch {
        return $null
    }
}

function ConvertTo-DkWhoisSectionValue {
    <#
.SYNOPSIS
    Internal helper: a section with only one distinct field (e.g. "Nameservers" with repeated
    "Hostname:" lines) collapses to a plain array of that field's values; otherwise it becomes
    a nested PSCustomObject.
#>
    param ([parameter(Mandatory = $true)] [System.Collections.Specialized.OrderedDictionary]$Fields)
    if ($Fields.Keys.Count -eq 1) { return $Fields[$Fields.Keys[0]] }
    [PSCustomObject]$Fields
}

function Get-DkRegistrar {
    <#
.SYNOPSIS
    Looks up the registrar name for a .dk domain. Thin convenience wrapper around Get-DkWhois.

.PARAMETER Domain
    The .dk domain name to look up, e.g. "example.dk".

.OUTPUTS
    System.String
    The registrar name (e.g. "One.com A/S"), or an empty string if none is associated.

.EXAMPLE
    Get-DkRegistrar -Domain "google.dk"
    Returns "MarkMonitor Inc."
#>
    param (
        [parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Domain
    )
    (Get-DkWhois -Domain $Domain).Registrar
}
