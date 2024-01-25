# Powershell Notes

## Table of Contents <!-- omit in toc -->

1. [Error handling in Powershell](#error-handling-in-powershell)

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
