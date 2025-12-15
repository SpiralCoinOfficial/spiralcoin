# Quick Status Check for SpiralCoin Production
# Fast check of all critical services

param(
    [string]$ServerIP = "174.138.37.6"
)

$Host.UI.RawUI.WindowTitle = "SpiralCoin Status Monitor"

function Test-Service {
    param($Name, $Port)

    $result = Test-NetConnection -ComputerName $ServerIP -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($result) {
        Write-Host "  ✅ $Name" -ForegroundColor Green -NoNewline
        Write-Host " (port $Port)" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "  ❌ $Name" -ForegroundColor Red -NoNewline
        Write-Host " (port $Port)" -ForegroundColor Gray
        return $false
    }
}

Clear-Host
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin Production Status" -ForegroundColor Cyan
Write-Host "  Server: $ServerIP" -ForegroundColor Gray
Write-Host "  Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "Services:" -ForegroundColor Yellow
$webOK = Test-Service "Web UI" 3000
$backendOK = Test-Service "Backend API" 5000
$rpcOK = Test-Service "RPC Daemon" 8545
$feedOK = Test-Service "MarketFeed" 4000

Write-Host ""
Write-Host "Infrastructure:" -ForegroundColor Yellow
$sshOK = Test-Service "SSH" 22
if (-not $sshOK) {
    $sshOK = Test-Service "SSH (Alt)" 2222
}

Write-Host ""
$totalServices = 4
$runningServices = @($webOK, $backendOK, $rpcOK, $feedOK) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count

if ($runningServices -eq $totalServices) {
    Write-Host "Status: " -NoNewline
    Write-Host "ALL SYSTEMS OPERATIONAL ✅" -ForegroundColor Green
} elseif ($runningServices -ge 2) {
    Write-Host "Status: " -NoNewline
    Write-Host "PARTIAL OUTAGE ⚠️ " -ForegroundColor Yellow -NoNewline
    Write-Host "($runningServices/$totalServices services up)" -ForegroundColor Yellow
} else {
    Write-Host "Status: " -NoNewline
    Write-Host "CRITICAL ❌ " -ForegroundColor Red -NoNewline
    Write-Host "($runningServices/$totalServices services up)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Quick Actions:" -ForegroundColor Yellow
Write-Host "  SSH to server:  " -NoNewline -ForegroundColor Gray
Write-Host "ssh root@$ServerIP" -ForegroundColor White
Write-Host "  Check logs:     " -NoNewline -ForegroundColor Gray
Write-Host "docker compose logs -f" -ForegroundColor White
Write-Host "  Restart:        " -NoNewline -ForegroundColor Gray
Write-Host "docker compose restart" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
