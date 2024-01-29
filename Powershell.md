# Powershell Notes

## Table of Contents <!-- omit in toc -->

1. [Error handling in Powershell](#error-handling-in-powershell)
2. [Run as system](#run-as-system)

### Error handling in Powershell

This gets the type of the exception from the first error in the error list. The output is the full name of the exception type, that can be used to catch the exception in the square brackets of the catch block.

```powershell
$Error[0].Exception.GetType().FullName
```

The most useful properties are:

- $\_.Exception.Message: The error message text.
- $\_.Exception.ItemName: The input that caused the error.
- $\_.Exception.PSMessageDetails: Additional info about the error.
- $\_.CategoryInfo: The category of the error, such as InvalidArgument.
- $\_.FullyQualifiedErrorId: The full ID of the error, such as NativeCommandError.
- $\_.Exception.GetType().FullName – Gets you the full name of the exception

### Run as system

Sometimes you need to run a script as system to test. This is usually to test a script that will be run as a scheduled task, or a script for Intune. To do this, you can use the following command:

```powershell
Invoke-WebRequest -Uri 'https://live.sysinternals.com/PsExec64.exe'-OutFile $env:TEMP\PsExec64.exe
Start-Process $env:TEMP\PsExec64.exe '-i -s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe'
Start-Sleep -Seconds 5
# After you are done with the script, remove the PsExec64.exe file
Remove-Item $env:TEMP\PsExec64.exe
```

Bit hacky, but meh.
