#!/usr/bin/env pwsh

param(
    [string]$ServerIP = "174.138.37.6",
    [string]$SshUser = "root",
    [int]$MaxRetries = 30,
    [int]$RetryDelaySeconds = 10
)

$ErrorActionPreference = "Continue"

Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SpiralCoin Automatic Production Deployment          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Waiting for SSH access on $ServerIP..." -ForegroundColor Yellow
Write-Host "Trying ports 22 and 2222..." -ForegroundColor Gray
Write-Host ""

$sshReady = $false
$sshPort = 22
$attempts = 0

while ($attempts -lt $MaxRetries) {
    $attempts++
    Write-Host "  Attempt $attempts/$MaxRetries" -ForegroundColor Gray -NoNewline

    $result22 = Test-NetConnection -ComputerName $ServerIP -Port 22 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($result22.TcpTestSucceeded) {
        Write-Host " SSH port 22 responding!" -ForegroundColor Green
        $sshReady = $true
        $sshPort = 22
        break
    }

    $result2222 = Test-NetConnection -ComputerName $ServerIP -Port 2222 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($result2222.TcpTestSucceeded) {
        Write-Host " SSH port 2222 responding!" -ForegroundColor Green
        $sshReady = $true
        $sshPort = 2222
        break
    }

    Write-Host " (waiting...)" -ForegroundColor Gray
    Start-Sleep -Seconds $RetryDelaySeconds
}

if (-not $sshReady) {
    Write-Host ""
    Write-Host "ERROR: SSH not available after $($MaxRetries * $RetryDelaySeconds) seconds" -ForegroundColor Red
    Write-Host "Server may still be starting." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "SSH is ready on port $sshPort" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Running recovery script on server..." -ForegroundColor Yellow
Write-Host "Installing Docker, configuring SSH, and deploying services..." -ForegroundColor Gray
Write-Host ""

try {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $sshPort "${SshUser}@${ServerIP}" "bash -c 'curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/recovery-all.sh | bash'" 2>&1 | ForEach-Object {
        Write-Host "  $($_)"
    }
    $scriptSuccess = $true
}
catch {
    Write-Host "Error running recovery script: $($_.Exception.Message)" -ForegroundColor Yellow
    $scriptSuccess = $false
}

Write-Host ""
Write-Host "Step 3: Verifying services..." -ForegroundColor Yellow
Write-Host ""

$services = @(
    @{ Name = "Web UI"; Port = 3000 },
    @{ Name = "Backend API"; Port = 5000 },
    @{ Name = "RPC Daemon"; Port = 8545 },
    @{ Name = "MarketFeed"; Port = 4000 }
)

foreach ($service in $services) {
    $testConn = Test-NetConnection -ComputerName $ServerIP -Port $service.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    if ($testConn.TcpTestSucceeded) {
        Write-Host "  OK: $($service.Name) - Port $($service.Port)" -ForegroundColor Green
    } else {
        Write-Host "  PENDING: $($service.Name) - Port $($service.Port) (still starting)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 4: Checking Docker status..." -ForegroundColor Yellow
Write-Host ""

try {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $sshPort "${SshUser}@${ServerIP}" "cd /root/spiralcoin; docker compose ps" 2>&1 | ForEach-Object {
        Write-Host "  $_"
    }
}
catch {
    Write-Host "  Could not retrieve container status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║            DEPLOYMENT AUTOMATION COMPLETE             ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "SpiralCoin server is being set up!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Services may take 1-2 more minutes to fully start" -ForegroundColor Gray
Write-Host "  2. SSH access: ssh root@$ServerIP -p $sshPort" -ForegroundColor White
Write-Host "  3. View logs: docker compose logs -f" -ForegroundColor White
Write-Host "  4. Update DNS: spiralcoin.net A record to $ServerIP" -ForegroundColor White
Write-Host ""
Write-Host "Service URLs:" -ForegroundColor Cyan
Write-Host "  Web UI:     http://$ServerIP`:3000" -ForegroundColor White
Write-Host "  Backend:    http://$ServerIP`:5000/health" -ForegroundColor White
Write-Host "  RPC:        http://$ServerIP`:8545" -ForegroundColor White
Write-Host "  MarketFeed: http://$ServerIP`:4000" -ForegroundColor White
Write-Host ""
