param(
  [string]$ServerHost = "174.138.37.6",
  [int]$Port = 8454,
  [string]$User = "root"
)

$ErrorActionPreference = 'Continue'
Write-Host "=== SpiralCoin: Remote Service Checks ===" -ForegroundColor Cyan
Write-Host "Target: ${User}@${ServerHost}:${Port}"

function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing command: $name. Install Windows OpenSSH client or Git for Windows (includes ssh/scp)."
  }
}
Require-Command ssh

function Run-Remote([string]$cmd) {
  ssh -p $Port "${User}@${ServerHost}" $cmd
}

Write-Host "\n== Docker compose status ==" -ForegroundColor Yellow
Run-Remote "cd /root/spiralcoin && docker compose ps"

Write-Host "\n== Backend health on server ==" -ForegroundColor Yellow
Run-Remote "curl -s http://localhost:5000/health || echo 'backend health failed'"

Write-Host "\n== API quotes/candles on server ==" -ForegroundColor Yellow
Run-Remote "curl -s http://localhost:5000/api/market/quotes || echo 'quotes failed'"
Run-Remote "curl -s 'http://localhost:5000/api/market/candles?asset=ETH&vs=USD&interval=1h' || echo 'candles failed'"

Write-Host "\n== SSE streams on server (headers only) ==" -ForegroundColor Yellow
Run-Remote "curl -sI -H 'Accept: text/event-stream' http://localhost:5000/api/market/stream/quotes | grep -i content-type || echo 'quotes sse failed'"
Run-Remote "curl -sI -H 'Accept: text/event-stream' 'http://localhost:5000/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m' | grep -i content-type || echo 'candles sse failed'"

Write-Host "\n== Nginx sites-enabled listing ==" -ForegroundColor Yellow
Run-Remote "ls -l /etc/nginx/sites-enabled/"

Write-Host "\n== Nginx test and reload ==" -ForegroundColor Yellow
Run-Remote "nginx -t && systemctl reload nginx || echo 'nginx reload failed'"

Write-Host "\nDone." -ForegroundColor Green
