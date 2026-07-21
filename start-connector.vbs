' Starts the Consult Scribe connector silently at login.
' Target of the Startup-folder shortcut.
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\ConsultScribe\connector.ps1""", 0, False
