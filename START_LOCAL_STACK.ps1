# SpiralCoin - Start Local Stack (Backend + optional Daemon)
# - Starts backend if not already running
# - Builds and starts daemon if toolchains are available
# - Verifies backend health and RPC

$ErrorActionPreference = 'Continue'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Test-Command {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Get-PortPid {
  param([int]$Port)
  try {
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    return $conn.OwningProcess
  } catch { return $null }
}

function Start-Backend {
  $pid = Get-PortPid -Port 5000
  if ($pid) {
    Write-Host "[INFO] Backend already listening on :5000 (PID $pid)" -ForegroundColor Yellow
    return
  }
  if (-not (Test-Command 'node')) {
    Write-Host "[ERROR] Node.js is not installed. Please install Node.js or run INSTALL_PREREQS.ps1." -ForegroundColor Red
    return
  }
  Write-Host "[STEP] Starting backend (server.js)" -ForegroundColor Cyan
  try {
    Start-Process -FilePath "node" -ArgumentList "server.js" -WorkingDirectory $scriptDir -WindowStyle Minimized | Out-Null
    Start-Sleep -Seconds 2
  } catch { Write-Host "[WARN] Could not start backend: $($_.Exception.Message)" -ForegroundColor Yellow }
}

function Build-And-Start-Daemon {
  $pid = Get-PortPid -Port 8545
  if ($pid) {
    Write-Host "[INFO] Daemon already listening on :8545 (PID $pid)" -ForegroundColor Yellow
    return
  }
  $exe = Join-Path $scriptDir 'build/spiralcoind.exe'
  if (-not (Test-Path $exe)) {
    Write-Host "[STEP] Building daemon (spiralcoind.exe)" -ForegroundColor Cyan
    if (Test-Command 'cl') {
      try {
        Push-Location $scriptDir
        & cl /std:c++20 /EHsc /I include src\*.cpp /Fe:build\spiralcoind.exe Ws2_32.lib Crypt32.lib
        Pop-Location
      } catch { Write-Host "[WARN] MSVC build failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    if ((-not (Test-Path $exe)) -and (Test-Command 'g++')) {
      try {
        Push-Location $scriptDir
        $files = (Get-ChildItem src -Filter *.cpp).FullName -join ' '
        & g++ -std=c++20 -I include $files -o build/spiralcoind.exe -pthread -lws2_32 -lcrypt32
        Pop-Location
      } catch { Write-Host "[WARN] MinGW build failed: $($_.Exception.Message)" -ForegroundColor Yellow }
    }
    if (-not (Test-Path $exe)) {
      Write-Host "[INFO] Skipping daemon start (compiler toolchain not available)." -ForegroundColor Yellow
      return
    }
  }
  Write-Host "[STEP] Starting daemon (spiralcoind.exe)" -ForegroundColor Cyan
  try {
    Start-Process -FilePath $exe -WorkingDirectory $scriptDir -WindowStyle Minimized | Out-Null
    Start-Sleep -Seconds 2
  } catch { Write-Host "[WARN] Could not start daemon: $($_.Exception.Message)" -ForegroundColor Yellow }
}

function Get-UrlResponse {
  param([string]$Url)
  try { return Invoke-RestMethod -Uri $Url -TimeoutSec 5 } catch { return $null }
}

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Start Local Stack" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan; Write-Host ""

Start-Backend
Build-And-Start-Daemon

# Verify endpoints
$base = "http://127.0.0.1"
Write-Host "[VERIFY] Backend /health" -ForegroundColor Cyan
$health = Get-UrlResponse "$base:5000/health"
if ($health) { Write-Host "[OK] Backend healthy: $($health.status)" -ForegroundColor Green } else { Write-Host "[WARN] Backend /health not responding" -ForegroundColor Yellow }

Write-Host "[VERIFY] Backend /api/status" -ForegroundColor Cyan
$status = Get-UrlResponse "$base:5000/api/status"
if ($status) {
  Write-Host "[OK] Status: block=$($status.blockNumber) peers=$($status.peerCount) chainId=$($status.chainId)" -ForegroundColor Green
} else {
  Write-Host "[WARN] /api/status not responding yet" -ForegroundColor Yellow
}

Write-Host "[VERIFY] Daemon RPC (getblockcount)" -ForegroundColor Cyan
try {
  $payload = '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
  $rpc = Invoke-RestMethod -Method Post -Uri "$base:8545/rpc" -Body $payload -ContentType 'application/json'
  if ($rpc) { Write-Host "[OK] RPC responded: $($rpc.result)" -ForegroundColor Green } else { Write-Host "[WARN] RPC no response" -ForegroundColor Yellow }
} catch { Write-Host "[WARN] RPC test failed (daemon may be starting)" -ForegroundColor Yellow }

Write-Host ""; Write-Host "[DONE] Local stack start complete" -ForegroundColor Cyan
exit 0
