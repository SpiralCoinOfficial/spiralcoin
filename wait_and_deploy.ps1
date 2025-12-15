# SpiralCoin Server Recovery Monitor
$SERVER = "174.138.37.6"
$SSH_PORTS = @(22, 2222)
$MAX_WAIT = 600

Write-Host "SpiralCoin Server Recovery Monitor" -ForegroundColor Cyan
Write-Host "Waiting for server to come online..." -ForegroundColor Yellow

$startTime = Get-Date
$checkInterval = 5

while ($true) {
    $elapsed = ((Get-Date) - $startTime).TotalSeconds

    if ($elapsed -gt $MAX_WAIT) {
        Write-Host "Timeout: Server offline too long" -ForegroundColor Red
        exit 1
    }

    $onlinePort = $null
    foreach ($p in $SSH_PORTS) {
        $r = Test-NetConnection -ComputerName $SERVER -Port $p -WarningAction SilentlyContinue
        if ($r.TcpTestSucceeded) { $onlinePort = $p; break }
    }

    if ($onlinePort) {
        Write-Host ""
        Write-Host ("SERVER IS ONLINE on port " + $onlinePort) -ForegroundColor Green
        Write-Host "Running deployment..." -ForegroundColor Cyan
        & "$PSScriptRoot\deploy_production.ps1"
        exit 0
    }

    $minutes = [Math]::Floor($elapsed / 60)
    $seconds = [Math]::Floor($elapsed % 60)
    Write-Host "[$minutes :$seconds ] Waiting for SSH (ports: $($SSH_PORTS -join ', '))..." -ForegroundColor Gray

    Start-Sleep -Seconds $checkInterval
}
