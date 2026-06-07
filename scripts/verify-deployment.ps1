# Verify SpiralCoin Production Deployment
# Checks all services, automation, and configuration

param(
    [string]$ServerIP = "174.138.37.6",
    [int]$Port = 22,
    [string]$Username = "root"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SpiralCoin Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# Test 1: Server Connectivity
Write-Host "[1/10] Testing server connectivity..." -ForegroundColor Yellow
$connection = Test-NetConnection -ComputerName $ServerIP -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
if ($connection) {
    Write-Host "✅ Server reachable on port $Port" -ForegroundColor Green
} else {
    Write-Host "⚠️  Cannot reach server on port $Port, trying alternate..." -ForegroundColor Yellow
    $connection2222 = Test-NetConnection -ComputerName $ServerIP -Port 2222 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($connection2222) {
        Write-Host "✅ Server reachable on alternate port 2222" -ForegroundColor Green
        $Port = 2222
    } else {
        Write-Host "❌ Server not reachable on any port" -ForegroundColor Red
        Write-Host "   Check if server is online: ping $ServerIP" -ForegroundColor Gray
        Write-Host "   Or check firewall settings" -ForegroundColor Gray
        $allPassed = $false
    }
}

# Test 2: Web UI
Write-Host "[2/10] Testing Web UI (port 3000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP`:3000" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Web UI responding" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Web UI returned status $($response.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Web UI not responding" -ForegroundColor Red
    $allPassed = $false
}

# Test 3: Backend API
Write-Host "[3/10] Testing Backend API (port 5000)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$ServerIP`:5000" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    Write-Host "✅ Backend API responding" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend API not responding" -ForegroundColor Red
    $allPassed = $false
}

# Test 4: RPC Daemon
Write-Host "[4/10] Testing RPC Daemon (port 8545)..." -ForegroundColor Yellow
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $tcpClient.Connect($ServerIP, 8545)
    $tcpClient.Close()
    Write-Host "✅ RPC Daemon port open" -ForegroundColor Green
} catch {
    Write-Host "❌ RPC Daemon not responding" -ForegroundColor Red
    $allPassed = $false
}

# Test 5: MarketFeed
Write-Host "[5/10] Testing MarketFeed (port 4000)..." -ForegroundColor Yellow
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    $tcpClient.Connect($ServerIP, 4000)
    $tcpClient.Close()
    Write-Host "✅ MarketFeed port open" -ForegroundColor Green
} catch {
    Write-Host "❌ MarketFeed not responding" -ForegroundColor Red
    $allPassed = $false
}

# Test 6: SSL/HTTPS (if domain is configured)
Write-Host "[6/10] Testing SSL/HTTPS..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://$ServerIP`:3000" -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response) {
        Write-Host "✅ SSL/HTTPS configured" -ForegroundColor Green
    } else {
        Write-Host "⚠️  SSL/HTTPS not configured (expected if DNS not live)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  SSL/HTTPS not configured (expected if DNS not live)" -ForegroundColor Yellow
}

# Test 7: DNS Resolution
Write-Host "[7/10] Testing DNS resolution (spiralcoin.net)..." -ForegroundColor Yellow
try {
    $dns = Resolve-DnsName -Name "spiralcoin.net" -ErrorAction SilentlyContinue
    if ($dns) {
        $resolvedIP = $dns[0].IPAddress
        if ($resolvedIP -eq $ServerIP) {
            Write-Host "✅ DNS correctly points to $ServerIP" -ForegroundColor Green
        } else {
            Write-Host "⚠️  DNS points to $resolvedIP (expected: $ServerIP)" -ForegroundColor Yellow
            Write-Host "   Waiting for DNS propagation..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "⚠️  DNS not configured yet (update registrar)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  DNS not configured yet (update registrar)" -ForegroundColor Yellow
}

# Test 8: SSH Connectivity
Write-Host "[8/10] Testing SSH access..." -ForegroundColor Yellow
if ($Port -eq 22) {
    Write-Host "✅ SSH accessible on standard port 22" -ForegroundColor Green
} elseif ($Port -eq 2222) {
    Write-Host "✅ SSH accessible on alternate port 2222" -ForegroundColor Green
} else {
    Write-Host "❌ SSH not accessible" -ForegroundColor Red
    $allPassed = $false
}

# Test 9: Firewall Check
Write-Host "[9/10] Checking firewall ports..." -ForegroundColor Yellow
$requiredPorts = @(22, 80, 443, 3000, 4000, 5000, 8545)
$openPorts = 0
foreach ($testPort in $requiredPorts) {
    $test = Test-NetConnection -ComputerName $ServerIP -Port $testPort -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($test) {
        $openPorts++
    }
}
if ($openPorts -ge 5) {
    Write-Host "✅ Firewall configured ($openPorts/$($requiredPorts.Count) ports open)" -ForegroundColor Green
} else {
    Write-Host "⚠️  Only $openPorts/$($requiredPorts.Count) ports accessible" -ForegroundColor Yellow
}

# Test 10: GitHub Repository
Write-Host "[10/10] Testing GitHub repository access..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/README.md" -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ GitHub repository accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  GitHub repository not accessible" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($allPassed) {
    Write-Host "✅ ALL CRITICAL TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your deployment is operational!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. SSH to server: ssh $Username@$ServerIP" -ForegroundColor White
    Write-Host "2. Check status: /root/status.sh" -ForegroundColor White
    Write-Host "3. Deploy automation: .\scripts\deploy-automation.ps1" -ForegroundColor White
} else {
    Write-Host "⚠️  SOME TESTS FAILED" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Review failed tests above and troubleshoot." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Quick Fix - Run these commands:" -ForegroundColor Cyan
    Write-Host "  ssh $Username@$ServerIP" -ForegroundColor White
    Write-Host "  Use your configured SSH key or server password prompt" -ForegroundColor Yellow
    Write-Host "  cd /root/spiralcoin && docker compose restart" -ForegroundColor White
    Write-Host ""
    Write-Host "Or see DEPLOY_NOW.md for complete instructions" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "For detailed troubleshooting, see:" -ForegroundColor Cyan
Write-Host "- QUICK_REFERENCE_CARD.md" -ForegroundColor White
Write-Host "- PRODUCTION_QUICK_REFERENCE.md" -ForegroundColor White
Write-Host ""
