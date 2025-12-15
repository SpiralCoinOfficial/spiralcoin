# SpiralCoin - Complete Local Production Deployment & Verification
# Run this to poll for server, deploy, and verify everything

param(
    [string]$Server = "174.138.37.6",
    [int]$PollIntervalSeconds = 10,
    [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
$startTime = Get-Date
$sshPorts = @(22, 2222)

function Write-Status {
    param([string]$msg, [string]$color = 'Cyan')
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Test-SSH {
    param([int]$port)
    $r = Test-NetConnection -ComputerName $Server -Port $port -WarningAction SilentlyContinue
    return $r.TcpTestSucceeded
}

function Get-WorkingSSHPort {
    foreach ($p in $sshPorts) {
        if (Test-SSH $p) { return $p }
    }
    return $null
}

function Run-SSH {
    param([int]$port, [string]$cmd)
    ssh -p $port -o StrictHostKeyChecking=no root@$Server $cmd 2>&1
}

Write-Status "=== SpiralCoin Production Deployment ===" 'Cyan'

# ========== PHASE 1: WAIT FOR SSH ==========
Write-Status "Phase 1: Waiting for SSH to become available..." 'Yellow'
$sshPort = $null
while ($sshPort -eq $null -and ((Get-Date) - $startTime).TotalSeconds -lt $TimeoutSeconds) {
    $sshPort = Get-WorkingSSHPort
    if ($sshPort) {
        Write-Status "SSH is ONLINE on port $sshPort" 'Green'
        break
    }
    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
    Write-Status "Waiting... ($elapsed/$TimeoutSeconds sec, trying ports: $($sshPorts -join ','))" 'Gray'
    Start-Sleep -Seconds $PollIntervalSeconds
}

if (-not $sshPort) {
    Write-Status "TIMEOUT: SSH not available after $TimeoutSeconds seconds" 'Red'
    exit 1
}

# ========== PHASE 2: VERIFY SYSTEM & RUN RECOVERY ==========
Write-Status "Phase 2: Verifying system and running recovery script..." 'Yellow'

$recoveryScript = @'
bash /root/spiralcoin/scripts/recovery-all.sh
'@

try {
    Run-SSH $sshPort $recoveryScript | ForEach-Object { Write-Host $_ }
} catch {
    Write-Status "Recovery script error: $_" 'Red'
    exit 1
}

Write-Status "Recovery script completed" 'Green'

# ========== PHASE 3: LOCAL VERIFICATION ==========
Write-Status "Phase 3: Verifying services from local machine..." 'Yellow'
Start-Sleep -Seconds 5

$ports = @{
    '8545' = 'RPC Daemon'
    '5000' = 'Backend API'
    '4000' = 'MarketFeed'
    '3000' = 'Web UI'
    '22'   = 'SSH'
    '2222' = 'SSH (backup)'
}

$results = @()
foreach ($p in @('22','2222','8545','5000','4000','3000')) {
    $r = Test-NetConnection -ComputerName $Server -Port $p -WarningAction SilentlyContinue
    $status = if ($r.TcpTestSucceeded) { 'OPEN' } else { 'CLOSED' }
    $color = if ($r.TcpTestSucceeded) { 'Green' } else { 'Red' }
    Write-Status ("Port {0}: {1} ({2})" -f $p, $status, $ports[$p]) $color
    $results += @{ port = $p; status = $status; name = $ports[$p] }
}

# ========== PHASE 4: DOCKER STATUS ==========
Write-Status "Phase 4: Docker and service status..." 'Yellow'
$dockerStatus = Run-SSH $sshPort "cd /root/spiralcoin && docker compose ps" | Out-String
Write-Host $dockerStatus

# ========== PHASE 5: SERVICE HEALTH CHECKS ==========
Write-Status "Phase 5: HTTP health checks..." 'Yellow'
$services = @(
    @{ url = "http://$Server`:8545"; name = 'RPC' },
    @{ url = "http://$Server`:5000/health"; name = 'Backend' },
    @{ url = "http://$Server`:4000/api/feed"; name = 'MarketFeed' },
    @{ url = "http://$Server`:3000"; name = 'Web UI' }
)

foreach ($svc in $services) {
    try {
        $null = Invoke-WebRequest -Uri $svc.url -TimeoutSec 5 -UseBasicParsing -WarningAction SilentlyContinue
        Write-Status ("HTTP {0}: OK" -f $svc.name) 'Green'
    } catch {
        Write-Status ("HTTP {0}: NOT RESPONDING (may be starting)" -f $svc.name) 'Yellow'
    }
}

# ========== FINAL SUMMARY ==========
Write-Status "=== DEPLOYMENT COMPLETE ===" 'Cyan'
Write-Host ""
Write-Host "Access your SpiralCoin services:" -ForegroundColor Cyan
Write-Host "  Web Dashboard:  http://$Server`:3000" -ForegroundColor White
Write-Host "  RPC API:        http://$Server`:8545" -ForegroundColor White
Write-Host "  Backend API:    http://$Server`:5000" -ForegroundColor White
Write-Host "  MarketFeed:     http://$Server`:4000" -ForegroundColor White
Write-Host ""
Write-Host "SSH Access:" -ForegroundColor Cyan
Write-Host "  ssh -p $sshPort root@$Server" -ForegroundColor White
Write-Host ""
Write-Host "Check logs:" -ForegroundColor Cyan
Write-Host "  ssh -p $sshPort root@$Server 'cd /root/spiralcoin && docker compose logs -f'" -ForegroundColor White
Write-Host ""
