# Quick Deployment with Secret-Managed Password
# Run these commands manually using the current password from your secret manager

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SpiralCoin Quick Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Password: use the current server password from your secret manager or SPIRALCOIN_SSH_PASSWORD" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Restart Services" -ForegroundColor Green
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'ssh root@174.138.37.6 "cd /root/spiralcoin && docker compose restart && docker compose ps"' -ForegroundColor White
Write-Host ""

Write-Host "Step 2: Deploy Automation" -ForegroundColor Green
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'ssh root@174.138.37.6 "bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)"' -ForegroundColor White
Write-Host ""

Write-Host "Step 3: Verify Installation" -ForegroundColor Green
Write-Host "Command:" -ForegroundColor Yellow
Write-Host 'ssh root@174.138.37.6 "crontab -l && /root/status.sh"' -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running commands now..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Note: PowerShell ssh doesn't support password in command line for security
# User will need to enter password interactively

Read-Host "Press Enter to start deployment (you'll be prompted for password 3 times)" | Out-Null

Write-Host ""
Write-Host "[1/3] Restarting services..." -ForegroundColor Yellow
ssh root@174.138.37.6 "cd /root/spiralcoin && docker compose restart && echo '✅ Services restarted' && docker compose ps"

Write-Host ""
Write-Host "[2/3] Deploying automation..." -ForegroundColor Yellow
ssh root@174.138.37.6 "bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)"

Write-Host ""
Write-Host "[3/3] Verifying installation..." -ForegroundColor Yellow
ssh root@174.138.37.6 "/root/status.sh"

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next: Run .\scripts\quick-status.ps1 daily" -ForegroundColor Cyan
