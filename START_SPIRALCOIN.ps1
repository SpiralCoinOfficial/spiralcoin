# =====================================================
# SpiralCoin Complete Startup Script (PowerShell)
# Starts both C++ daemon and Node.js backend
# =====================================================

Write-Host @"

╔════════════════════════════════════════════════════╗
║    SpiralCoin Daemon & Backend Startup (v1.0)    ║
╚════════════════════════════════════════════════════╝

"@

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Test-API {
  param([string]$Url, [string]$Name)
  try {
    $response = Invoke-WebRequest -Uri $Url -TimeoutSec 3 -ErrorAction Stop
    Write-Host "✅ $Name responding (HTTP $($response.StatusCode))"
    return $true
  }
  catch {
    Write-Host "❌ $Name not responding"
    return $false
  }
}

# Start Node.js Backend
Write-Host "[1/2] Starting Node.js Backend on port 5000..."
Start-Process -FilePath 'node' -ArgumentList 'server.js' -WindowStyle Minimized
Start-Sleep -Seconds 3

if (Test-API "http://127.0.0.1:5000/health" "Backend Health") {
  try {
    $status = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/status"
    Write-Host "       Block: $($status.blockNumber)"
    Write-Host "       Peers: $($status.peerCount)"
    Write-Host "       Gas (Wei): $($status.gasPriceWei)"
    Write-Host "       ChainId: $($status.chainId)"
  } catch { Write-Host "       Status unavailable" }
}

# Optionally start Windows C++ daemon if present
$daemonPath = Join-Path $scriptDir "build\spiralcoind.exe"
if (Test-Path $daemonPath) {
  Write-Host "[2/2] Starting C++ RPC Daemon (Windows binary) on port 8545..."
  $daemon = Start-Process -FilePath $daemonPath -PassThru -WindowStyle Minimized
  Start-Sleep -Seconds 2
  # Verify RPC
  try {
    $payload = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
    $rpc = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8545/rpc" -Body $payload -ContentType 'application/json'
    Write-Host "       RPC getblockcount: $($rpc.result)"
  } catch { Write-Host "       RPC not responding yet" }
} else {
  Write-Host "[2/2] C++ RPC Daemon Setup"
  Write-Host "       Available: .\build\spiralcoind.exe"
  Write-Host "       To start: .\build\spiralcoind.exe"
  Write-Host "       Listens on port 8545 (JSON-RPC)"
}

Write-Host ""
Write-Host "[2/2] C++ RPC Daemon Setup"
Write-Host "       Available: .\build\spiralcoind.exe"
Write-Host "       To start: .\build\spiralcoind.exe"
Write-Host "       Listens on port 8545 (JSON-RPC)"

Write-Host @"

╔════════════════════════════════════════════════════╗
║           Startup Complete - Ready!               ║
╚════════════════════════════════════════════════════╝

Available API Endpoints:
  • http://127.0.0.1:5000/health          Health check
  • http://127.0.0.1:5000/api/stats       Statistics
  • http://127.0.0.1:5000/api/blockchain  Blockchain ops
  • http://127.0.0.1:5000/api/wallet      Wallet mgmt
  • http://127.0.0.1:5000/api/market      Market data
  • http://127.0.0.1:5000/api/mining      Mining ops

Services Running:
  ✅ Node.js Backend (Port 5000)
  ✅/⏹️ C++ Daemon (Port 8545) - Started if binary present

Type 'Get-Process node' to view backend process
Type 'Stop-Process -Name node' to stop backend

"@

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
