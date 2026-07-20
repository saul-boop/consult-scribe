# Creates the Consult Scribe desktop icon (Chrome app window) and the
# connector auto-start entry. Run once on the workstation:
#   powershell -ExecutionPolicy Bypass -File C:\ConsultScribe\make-shortcuts.ps1
$ws = New-Object -ComObject WScript.Shell

$chrome = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { Write-Host "Chrome not found - install Chrome first."; exit 1 }

$d = $ws.CreateShortcut([Environment]::GetFolderPath("Desktop") + "\Consult Scribe.lnk")
$d.TargetPath = $chrome
$d.Arguments = "--app=http://localhost:8383"
$d.IconLocation = "C:\ConsultScribe\consultscribe.ico"
$d.Description = "Consult Scribe - dictation to Optomate"
$d.Save()

$s = $ws.CreateShortcut([Environment]::GetFolderPath("Startup") + "\Consult Scribe Connector.lnk")
$s.TargetPath = "powershell.exe"
$s.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\ConsultScribe\connector.ps1"
$s.Description = "Starts the Consult Scribe connector at login"
$s.Save()

Write-Host "SHORTCUTS-CREATED using $chrome"
