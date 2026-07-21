# Creates the Consult Scribe desktop icon and the connector auto-start entry.
# Both go through wscript so nothing flashes a console window.
# Run once on the workstation:
#   powershell -ExecutionPolicy Bypass -File C:\ConsultScribe\make-shortcuts.ps1
$ws = New-Object -ComObject WScript.Shell

# Desktop icon: starts the connector if needed, then opens the app.
$desktop = $ws.CreateShortcut([Environment]::GetFolderPath("Desktop") + "\Consult Scribe.lnk")
$desktop.TargetPath = "$env:SystemRoot\System32\wscript.exe"
$desktop.Arguments = '"C:\ConsultScribe\launch.vbs"'
$desktop.IconLocation = "C:\ConsultScribe\consultscribe.ico"
$desktop.Description = "Consult Scribe - dictation to Optomate"
$desktop.WorkingDirectory = "C:\ConsultScribe"
$desktop.Save()

# Login auto-start: connector only, silent.
$startup = $ws.CreateShortcut([Environment]::GetFolderPath("Startup") + "\Consult Scribe Connector.lnk")
$startup.TargetPath = "$env:SystemRoot\System32\wscript.exe"
$startup.Arguments = '"C:\ConsultScribe\start-connector.vbs"'
$startup.Description = "Starts the Consult Scribe connector at login"
$startup.WorkingDirectory = "C:\ConsultScribe"
$startup.Save()

Write-Host "SHORTCUTS-CREATED"
