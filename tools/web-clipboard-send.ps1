param(
    [Parameter(Mandatory = $true)]
    [string]$Room,

    [Parameter(Mandatory = $true)]
    [string]$TextPath,

    [string]$BaseUrl = "https://web-clipboard.jpsala.workers.dev",

    [string]$LogPath = "$env:TEMP\web-clipboard-host.log"
)

$ErrorActionPreference = "Stop"

function Write-SendLog {
    param([string]$Message)
    $line = "{0} | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
}

function Get-WebSocketUri {
    param([string]$BaseUrl, [string]$Room)

    $builder = [System.UriBuilder]::new($BaseUrl)
    if ($builder.Scheme -eq "https") {
        $builder.Scheme = "wss"
        $builder.Port = -1
    } elseif ($builder.Scheme -eq "http") {
        $builder.Scheme = "ws"
        $builder.Port = -1
    }

    $builder.Path = "/room/$([System.Uri]::EscapeDataString($Room))"
    $builder.Query = ""
    return $builder.Uri
}

if (!(Test-Path -LiteralPath $TextPath)) {
    throw "Text file not found: $TextPath"
}

$text = Get-Content -LiteralPath $TextPath -Raw -Encoding UTF8
$uri = Get-WebSocketUri -BaseUrl $BaseUrl -Room $Room
$socket = [System.Net.WebSockets.ClientWebSocket]::new()

try {
    $socket.ConnectAsync($uri, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    $message = @{ type = "clipboard"; text = $text; sentAt = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() } | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($message)
    $segment = [ArraySegment[byte]]::new($bytes)
    $socket.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [Threading.CancellationToken]::None).GetAwaiter().GetResult()
    Start-Sleep -Milliseconds 250
    Write-SendLog ("sent room=$Room chars=" + $text.Length)
} catch {
    Write-SendLog ("error " + $_.Exception.Message)
    throw
} finally {
    if ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
        try { $socket.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "done", [Threading.CancellationToken]::None).GetAwaiter().GetResult() } catch {}
    }
    $socket.Dispose()
}
