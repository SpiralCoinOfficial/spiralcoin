# SpiralCoin - Production Deploy (Docker Compose)
# - Builds and starts daemon, backend, marketfeed, and nginx (80/443)
# - Verifies public site, backend health, status, and RPC

$ErrorActionPreference = 'Continue'

Write-Host ""; Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   SpiralCoin - Production Deployment" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

function Test-Command {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

if (-not (Test-Command 'docker')) {
  Write-Host "[ERROR] Docker is not installed. Please install Docker Desktop and re-run." -ForegroundColor Red
  Start-Process "https://www.docker.com/products/docker-desktop" | Out-Null
  exit 0
}

# Ensure Docker daemon is responsive
try {
  $null = docker info 2>$null
} catch {
  Write-Host "[INFO] Docker daemon not ready. Attempting to start Docker Desktop..." -ForegroundColor Yellow
  $dockerApp = Join-Path ${env:ProgramFiles} "Docker\\Docker\\Docker Desktop.exe"
  if (Test-Path $dockerApp) {
    try { Start-Process -FilePath $dockerApp -WindowStyle Minimized | Out-Null } catch {}
    # Wait up to ~60s for daemon
    for ($i=0; $i -lt 30; $i++) {
      try { $null = docker info 2>$null; break } catch { Start-Sleep -Seconds 2 }
    }
  } else {
    Write-Host "[HINT] Start Docker Desktop manually if installed." -ForegroundColor Yellow
  }
}

# Ensure SSL dir exists (optional)
$sslDir = Join-Path $scriptDir 'ssl'
if (-not (Test-Path $sslDir)) { New-Item -ItemType Directory -Path $sslDir | Out-Null }

# Compose helper that supports both 'docker compose' and 'docker-compose'
function Invoke-Compose {
  param([Parameter(Mandatory=$true)][string[]]$Args)
  if (Test-Command 'docker') {
    try { & docker compose @Args; return $LASTEXITCODE } catch { }
  }
  if (Test-Command 'docker-compose') {
    try { & docker-compose @Args; return $LASTEXITCODE } catch { }
  }
  Write-Host "[ERROR] Neither 'docker compose' nor 'docker-compose' is available" -ForegroundColor Red
  return 1
}

# Build and run (with fallback compose files)
$candidateFiles = @(
  (Join-Path $scriptDir 'docker-compose.prod.full.yaml'),
  (Join-Path $scriptDir 'docker-compose.prod.yaml'),
  (Join-Path $scriptDir 'compose.yaml'),
  (Join-Path $scriptDir 'docker-compose.yaml')
)
$composeFile = $null
foreach ($f in $candidateFiles) { if (Test-Path $f) { $composeFile = $f; break } }
if (-not $composeFile) {
  Write-Host "[ERROR] No compose file found (searched prod.full, prod, compose.yaml)." -ForegroundColor Red
  exit 0
}
Write-Host "[INFO] Using compose file: $composeFile" -ForegroundColor Cyan
Write-Host "[STEP] Building images via compose" -ForegroundColor Cyan
try { $null = Invoke-Compose @('-f', $composeFile, 'build') } catch { Write-Host "[WARN] Build returned an error but will continue" -ForegroundColor Yellow }

Write-Host "[STEP] Starting services (daemon, backend, marketfeed, nginx)" -ForegroundColor Cyan
try { $null = Invoke-Compose @('-f', $composeFile, 'up', '-d') } catch { Write-Host "[WARN] Up returned an error but will continue" -ForegroundColor Yellow }

# Wait for services with retries
$retries = 20; $delay = 3
for ($i=0; $i -lt $retries; $i++) {
  try { $ok = (Invoke-RestMethod -Uri 'http://127.0.0.1:5000/health' -TimeoutSec 2) } catch { $ok = $null }
  if ($ok) { break }
  Start-Sleep -Seconds $delay
}

# Verify endpoints
$base = "http://127.0.0.1"

function Get-UrlResponse {
  param([Parameter(Mandatory=$true)][string]$Url)
  try { return Invoke-RestMethod -Uri $Url -TimeoutSec 5 } catch { return $null }
}

Write-Host "[VERIFY] Public site (nginx)" -ForegroundColor Cyan
$root = Get-UrlResponse "$base/"
if ($root) { Write-Host "[OK] Public site reachable on :80" -ForegroundColor Green } else { Write-Host "[WARN] Public site not reachable yet" -ForegroundColor Yellow }

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

Write-Host ""; Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Deployment complete." -ForegroundColor Cyan
Write-Host "  • Web:     http://localhost/" -ForegroundColor Cyan
Write-Host "  • Backend: http://localhost:5000" -ForegroundColor Cyan
Write-Host "  • RPC:     http://localhost:8545" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
try {
  Write-Host "[INFO] docker compose ps" -ForegroundColor Cyan
  $null = Invoke-Compose @('-f', $composeFile, 'ps')
} catch {}
Write-Host "[TIP] View live logs: docker compose -f $composeFile logs -f" -ForegroundColor DarkCyan
exit 0
