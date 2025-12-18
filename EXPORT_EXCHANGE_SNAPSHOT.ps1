param(
  [string]$BaseUrl = "https://spiralcoin.net",
  [string]$OutDir = "snapshots"
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir | Out-Null }

function SaveJson {
  param([string]$Path, [object]$Obj)
  try {
    $json = $Obj | ConvertTo-Json -Depth 6
    Set-Content -Path (Join-Path $OutDir $Path) -Value $json -Encoding UTF8
    Write-Host "[OK] Saved $Path" -ForegroundColor Green
  } catch {
    Write-Host "[ERR] Failed to save ${Path}: $($_.Exception.Message)" -ForegroundColor Red
  }
}

function TryGet {
  param([string]$Url)
  try { return Invoke-RestMethod -Uri $Url -TimeoutSec 10 } catch { return $null }
}

Write-Host "Exporting exchange submission snapshots from $BaseUrl" -ForegroundColor Cyan

$health = TryGet "$BaseUrl/health"; if ($health) { SaveJson "health.json" $health }
$status = TryGet "$BaseUrl/api/status"; if ($status) { SaveJson "status.json" $status }
$info   = TryGet "$BaseUrl/api/exchange/info"; if ($info) { SaveJson "exchange_info.json" $info }
$price  = TryGet "$BaseUrl/api/market/price"; if ($price) { SaveJson "market_price.json" $price }
$supply = TryGet "$BaseUrl/api/wallet/verify-supply"; if ($supply) { SaveJson "verify_supply.json" $supply }

# RPC getblockcount
try {
  $payload = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
  $rpc = Invoke-RestMethod -Uri "$BaseUrl/api/rpc" -TimeoutSec 10 -UseBasicParsing -Headers @{ 'Content-Type' = 'application/json' } -Method POST -Body $payload
  SaveJson "rpc_blockcount.json" $rpc
} catch {
  Write-Host "[WARN] RPC call failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Trading endpoints
$markets = TryGet "$BaseUrl/api/trade/markets"; if ($markets) { SaveJson "trade_markets.json" $markets }
$orders  = TryGet "$BaseUrl/api/trade/orders"; if ($orders) { SaveJson "trade_orders.json" $orders }

Write-Host "Done. Files in ${OutDir}:" -ForegroundColor Cyan
Get-ChildItem -Path $OutDir | Select-Object -ExpandProperty Name
