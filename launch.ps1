# Consult Scribe launcher.
# Opens the app, starting the connector first if it isn't already running.
# This is what the desktop icon runs, so the app works even if the
# login auto-start didn't fire (Windows sometimes disables startup items).

$port = 8383
$connector = Join-Path $PSScriptRoot "connector.ps1"

function Test-Connector {
    try {
        $req = [System.Net.WebRequest]::Create("http://localhost:$port/")
        $req.Timeout = 1500
        $req.Method = "HEAD"
        $req.GetResponse().Close()
        return $true
    } catch {
        return $false
    }
}

if (-not (Test-Connector)) {
    Start-Process powershell.exe `
        -ArgumentList "-WindowStyle","Hidden","-ExecutionPolicy","Bypass","-File","`"$connector`"" `
        -WindowStyle Hidden
    # Give it up to ~10s to come up before opening the page.
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-Connector) { break }
    }
}

$chrome = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($chrome) {
    Start-Process $chrome -ArgumentList "--app=http://localhost:$port"
} else {
    Start-Process "http://localhost:$port"
}
