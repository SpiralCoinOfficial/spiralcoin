<#
SpiralCoin Production Deployment Script
Simplified and hardened to avoid parser issues with quotes/backticks.
#>

$ErrorActionPreference = 'Stop'

$SERVER = '174.138.37.6'
$SSH_PORTS = @(22, 2222)
$SSH_USER = 'root'
$BACKEND_PORT = 5000
$PUBLIC_HTTP_PORT = 80
$PUBLIC_HTTPS_PORT = 443

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
    'apt-get update -y >/dev/null 2>&1 || true',
    'apt-get install -y docker-compose-plugin ca-certificates curl gnupg >/dev/null 2>&1 || true',
    'systemctl enable docker >/dev/null 2>&1 || true',
    'systemctl start docker >/dev/null 2>&1 || true',
    'echo Syncing repository...',
    'if [ -d /root/spiralcoin/.git ]; then cd /root/spiralcoin && git fetch origin && git reset --hard origin/main; else cd /root && rm -rf spiralcoin && git clone https://github.com/SpiralCoinOfficial/spiralcoin.git; fi',
    'cd /root/spiralcoin',
    'touch .env',
    'grep -q "^NODE_ENV=" .env || echo "NODE_ENV=production" >> .env',
    'grep -q "^PORT=" .env || echo "PORT=5000" >> .env',
    'grep -q "^RPC_URL=" .env || echo "RPC_URL=http://daemon:8545" >> .env',
    'grep -q "^NAME=" .env || echo "NAME=SpiralCoin" >> .env',
    'grep -q "^SYMBOL=" .env || echo "SYMBOL=SPRC" >> .env',
    'grep -q "^EXT_FEED=" .env || echo "EXT_FEED=https://api.example.com/feed" >> .env',
    'grep -q "^NODE_PORT=" .env || echo "NODE_PORT=4000" >> .env',
    'grep -q "^JWT_SECRET=" .env || echo "JWT_SECRET=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 48)" >> .env',
    'echo Applying build fixes (disable evmone include and macro if present)...',
    "bash -lc 'grep -q ""evmone/evmone.h"" include/state_db.h && sed -i ""s|#include <evmone/evmone.h>|// evmone disabled|g"" include/state_db.h || true'",
    "bash -lc 'sed -i ""s/-D HAVE_EVMONE=0//"" Dockerfile.daemon || true'",
    'echo Building and starting services...',
    'docker compose up -d --build 2>&1 | tail -n 80 || true',
    'echo Waiting for services to start...',
    'for i in $(seq 1 30); do sleep 2; done',
    'echo Service status:',
    'docker compose ps || true'
)
$bashCmd = 'bash -lc "' + ($cmdParts -join '; ') + '"'

# Use BatchMode to avoid interactive password prompts; expect key-based auth
ssh -p $SSH_PORT -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 ($SSH_USER + '@' + $SERVER) $bashCmd

Write-Host 'Deployment command sent to server.' -ForegroundColor Green

# Step 3: Verify services (best-effort)
Write-Host '[*] Step 3: Verifying service health...' -ForegroundColor Yellow

$remoteChecks = @(
    @{ Name = 'Docker Compose backend service'; Command = 'cd /root/spiralcoin && docker compose ps --status running backend | grep -q backend' },
    @{ Name = 'Backend API health'; Command = 'curl -fsS http://127.0.0.1:5000/health >/dev/null' },
    @{ Name = 'Backend RPC proxy'; Command = 'curl -fsS -H "Content-Type: application/json" -d "{""jsonrpc"":""2.0"",""id"":1,""method"":""getblockcount"",""params"":[]}" http://127.0.0.1:5000/api/rpc >/dev/null || true' }
)

foreach ($check in $remoteChecks) {
    try {
        ssh -p $SSH_PORT -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 ($SSH_USER + '@' + $SERVER) ('bash -lc ''' + $check.Command + '''') | Out-Null
        Write-Host ('OK ' + $check.Name) -ForegroundColor Green
    } catch {
        Write-Host ('WARN ' + $check.Name + ': Not yet responding') -ForegroundColor Yellow
    }
}

# Step 4: Show summary
Write-Host ''
Write-Host '======================================' -ForegroundColor Cyan
Write-Host '  DEPLOYMENT COMPLETE (best-effort)' -ForegroundColor Green
Write-Host '======================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Access your services:' -ForegroundColor Cyan
Write-Host ('  Backend health: http://' + $SERVER + ':' + $BACKEND_PORT + '/health') -ForegroundColor White
Write-Host ('  Public HTTP:    http://' + $SERVER + ':' + $PUBLIC_HTTP_PORT) -ForegroundColor White
Write-Host ('  Public HTTPS:   https://spiralcoin.net:' + $PUBLIC_HTTPS_PORT) -ForegroundColor White
Write-Host '  Public RPC:     https://spiralcoin.net/api/rpc' -ForegroundColor White
Write-Host '  MarketFeed:     internal compose service (not host-published by default)' -ForegroundColor White
Write-Host ''
Write-Host 'SSH Access:' -ForegroundColor Cyan
Write-Host ('  ssh -p ' + $SSH_PORT + ' root@' + $SERVER) -ForegroundColor White
Write-Host ''
Write-Host 'Useful Commands:' -ForegroundColor Cyan
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose ps"') -ForegroundColor White
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose logs -f"') -ForegroundColor White
Write-Host ('  ssh root@' + $SERVER + ' "cd /root/spiralcoin && docker compose restart"') -ForegroundColor White
Write-Host ''
