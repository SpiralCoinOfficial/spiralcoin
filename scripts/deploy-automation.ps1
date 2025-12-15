# Deploy Automation Scripts to Production Server
# Uploads and executes setup-automation.sh on the production server

param(
    [string]$ServerIP = "174.138.37.6",
    [int]$Port = 22,
    [string]$Username = "root"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SpiralCoin Automation Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if we can reach the server
Write-Host "Testing connection to $ServerIP..." -ForegroundColor Yellow
$connection = Test-NetConnection -ComputerName $ServerIP -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue

if (-not $connection) {
    Write-Host "❌ Cannot reach server on port $Port" -ForegroundColor Red
    Write-Host "Trying alternate port 2222..." -ForegroundColor Yellow
    $connection = Test-NetConnection -ComputerName $ServerIP -Port 2222 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($connection) {
        $Port = 2222
        Write-Host "✅ Connected on port 2222" -ForegroundColor Green
    } else {
        Write-Host "❌ Cannot reach server. Check if it's online." -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Server is reachable" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deploying automation to $Username@$ServerIP..." -ForegroundColor Cyan
Write-Host ""

# Option 1: Direct execution (recommended)
Write-Host "Option 1: Direct Execution (Recommended)" -ForegroundColor Green
Write-Host "Run this command:" -ForegroundColor Yellow
Write-Host ""
if ($Port -eq 22) {
    Write-Host "ssh $Username@$ServerIP `"bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)`"" -ForegroundColor White
} else {
    Write-Host "ssh -p $Port $Username@$ServerIP `"bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)`"" -ForegroundColor White
}
Write-Host ""

# Option 2: Upload and execute
Write-Host "Option 2: Upload Local File" -ForegroundColor Green
Write-Host "If GitHub is not accessible from server, use SCP:" -ForegroundColor Yellow
Write-Host ""
$scriptPath = Join-Path $PSScriptRoot "setup-automation.sh"
if (Test-Path $scriptPath) {
    if ($Port -eq 22) {
        Write-Host "scp `"$scriptPath`" $Username@$ServerIP`:/root/setup-automation.sh" -ForegroundColor White
        Write-Host "ssh $Username@$ServerIP `"bash /root/setup-automation.sh`"" -ForegroundColor White
    } else {
        Write-Host "scp -P $Port `"$scriptPath`" $Username@$ServerIP`:/root/setup-automation.sh" -ForegroundColor White
        Write-Host "ssh -p $Port $Username@$ServerIP `"bash /root/setup-automation.sh`"" -ForegroundColor White
    }
} else {
    Write-Host "❌ setup-automation.sh not found at $scriptPath" -ForegroundColor Red
}
Write-Host ""

# Option 3: Interactive SSH session
Write-Host "Option 3: Manual SSH Connection" -ForegroundColor Green
Write-Host "Connect and run commands manually:" -ForegroundColor Yellow
Write-Host ""
if ($Port -eq 22) {
    Write-Host "ssh $Username@$ServerIP" -ForegroundColor White
} else {
    Write-Host "ssh -p $Port $Username@$ServerIP" -ForegroundColor White
}
Write-Host "Then on server run:" -ForegroundColor Yellow
Write-Host "bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "After Deployment:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Verify automation is running:" -ForegroundColor Yellow
Write-Host "   /root/status.sh" -ForegroundColor White
Write-Host ""
Write-Host "2. Check cron jobs:" -ForegroundColor Yellow
Write-Host "   crontab -l" -ForegroundColor White
Write-Host ""
Write-Host "3. View logs:" -ForegroundColor Yellow
Write-Host "   tail -f /var/log/spiralcoin-backup.log" -ForegroundColor White
Write-Host "   tail -f /var/log/spiralcoin-monitor.log" -ForegroundColor White
Write-Host ""

# Prompt for deployment
Write-Host ""
$response = Read-Host "Would you like to open SSH connection now? (y/n)"
if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Host ""
    Write-Host "Opening SSH connection..." -ForegroundColor Green
    if ($Port -eq 22) {
        ssh "$Username@$ServerIP"
    } else {
        ssh -p $Port "$Username@$ServerIP"
    }
} else {
    Write-Host ""
    Write-Host "Deployment instructions shown above. Run when ready!" -ForegroundColor Green
}
