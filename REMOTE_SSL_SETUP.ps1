# SpiralCoin - Remote SSL Setup (Let's Encrypt via Certbot)
# Requires domain DNS pointing to the server and nginx serving the site.

param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22,
  [string]$Domain = "spiralcoin.net",
  [string]$Email = "admin@spiralcoin.net"
)

$ErrorActionPreference = 'Continue'

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Remote SSL Setup" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan

function Invoke-Remote {
  param([string]$Cmd)
  ssh -p $Port "$User@$RemoteHost" $Cmd
}

try {
  Write-Host "[STEP] Installing Certbot (snap or apt)" -ForegroundColor Cyan
  Invoke-Remote "command -v snap && sudo snap install core; sudo snap refresh core || true"
  Invoke-Remote "sudo snap install --classic certbot || sudo apt-get update && sudo apt-get install -y certbot python3-certbot-nginx"

  Write-Host "[STEP] Obtaining certificate for $Domain" -ForegroundColor Cyan
  Invoke-Remote "sudo certbot --nginx -d $Domain --non-interactive --agree-tos -m $Email || sudo certbot certonly --nginx -d $Domain --non-interactive --agree-tos -m $Email"

  Write-Host "[STEP] Enabling auto-renewal" -ForegroundColor Cyan
  Invoke-Remote "sudo systemctl enable snap.certbot.renew.timer || true; sudo systemctl start snap.certbot.renew.timer || true"

  Write-Host "[OK] SSL setup complete. nginx should be reloaded by certbot." -ForegroundColor Green
} catch {
  Write-Host "[WARN] SSL setup encountered an issue: $($_.Exception.Message)" -ForegroundColor Yellow
  Write-Host "[HINT] Ensure DNS A record for $Domain points to ${RemoteHost} and nginx is running." -ForegroundColor Yellow
}

exit 0
