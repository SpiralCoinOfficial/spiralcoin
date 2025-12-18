# SpiralCoin - Verify Local Stack
$ErrorActionPreference = 'Continue'

function Try-Get($Url, $Method = 'GET', $Body = $null) {
  try {
    if ($Method -eq 'POST') {
      return Invoke-RestMethod -Uri $Url -Method Post -ContentType 'application/json' -Body $Body -TimeoutSec 5
    } else {
      return Invoke-RestMethod -Uri $Url -TimeoutSec 5
    }
  } catch { return $null }
}

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Verify Local Stack" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan

$base = 'http://127.0.0.1'

Write-Host "[CHECK] Backend /health" -ForegroundColor Cyan
$health = Try-Get "$base:5000/health"
if ($health) { Write-Host "[OK] Backend healthy: $($health.status)" -ForegroundColor Green } else { Write-Host "[WARN] Backend /health not responding" -ForegroundColor Yellow }

Write-Host "[CHECK] /api/status" -ForegroundColor Cyan
$status = Try-Get "$base:5000/api/status"
if ($status) {
  Write-Host "[OK] Status: block=$($status.blockNumber) peers=$($status.peerCount) chainId=$($status.chainId)" -ForegroundColor Green
  if ($status.error) { Write-Host "[INFO] Status error: $($status.error)" -ForegroundColor Yellow }
} else {
  Write-Host "[WARN] /api/status not responding" -ForegroundColor Yellow
}

Write-Host "[CHECK] Market price" -ForegroundColor Cyan
$price = Try-Get "$base:5000/api/market/price"
if ($price) { Write-Host "[OK] Market price: $($price.price)" -ForegroundColor Green } else { Write-Host "[WARN] Market price endpoint not responding" -ForegroundColor Yellow }

Write-Host "[CHECK] RPC getblockcount" -ForegroundColor Cyan
$payload = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
$rpc = Try-Get "$base:8545/rpc" 'POST' $payload
if ($rpc) { Write-Host "[OK] RPC responded: $($rpc.result)" -ForegroundColor Green } else { Write-Host "[WARN] RPC no response" -ForegroundColor Yellow }

Write-Host ""; Write-Host "[DONE] Verification complete" -ForegroundColor Cyan
exit 0
