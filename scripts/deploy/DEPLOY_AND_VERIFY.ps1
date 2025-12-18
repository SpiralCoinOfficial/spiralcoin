Param(
  [string]$Server = 'root@174.138.37.6',
  [string]$HostName = 'spiralcoin.net'
)

$ErrorActionPreference = 'Stop'

# Resolve paths
$ScriptsDir = Split-Path -Parent $PSScriptRoot
$RepoRoot = Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')
$NginxConf = Join-Path (Join-Path $ScriptsDir 'nginx') 'spiralcoin.conf'
$ServerJs = Join-Path $RepoRoot 'server.js'
$TradingHtml = Join-Path (Join-Path $RepoRoot 'public') 'trading_platform.html'
$ExchangeHtml = Join-Path (Join-Path $RepoRoot 'public') 'exchange.html'
$ManifestJson = Join-Path (Join-Path $RepoRoot 'public') 'manifest.json'
$ServiceWorker = Join-Path (Join-Path $RepoRoot 'public') 'service-worker.js'
$PublicScript = Join-Path (Join-Path $RepoRoot 'public') 'script.js'

Write-Host "[1/5] Syncing Nginx site config..." -ForegroundColor Cyan
scp "$NginxConf" "${Server}:/etc/nginx/sites-available/spiralcoin"
$nginxCmd = "ln -sf /etc/nginx/sites-available/spiralcoin /etc/nginx/sites-enabled/spiralcoin; nginx -t; systemctl reload nginx || systemctl restart nginx"
ssh $Server $nginxCmd

Write-Host "[2/5] Syncing backend and public files..." -ForegroundColor Cyan
scp "$ServerJs" "${Server}:/root/spiralcoin/server.js"
scp "$TradingHtml" "${Server}:/root/spiralcoin/public/trading_platform.html"
scp "$ExchangeHtml" "${Server}:/root/spiralcoin/public/exchange.html"
scp "$ManifestJson" "${Server}:/root/spiralcoin/public/manifest.json"
scp "$ServiceWorker" "${Server}:/root/spiralcoin/public/service-worker.js"
scp "$PublicScript" "${Server}:/root/spiralcoin/public/script.js"

Write-Host "[3/5] Rebuilding and restarting backend container..." -ForegroundColor Cyan
$rebuildCmd = "cd /root/spiralcoin; docker compose up -d --build backend || docker-compose up -d --build backend; sleep 2"
ssh $Server $rebuildCmd

Write-Host "[4/5] Verifying HTTPS endpoints..." -ForegroundColor Cyan
$verifyCmd = "curl -sS -I https://$HostName | head -n 1; echo '--- /health'; curl -sS https://$HostName/health; echo '--- /api/status'; curl -sS https://$HostName/api/status | head -c 300; echo; echo '--- /api/exchange/info'; curl -sS https://$HostName/api/exchange/info | head -c 300; echo; echo '--- /exchange'; curl -sS https://$HostName/exchange | head -c 200 | sed -n '1,5p'; echo; echo '--- /api/feed'; curl -sS https://$HostName/api/feed | head -c 300; echo; echo '--- /api/wallet/verify-supply'; curl -sS https://$HostName/api/wallet/verify-supply | head -c 300; echo; echo '--- /manifest.json'; curl -sS https://$HostName/manifest.json | head -c 200; echo; echo '--- /trading_platform.html'; curl -sS https://$HostName/trading_platform.html | head -c 120 | sed -n '1,3p'"
ssh $Server $verifyCmd

Write-Host "[5/5] Done." -ForegroundColor Green
