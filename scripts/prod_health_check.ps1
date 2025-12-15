# SpiralCoin - Production health check (run from your workstation)
param(
    [string]$Server = "174.138.37.6",
    [string[]]$Ports = @('22','2222','8545','5000','4000','3000'),
    [string]$User = "root"
)

$ErrorActionPreference = 'Stop'

Write-Host "=== SpiralCoin Production Health Check ===" -ForegroundColor Cyan

# 1) Port reachability from here
Write-Host "[*] Checking TCP ports from this machine..." -ForegroundColor Yellow
foreach ($p in $Ports) {
    $r = Test-NetConnection -ComputerName $Server -Port $p -WarningAction SilentlyContinue
    $status = if ($r.TcpTestSucceeded) { 'OPEN' } else { 'CLOSED' }
    $color = if ($r.TcpTestSucceeded) { 'Green' } else { 'Red' }
    Write-Host ("  Port {0}: {1}" -f $p, $status) -ForegroundColor $color
}

# Choose SSH port (prefer 22, fallback 2222)
$sshPort = $Ports | Where-Object { $_ -in @('22','2222') -and (Test-NetConnection -ComputerName $Server -Port $_ -WarningAction SilentlyContinue).TcpTestSucceeded } | Select-Object -First 1
if (-not $sshPort) {
    Write-Host "No SSH port reachable (22/2222)." -ForegroundColor Red
    exit 1
}

# 2) Remote docker/service checks
Write-Host "[*] Checking docker services on server (port $sshPort)..." -ForegroundColor Yellow
$remoteCmd = @'
set -e
if ! command -v docker >/dev/null 2>&1; then echo "docker missing"; exit 1; fi
cd /root/spiralcoin || exit 1
docker compose ps
# Lightweight HTTP checks (best-effort)
check() { curl -fsS --max-time 3 "$1" || echo "fail $1"; }
check http://localhost:8545 || true
check http://localhost:5000/health || true
check http://localhost:4000/api/feed || true
'@
ssh -p $sshPort -o StrictHostKeyChecking=no ($User + '@' + $Server) $remoteCmd

Write-Host "Done." -ForegroundColor Green
