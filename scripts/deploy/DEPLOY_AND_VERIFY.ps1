Param(
  [string]$Server = 'root@174.138.37.6',
  [string]$HostName = 'spiralcoin.net'
)

$ErrorActionPreference = 'Stop'

Write-Host "[1/5] Syncing Nginx site config..." -ForegroundColor Cyan
scp "$(Join-Path $PSScriptRoot '..' 'nginx' 'spiralcoin.conf')" "$Server:/etc/nginx/sites-available/spiralcoin"

ssh $Server @'
set -e
ln -sf /etc/nginx/sites-available/spiralcoin /etc/nginx/sites-enabled/spiralcoin
nginx -t
systemctl reload nginx
echo "Nginx reloaded"
'@

Write-Host "[2/5] Syncing backend and public files..." -ForegroundColor Cyan
scp "$(Join-Path $PSScriptRoot '..' '..' 'server.js')" "$Server:/root/spiralcoin/server.js"
scp "$(Join-Path $PSScriptRoot '..' '..' 'public' 'trading_platform.html')" "$Server:/root/spiralcoin/public/trading_platform.html"
scp "$(Join-Path $PSScriptRoot '..' '..' 'public' 'exchange.html')" "$Server:/root/spiralcoin/public/exchange.html"

Write-Host "[3/5] Rebuilding and restarting backend container..." -ForegroundColor Cyan
ssh $Server @'
set -e
cd /root/spiralcoin
docker compose up -d --build backend || docker-compose up -d --build backend
sleep 2
echo "Backend rebuilt and restarted"
'@

Write-Host "[4/5] Verifying HTTPS endpoints..." -ForegroundColor Cyan
ssh $Server @"
set -e
curl -sS -I https://$HostName | head -n 1
echo '--- /health'; curl -sS https://$HostName/health
echo '--- /api/status'; curl -sS https://$HostName/api/status | head -c 300; echo
echo '--- /api/exchange/info'; curl -sS https://$HostName/api/exchange/info | head -c 300; echo
echo '--- /api/feed'; curl -sS https://$HostName/api/feed | head -c 300; echo
echo '--- /trading_platform.html'; curl -sS https://$HostName/trading_platform.html | head -c 120 | sed -n '1,3p'
"@

Write-Host "[5/5] Done." -ForegroundColor Green
