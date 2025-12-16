# SpiralCoin Deployment Fix - PowerShell Compatible
# This script diagnoses connection issues and deploys with proper Windows syntax

param(
    [string]$ServerIP = "174.138.37.6",
    [string]$Username = "root",
    [string]$Password = "HarLand2025!"
)

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SPIRALCOIN DEPLOYMENT FIX & DIAGNOSTICS" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Test basic connectivity
Write-Host "Step 1: Testing server connectivity..." -ForegroundColor Yellow
Write-Host ""

# Ping test
Write-Host "  [1/4] Ping test..." -NoNewline
$pingResult = Test-Connection -ComputerName $ServerIP -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($pingResult) {
    Write-Host " ✅ Server responds to ping" -ForegroundColor Green
} else {
    Write-Host " ❌ Server not responding to ping" -ForegroundColor Red
    Write-Host "        This usually means the server is offline or blocked by firewall" -ForegroundColor Gray
}

# Port 22 test
Write-Host "  [2/4] SSH port 22 test..." -NoNewline
$port22 = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($port22.TcpTestSucceeded) {
    Write-Host " ✅ Port 22 open" -ForegroundColor Green
} else {
    Write-Host " ❌ Port 22 closed or filtered" -ForegroundColor Red
    Write-Host "        SSH service may be down or firewall blocking" -ForegroundColor Gray
}

# Port 2222 test (alternate SSH)
Write-Host "  [3/4] Alternate SSH port 2222 test..." -NoNewline
$port2222 = Test-NetConnection -ComputerName $ServerIP -Port 2222 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
if ($port2222.TcpTestSucceeded) {
    Write-Host " ✅ Port 2222 open" -ForegroundColor Green
} else {
    Write-Host " ⚠️ Port 2222 not available" -ForegroundColor Yellow
}

# Web services test
Write-Host "  [4/4] Web services test..." -NoNewline
try {
    $webTest = Invoke-WebRequest -Uri "http://$ServerIP`:3000" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
    Write-Host " ✅ Web service responding" -ForegroundColor Green
} catch {
    Write-Host " ❌ Web services not responding" -ForegroundColor Red
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Determine if we can proceed
$canConnect = $port22.TcpTestSucceeded -or $port2222.TcpTestSucceeded

if (-not $canConnect) {
    Write-Host ""
    Write-Host "❌ CRITICAL: Cannot connect to server!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Yellow
    Write-Host "  1. Server is powered off or rebooting" -ForegroundColor White
    Write-Host "  2. DigitalOcean droplet was deleted/stopped" -ForegroundColor White
    Write-Host "  3. Firewall blocking SSH (port 22)" -ForegroundColor White
    Write-Host "  4. IP address changed" -ForegroundColor White
    Write-Host ""
    Write-Host "Immediate actions:" -ForegroundColor Cyan
    Write-Host "  → Log into DigitalOcean dashboard: https://cloud.digitalocean.com" -ForegroundColor White
    Write-Host "  → Check if droplet is running" -ForegroundColor White
    Write-Host "  → Verify IP address is still $ServerIP" -ForegroundColor White
    Write-Host "  → Check firewall rules allow SSH (port 22)" -ForegroundColor White
    Write-Host "  → Try accessing the Droplet Console from DigitalOcean dashboard" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "✅ Server is reachable! Ready to deploy." -ForegroundColor Green
Write-Host ""

# Step 2: Generate deployment commands
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMMANDS (PowerShell Compatible)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option A: Interactive SSH Session (RECOMMENDED)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Run this command:" -ForegroundColor Cyan
Write-Host "  ssh $Username@$ServerIP" -ForegroundColor White
Write-Host ""
Write-Host "When prompted for password, enter: $Password" -ForegroundColor Yellow
Write-Host ""
Write-Host "Then run these commands ONE AT A TIME in the SSH session:" -ForegroundColor Cyan
Write-Host ""
Write-Host '  1) cd /root/spiralcoin && docker compose restart && docker compose ps' -ForegroundColor White
Write-Host '  2) bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)' -ForegroundColor White
Write-Host '  3) /root/status.sh' -ForegroundColor White
Write-Host ""

Write-Host "Option B: Single-Line Commands (if SSH works)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "Command 1 - Restart services:" -ForegroundColor Cyan
Write-Host '  ssh $Username@$ServerIP "cd /root/spiralcoin && docker compose restart && docker compose ps"' -ForegroundColor White
Write-Host ""
Write-Host "Command 2 - Deploy automation:" -ForegroundColor Cyan
Write-Host '  ssh $Username@$ServerIP "bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)"' -ForegroundColor White
Write-Host ""
Write-Host "Command 3 - Verify:" -ForegroundColor Cyan
Write-Host '  ssh $Username@$ServerIP "/root/status.sh"' -ForegroundColor White
Write-Host ""

Write-Host "Option C: Use PuTTY (Windows-native SSH)" -ForegroundColor Yellow
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host ""
Write-Host "1. Download PuTTY: https://www.putty.org/" -ForegroundColor White
Write-Host "2. Open PuTTY and enter:" -ForegroundColor White
Write-Host "   Host: $ServerIP" -ForegroundColor White
Write-Host "   Port: 22" -ForegroundColor White
Write-Host "3. Click 'Open' and login with:" -ForegroundColor White
Write-Host "   Username: $Username" -ForegroundColor White
Write-Host "   Password: $Password" -ForegroundColor White
Write-Host "4. Run the commands from Option A" -ForegroundColor White
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 3: Offer to copy first command to clipboard
Write-Host "📋 Quick Action: Copy SSH command to clipboard?" -ForegroundColor Yellow
Write-Host "   Press Y to copy 'ssh $Username@$ServerIP' to clipboard" -ForegroundColor Gray
Write-Host "   Press any other key to exit" -ForegroundColor Gray
Write-Host ""

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
if ($key.Character -eq 'y' -or $key.Character -eq 'Y') {
    "ssh $Username@$ServerIP" | Set-Clipboard
    Write-Host ""
    Write-Host "✅ Copied to clipboard! Paste into terminal and press Enter." -ForegroundColor Green
    Write-Host "   When prompted for password, enter: $Password" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Done! Follow the commands above to complete deployment." -ForegroundColor Green
