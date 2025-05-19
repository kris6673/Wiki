# Logging functions for PowerShell scripts
Function Write-Log {
    <#
    .SYNOPSIS
        Writes a log message to the console with a specified foreground color.

    .DESCRIPTION
        The Write-Log function writes a log message to the console with a specified foreground color. It includes a timestamp indicating when the log message was generated.

    .PARAMETER Message
        The log message to be written.

    .PARAMETER ForegroundColor
        The foreground color of the log message. The available colors are: 'Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White'. The default value is 'White'.

    .EXAMPLE
        Write-Log -Message "This is a sample log message" -ForegroundColor "Yellow"
        Writes a log message to the console with the message "This is a sample log message" and the foreground color set to Yellow.
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,
        [Parameter(Mandatory = $false)]
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')]
        [string]$ForegroundColor = 'White'
    )

    $TimeGenerated = $(Get-Date -Format 'dd/MM/yy HH:mm:ss:fff')
    $Line = "$TimeGenerated : $Message"
    Write-Host $Line -ForegroundColor $ForegroundColor
}


function Initialize-Logging {
    <#
    .SYNOPSIS
        Initializes logging for the script.

    .DESCRIPTION
        This function initializes logging for the script by creating a log file and performing cleanup operations on existing log files.

    .PARAMETER DeleteLogsOlderThanDays
        Specifies the number of days after which log files should be deleted. Default value is 90.

    .PARAMETER MaxLogFileSizeInMB
        Specifies the maximum size in megabytes (MB) that a log file can reach before a new log file is created. Default value is 10.

    .PARAMETER NoLogCleanup
        Indicates whether log cleanup should be skipped. If this switch is present, log files will not be deleted or checked for size.

    .PARAMETER ScriptName
        Specifies the name of the script. The default value is the name of the script file.

    .EXAMPLE
        Initialize-Logging

    .EXAMPLE
        Initialize-Logging -DeleteLogsOlderThanDays 30 -MaxLogFileSizeInMB 5 -ScriptName 'MyScript'

    .NOTES
        The function uses the following logic to initialize logging:
        1. Tries to create a log file in the 'Logs' folder located in the same directory as the script.
        2. If the log file creation fails, it creates the log file in the temporary 'Logs' folder.
        3. Deletes log files older than the specified number of days (default is 90 days).
        4. If the log file size is greater than or equal to the specified maximum size (default is 10MB), renames the log file and creates a new one.
    #>

    param (
        [int]$DeleteLogsOlderThanDays = 90,
        [int]$MaxLogFileSizeInMB = 10,
        [switch]$NoLogCleanup,
        [array]$ScriptName = (Split-Path ($MyInvocation.ScriptName) -Leaf) -split '\.'
    )

    # Try making a log file in the same folder as the script, if that fails, make it in the temp folder
    try {
        $LogFileRoot = Join-Path $PSScriptRoot 'Logs'
        $LogFile = Join-Path $LogFileRoot "$($ScriptName[0]).log"
        Start-Transcript -Path $LogFile -Append -ErrorAction Stop
        Write-Log -Message "Logfile created at: $LogFile" -ForegroundColor Green
    } catch {
        $LogFileRoot = Join-Path $env:temp 'Logs'
        $LogFile = Join-Path $LogFileRoot "$($ScriptName[0]).log"
        Start-Transcript -Path $LogFile -Append
        Write-Log -Message "Logfile created at: $LogFile" -ForegroundColor Green
    }
    
    if ($NoLogCleanup.IsPresent) {
        Write-Host 'Skipping log cleanup' 
        return
    }

    $OlderThan = (Get-Date).AddDays(-$DeleteLogsOlderThanDays)
    # Delete log files older than the specified number of days
    Get-ChildItem "$LogFileRoot\*.log" | Where-Object { $_.LastWriteTime -le $OlderThan } | Remove-Item -Confirm:$false -Force

    # If log file is too big, make new one
    if (Test-Path -Path $LogFile) {
        $FileSizeInMB = ((Get-Item -Path $LogFile).Length) / 1MB
        
        if ($FileSizeInMB -ge $MaxLogFileSizeInMB) {
            $LogFileCreated = (Get-Item -Path $LogFile).CreationTime | Get-Date -Format FileDate
            $LogFileEnd = Get-Date -Format FileDate
            # Rename log file
            $LogfileNewName = "$($ScriptName[0])" + $LogFileCreated + '-' + $LogFileEnd + '.log'

            # Stop transcript and rename log file
            Stop-Transcript
            Start-Sleep 1
            Rename-Item -Path $LogFile -NewName $LogfileNewName -Force
            # Fix to CreationTime being remembered on the logfile even if renamed
            Add-Content -Value 'Start of logfile' -Path $LogFile -Encoding UTF8
            (Get-Item $LogFile).CreationTime = (Get-Date)

            # Start new transcript to new log file
            Start-Transcript -Path $LogFile -Append
        }
    }
}
Initialize-Logging