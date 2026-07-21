' Runs the Consult Scribe launcher with no console window flash.
' Target of the desktop icon.
Set sh = CreateObject("WScript.Shell")
sh.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\ConsultScribe\launch.ps1""", 0, False
