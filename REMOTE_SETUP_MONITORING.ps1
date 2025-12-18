# SpiralCoin - Remote Monitoring Setup
# Copies health check script to droplet and installs nightly cron.
param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22,
  [string]$RemoteDir = "/root/spiralcoin/scripts",
  [string]$CronSpec = "0 3 * * *"  # nightly at 03:00 UTC
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $root 'scripts/remote_health_check.sh'
if (-not (Test-Path $scriptPath)) { throw "Missing script: $scriptPath" }

Write-Host "Setting up monitoring on $User@$RemoteHost ..." -ForegroundColor Cyan

# Ensure directory and copy script
ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" "mkdir -p $RemoteDir && chmod 755 $RemoteDir"
$remoteTarget = "${User}@${RemoteHost}:$RemoteDir/remote_health_check.sh"
scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$scriptPath" "$remoteTarget"
ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" "chmod +x $RemoteDir/remote_health_check.sh"

# Install cron (system-wide file under /etc/cron.d)
$cronFile = "/etc/cron.d/spiralcoin-health"
$line = "$CronSpec root $RemoteDir/remote_health_check.sh >> /var/log/spiralcoin-health.log 2>&1"
ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" "echo '$line' > $cronFile && chmod 644 $cronFile && systemctl restart cron || systemctl restart crond || true"

# Run once immediately
Write-Host "Running health check once now..." -ForegroundColor Cyan
ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" "$RemoteDir/remote_health_check.sh"

Write-Host "Monitoring setup complete. Tail log with: tail -n 100 /var/log/spiralcoin-health.log" -ForegroundColor Green
