param(
  [string]$Domain = "www.spiralcoin.net"
)

$ErrorActionPreference = 'Continue'

Write-Host "=== SpiralCoin Production Verify ===" -ForegroundColor Cyan
Write-Host "Domain: $Domain"

function Try-Step($label, [ScriptBlock]$block) {
  Write-Host "\n== $label ==" -ForegroundColor Yellow
  try {
    & $block
  } catch {
    Write-Warning $_
  }
}

Try-Step "DNS resolution" {
  try {
    Resolve-DnsName $Domain -Type A | Format-Table -AutoSize
  } catch {
    Write-Warning "DNS A lookup failed: $($_.Exception.Message)"
  }
}

Try-Step "HTTP redirect (80 -> 443)" {
  try {
    $r = Invoke-WebRequest -Uri ("http://{0}/" -f $Domain) -UseBasicParsing -MaximumRedirection 0 -Method Head -TimeoutSec 8 -ErrorAction Stop
    Write-Host "HTTP ${($r.StatusCode)}"; $r.Headers.Location
  } catch {
    if ($_.Exception.Response) {
      $resp = $_.Exception.Response
      Write-Host "HTTP $($resp.StatusCode)"; $resp.Headers.Location
    } else { throw }
  }
}

Try-Step "TLS/Certificate check" {
  node scripts/prod_tls_check.js --host $Domain
}

Try-Step "HTTPS headers on /" {
  $resp = Invoke-WebRequest -Uri ("https://{0}/" -f $Domain) -UseBasicParsing -Method Head -TimeoutSec 10
  Write-Host "Status: $($resp.StatusCode)"
  $h = $resp.Headers
  $h["Strict-Transport-Security"] | ForEach-Object { Write-Host "HSTS: $_" }
  $h["Content-Security-Policy"] | ForEach-Object { Write-Host "CSP: $_" }
}

Try-Step "Basic pages" {
  function Show-Status([string]$Url) {
    try {
      $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
      Write-Host "[$Url] $($r.StatusCode)"
    } catch {
      Write-Host "[$Url] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  $Base = "https://$Domain"
  Show-Status "$Base/"
  Show-Status "$Base/trading_platform.html"
  Show-Status "$Base/health"
}

Try-Step "API: quotes and candles" {
  $Base = "https://$Domain"
  function Show-Status([string]$Url) {
    try {
      $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
      Write-Host "[$Url] $($r.StatusCode)"
    } catch {
      Write-Host "[$Url] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
  Show-Status "$Base/api/market/quotes"
  Show-Status "$Base/api/market/candles?asset=ETH&vs=USD&interval=1h"
}

Try-Step "SSE: quotes and candles" {
  $env:BASE_URL = ("https://{0}" -f $Domain)
  node scripts/qa_sse_streams.js
  Remove-Item Env:\BASE_URL -ErrorAction SilentlyContinue
}

Write-Host "\n=== Production verification finished ===" -ForegroundColor Green
