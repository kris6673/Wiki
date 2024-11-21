
Function Write-ToEventlog {
    <#
.SYNOPSIS
Writes a message to the Windows Event Log.

.DESCRIPTION
The Write-ToEventlog function writes a message to the specified Windows Event Log. 
If the log source does not exist, it creates a new event log source.

.PARAMETER Message
The message to be written to the event log.

.PARAMETER LogSource
The source of the event log entry. This is typically the name of the script or application.

.PARAMETER LogName
The name of the event log. Valid values are 'Application', 'System', and 'Security'. 
Defaults to 'Application'.

.PARAMETER Level
The level of the event log entry. Valid values are 'Information', 'Warning', 'Error', 
'SuccessAudit', and 'FailureAudit'. Defaults to 'Information'.

.PARAMETER EventID
The event ID for the log entry. Must be an integer between 0 and 65535. Defaults to 9376.

.PARAMETER Category
The category for the log entry. Defaults to 1.

.PARAMETER WriteToHost
If specified, writes the message to the host powershell window, in addition to the event log.

.EXAMPLE
Write-ToEventlog -Message "This is a test message" -LogSource "MyScript" -Level Information

Writes an informational message to the Application event log with the source "MyScript".

.EXAMPLE
Write-ToEventlog -Message "This is a warning" -LogSource "MyScript" -Level "Warning" -WriteToHost

Writes a warning message to the Application event log with the source "MyScript" and also writes the message to the host.

.NOTES
Author: kris6673
Date: 2024-11-21
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [String]$Message,
        [Parameter(Mandatory = $true)]
        [string]$LogSource, # ScriptName or whatever you want the entry name in the Event Viewer to be
        [Parameter(Mandatory = $False)][ValidateSet('Application', 'System', 'Security')]
        [String]$LogName = 'Application',
        [Parameter(Mandatory = $False)][ValidateSet('Information', 'Warning', 'Error', 'SuccessAudit', 'FailureAudit')]
        [String]$Level = 'Information',
        [Parameter(Mandatory = $False)][ValidateRange(0, 65535)]
        [int]$EventID = 9376,
        [Parameter(Mandatory = $False)]
        [String]$Category = 1,
        [Parameter(Mandatory = $False)]
        [switch]$WriteToHost
    )
    # Check the Event Viewer source exists
    if (!([System.Diagnostics.EventLog]::SourceExists($LogSource))) {
        New-EventLog -LogName $LogName -Source $LogSource -ErrorAction Continue
    }

    # Write it to Host or the Event Viewer
    try {
        $eventLogParams = @{
            LogName     = $LogName
            Source      = $LogSource
            EventId     = $EventID
            EntryType   = $Level
            Message     = $Message
            Category    = $Category
            ErrorAction = 'Stop'
        }
        Write-EventLog @eventLogParams

        if ($WriteToHost.IsPresent -eq $true) {
            Write-Host "Event Log written: $Message"
        }
    } catch {
        throw "Error writing to Event Log: $_"
    }
}