# CAB files are filling up the drive

On some Windows 7 machines, in the c:\windows\logs\CBS folder, there can be a corrupted CAB file, that errors out and leaves copies of itself when it tries to compress and archive itself.

## The fix

Open a CMD as admin and paste the following commands. This will delete all CAB files and the corrupted one that generating the files.


    net stop wuauserv
    cd %systemroot%
    rename SoftwareDistribution SoftwareDistribution.old
    rmdir /q /s c:\windows\temp
    net stop trustedinstaller
    c:
    cd c:\windows\logs\CBS
    del *.cab
    del *.log
    rem regenerate cab files
    c:\windows\system32\wuauclt.exe /detectnow
    net start wuauserv
    echo this is a dummy line

