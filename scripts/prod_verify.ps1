param(
  [string]$Base = "https://www.spiralcoin.net"
)

Write-Host "== Basic pages =="
function Show-Status([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-Host "[$Url] $($r.StatusCode)"
  } catch {
    Write-Host "[$Url] ERROR: $($_.Exception.Message)" -ForegroundColor Red
  }
}

Show-Status "$Base/"
Show-Status "$Base/trading_platform.html"
Show-Status "$Base/health"

Write-Host "`n== Quotes/Candles =="
Show-Status "$Base/api/market/quotes"
Show-Status "$Base/api/market/candles?asset=ETH&vs=USD&interval=1h"

Write-Host "`n== SSE (first events) =="
try {
  $quotes = iwr -Uri "$Base/api/market/stream/quotes" -UseBasicParsing -Headers @{ 'Accept'='text/event-stream' } -TimeoutSec 10
  # Note: Invoke-WebRequest may buffer; for quick smoke we just print headers
  Write-Host "Quotes SSE CT: $($quotes.Headers['Content-Type'])"
} catch {
  Write-Host "Quotes SSE ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

try {
  $candles = iwr -Uri "$Base/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" -UseBasicParsing -Headers @{ 'Accept'='text/event-stream' } -TimeoutSec 10
  Write-Host "Candles SSE CT: $($candles.Headers['Content-Type'])"
} catch {
  Write-Host "Candles SSE ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n== TLS quick check =="
try {
  $Server = ($Base -replace '^https?://','').TrimEnd('/')
  # On Windows without OpenSSL, quick HEAD as a proxy for trust
  $r = Invoke-WebRequest -Uri ("https://$Server/") -UseBasicParsing -Method Head -TimeoutSec 10
  Write-Host "TLS OK: $($r.StatusCode) from $Server"
} catch {
  Write-Host "TLS ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nDone."