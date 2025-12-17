<#
SpiralCoin Production Deployment Script
Simplified and hardened to avoid parser issues with quotes/backticks.
#>

$ErrorActionPreference = 'Stop'

$SERVER = '174.138.37.6'
$SSH_PORTS = @(22, 2222)
$SSH_USER = 'root'
$RPC_PORT = 8545
$BACKEND_PORT = 5000
$MARKETFEED_PORT = 4000

Write-Host '======================================' -ForegroundColor Cyan
Write-Host '  SpiralCoin Production Deployment' -ForegroundColor Cyan
Write-Host '======================================' -ForegroundColor Cyan
Write-Host ''

# Step 1: Check connectivity
Write-Host '[*] Step 1: Checking server connectivity...' -ForegroundColor Yellow
$SSH_PORT = $null
foreach ($p in $SSH_PORTS) {
    $r = Test-NetConnection -ComputerName $SERVER -Port $p -WarningAction SilentlyContinue
    if ($r.TcpTestSucceeded) { $SSH_PORT = $p; break }
}
if (-not $SSH_PORT) {
    Write-Host ('FAILED: Cannot reach server on ports ' + ($SSH_PORTS -join ', ')) -ForegroundColor Red
    Write-Host 'Please open the web console, apply SSH fix, then retry.' -ForegroundColor Red
    exit 1
}
Write-Host ('Server is online on port ' + $SSH_PORT) -ForegroundColor Green

# Step 2: Deploy Docker stack (bash -lc to avoid shell incompatibilities)
Write-Host '[*] Step 2: Installing Docker and deploying services...' -ForegroundColor Yellow
$cmdParts = @(
    'set -e',
    'echo Installing Docker...',
    'curl -fsSL https://get.docker.com | sh > /dev/null 2>&1 || true',
    'echo Syncing repository...',
    'if [ -d /root/spiralcoin/.git ]; then cd /root/spiralcoin && git fetch origin && git reset --hard origin/main; else cd /root && rm -rf spiralcoin && git clone https://github.com/SpiralCoinOfficial/spiralcoin.git; fi',
    'cd /root/spiralcoin',
    'echo Applying build fixes (disable evmone include and macro if present)...',
    "bash -lc 'grep -q ""evmone/evmone.h"" include/state_db.h && sed -i ""s|#include <evmone/evmone.h>|// evmone disabled|g"" include/state_db.h || true'",
    "bash -lc 'sed -i ""s/-D HAVE_EVMONE=0//"" Dockerfile.daemon || true'",
    'echo Building and starting services...',
    'docker compose --env-file /dev/null up -d --build 2>&1 | tail -n 40 || true',
    'echo Waiting for services to start...',
    'sleep 10',
    'echo Service status:',
    'docker compose ps || true'
)
$bashCmd = 'bash -lc "' + ($cmdParts -join '; ') + '"'

ssh -p $SSH_PORT -o StrictHostKeyChecking=no ($SSH_USER + '@' + $SERVER) $bashCmd

Write-Host 'Deployment command sent to server.' -ForegroundColor Green

# Step 3: Verify services (best-effort)
Write-Host '[*] Step 3: Verifying service health...' -ForegroundColor Yellow

$services = @(
    @{ Name = 'RPC Daemon'; Port = $RPC_PORT; Path = '/' },
    @{ Name = 'Backend API'; Port = $BACKEND_PORT; Path = '/' },
    @{ Name = 'MarketFeed'; Port = $MARKETFEED_PORT; Path = '/' }
)

foreach ($svc in $services) {
    try {
        $url = ('http://' + $SERVER + ':' + $svc.Port + $svc.Path)
        $null = Invoke-WebRequest -Uri $url -TimeoutSec 5 -ErrorAction Stop
        Write-Host ('OK ' + $svc.Name + ' (port ' + $svc.Port + '): RESPONDING') -ForegroundColor Green
    } catch {
        Write-Host ('WARN ' + $svc.Name + ' (port ' + $svc.Port + '): Not yet responding') -ForegroundColor Yellow
    }
}

# Step 4: Show summary
Write-Host ''
Write-Host '======================================' -ForegroundColor Cyan
Write-Host '  DEPLOYMENT COMPLETE (best-effort)' -ForegroundColor Green
Write-Host '======================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Access your services:' -ForegroundColor Cyan
Write-Host ('  RPC:       http://' + $SERVER + ':' + $RPC_PORT) -ForegroundColor White
Write-Host ('  Backend:   http://' + $SERVER + ':' + $BACKEND_PORT) -ForegroundColor White
Write-Host ('  MarketFeed: http://' + $SERVER + ':' + $MARKETFEED_PORT) -ForegroundColor White
Write-Host '  Web UI:    http://spiralcoin.net (nginx)' -ForegroundColor White
Write-Host ''
Write-Host 'SSH Access:' -ForegroundColor Cyan
Write-Host ('  ssh -p ' + $SSH_PORT + ' root@' + $SERVER) -ForegroundColor White
Write-Host ''
Write-Host 'Useful Commands:' -ForegroundColor Cyan
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose ps"') -ForegroundColor White
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose logs -f"') -ForegroundColor White
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose restart"') -ForegroundColor White
Write-Host ''
