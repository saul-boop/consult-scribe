# Consult Scribe Connector
# Runs on the practice WORKSTATION. Does two jobs:
#   1. Serves the Consult Scribe app at http://localhost:8383 (fetches the
#      latest copy from GitHub Pages when online, falls back to a cached copy).
#   2. Relays /OptomateTouch/OData4/* requests to the Optomate Touch API on the
#      practice server, so the browser page and the API share one origin —
#      no CORS or mixed-content blocking. Credentials pass through untouched;
#      nothing is stored here.
#
# One-time setup (run in an ADMINISTRATOR PowerShell):
#   netsh http add urlacl url=http://localhost:8383/ user=Everyone
# Then start with:
#   powershell -ExecutionPolicy Bypass -File connector.ps1
# (See the setup guide for making it start automatically at logon.)

# ======= EDIT THIS if the practice server has a different name =======
$OptomateServer = "MOSMAN"
# =====================================================================
$OptomatePort   = 12000
$Port           = 8383
$AppUrl         = "https://saul-boop.github.io/consult-scribe/"
$CacheFile      = Join-Path $PSScriptRoot "app-cache.html"

$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
try {
    $listener.Start()
} catch {
    Write-Host "Could not start on port $Port. Run the one-time setup command from the header as Administrator, and check nothing else uses the port." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}
Write-Host "Consult Scribe connector running."
Write-Host "  App:            http://localhost:$Port/"
Write-Host "  Relaying API to: http://${OptomateServer}:$OptomatePort"
Write-Host "Leave this window open (or set up the auto-start task). Ctrl+C to stop."

function Send-Bytes($response, [byte[]]$bytes, $contentType, $statusCode = 200) {
    try {
        $response.StatusCode = $statusCode
        if ($contentType) { $response.ContentType = $contentType }
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } catch {}
}

while ($listener.IsListening) {
    try { $ctx = $listener.GetContext() }
    catch {
        # Transient accept errors must not kill the connector; only exit
        # if the listener itself has stopped.
        if (-not $listener.IsListening) { break } else { continue }
    }
    $req = $ctx.Request
    $res = $ctx.Response
    try {
        $path = $req.Url.AbsolutePath

        if ($path.StartsWith("/OptomateTouch/")) {
            # ---- Relay to the Optomate Touch API on the practice server ----
            $target = "http://${OptomateServer}:$OptomatePort" + $req.Url.PathAndQuery
            $relay = [System.Net.HttpWebRequest]::Create($target)
            $relay.Method = $req.HttpMethod
            $relay.Accept = "application/json"
            $relay.Timeout = 15000
            $auth = $req.Headers["Authorization"]
            if ($auth) { $relay.Headers.Add("Authorization", $auth) }
            if ($req.HasEntityBody) {
                $relay.ContentType = "application/json"
                $rs = $relay.GetRequestStream()
                $req.InputStream.CopyTo($rs)
                $rs.Close()
            }
            $relayRes = $null
            try {
                $relayRes = $relay.GetResponse()
            } catch [System.Net.WebException] {
                if ($_.Exception.Response) { $relayRes = $_.Exception.Response }
            }
            if ($relayRes) {
                $ms = New-Object System.IO.MemoryStream
                $relayRes.GetResponseStream().CopyTo($ms)
                Send-Bytes $res $ms.ToArray() $relayRes.ContentType ([int]$relayRes.StatusCode)
                $relayRes.Close()
            } else {
                $msg = '{"error":{"code":"connector","message":"The connector could not reach the Optomate server (' + $OptomateServer + '). Is the server computer on and connected to the practice network?"}}'
                Send-Bytes $res ([Text.Encoding]::UTF8.GetBytes($msg)) "application/json" 502
            }

        } elseif ($path -eq "/" -or $path -eq "/index.html") {
            # ---- Serve the app: freshest copy from GitHub Pages, else cache ----
            $html = $null
            try {
                $wc = New-Object System.Net.WebClient
                $wc.Encoding = [Text.Encoding]::UTF8
                $html = $wc.DownloadString($AppUrl)
                if ($html) { [IO.File]::WriteAllText($CacheFile, $html, [Text.Encoding]::UTF8) }
            } catch {
                if (Test-Path $CacheFile) { $html = [IO.File]::ReadAllText($CacheFile, [Text.Encoding]::UTF8) }
            }
            if ($html) {
                Send-Bytes $res ([Text.Encoding]::UTF8.GetBytes($html)) "text/html; charset=utf-8"
            } else {
                $msg = "Consult Scribe couldn't load: no internet and no cached copy yet. Connect to the internet once and reload."
                Send-Bytes $res ([Text.Encoding]::UTF8.GetBytes($msg)) "text/plain; charset=utf-8" 503
            }

        } else {
            Send-Bytes $res ([Text.Encoding]::UTF8.GetBytes("Not found")) "text/plain" 404
        }
    } catch {
        try { $res.StatusCode = 500 } catch {}
    } finally {
        try { $res.Close() } catch {}
    }
}
