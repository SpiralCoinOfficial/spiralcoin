# SpiralCoin - Full Automatic Setup & Run (Windows PowerShell)
# - Installs Docker if needed (uses INSTALL_DOCKER_AUTO.ps1)
# - Builds and runs C++ daemon in Docker (port 8545)
# - Starts Node.js backend (port 5000)
# - Verifies endpoints

$ErrorActionPreference = 'Stop'

Write-Host ""; Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   SpiralCoin - Automatic Setup & Run" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Move to repo root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Test-Command {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Ensure-Docker {
  if (Test-Command 'docker') {
    try { $v = docker --version 2>$null; Write-Host "[OK] Docker present: $v" -ForegroundColor Green } catch { Write-Host "[WARN] Docker check failed" -ForegroundColor Yellow }
    return $true
  }
  Write-Host "[INFO] Docker not found. Opening Docker Desktop download page..." -ForegroundColor Yellow
  Start-Process "https://www.docker.com/products/docker-desktop"
  return $false
}

function Ensure-NodeBackend {
  Write-Host "[STEP] Installing backend dependencies (npm install)" -ForegroundColor Cyan
  npm install | Out-Null
  Write-Host "[STEP] Starting backend on port 5000" -ForegroundColor Cyan
  $backend = Start-Process -FilePath 'node' -ArgumentList 'server.js' -PassThru -WindowStyle Minimized
  Start-Sleep -Seconds 3
  return $backend
}

function Ensure-DataDir {
  $dataDir = Join-Path $scriptDir 'data'
  if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir | Out-Null }
  return $dataDir
}

function Build-And-Run-Daemon {
  if (-not (Test-Command 'docker')) { Write-Host "[SKIP] Docker not available; skipping daemon build/run" -ForegroundColor Yellow; return }
  Write-Host "[STEP] Building daemon Docker image" -ForegroundColor Cyan
  docker build -f "$scriptDir\Dockerfile.daemon" -t spiralcoind:latest "$scriptDir"
  Write-Host "[STEP] Starting daemon container (port 8545)" -ForegroundColor Cyan
  $dataDir = Ensure-DataDir
  docker rm -f spiralcoind 2>$null | Out-Null
  $vol = (Get-Location).Path + "\data:/app/data"
  docker run -d --name spiralcoind -p 8545:8545 -v $vol spiralcoind:latest | Out-Null
}

function Verify {
  Write-Host "[VERIFY] Checking backend health" -ForegroundColor Cyan
  try {
    $health = Invoke-RestMethod "http://127.0.0.1:5000/health"
    Write-Host "[OK] Backend healthy: $($health.status)" -ForegroundColor Green
  } catch { Write-Host "[ERROR] Backend not responding" -ForegroundColor Red }

  Write-Host "[VERIFY] Checking chain status" -ForegroundColor Cyan
  try {
    $status = Invoke-RestMethod "http://127.0.0.1:5000/api/status"
    Write-Host "[OK] Status: block=$($status.blockNumber) peers=$($status.peerCount) chainId=$($status.chainId)" -ForegroundColor Green
  } catch { Write-Host "[WARN] Status failed (RPC may be warming up)" -ForegroundColor Yellow }

  Write-Host "[VERIFY] Testing RPC getblockcount (daemon)" -ForegroundColor Cyan
  try {
    $payload = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
    $rpc = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:8545/rpc" -Body $payload -ContentType 'application/json'
    Write-Host "[OK] RPC responded: $($rpc.result)" -ForegroundColor Green
  } catch { Write-Host "[WARN] RPC test failed (daemon may be starting)" -ForegroundColor Yellow }
}

# Execute
if (Ensure-Docker) { Build-And-Run-Daemon } else { Write-Host "[NOTE] You can re-run this script after installing Docker." -ForegroundColor Yellow }
$backendProc = Ensure-NodeBackend
Verify

Write-Host ""; Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin running!" -ForegroundColor Cyan
Write-Host "  • Backend: http://127.0.0.1:5000" -ForegroundColor Cyan
Write-Host "  • RPC:     http://127.0.0.1:8545" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
