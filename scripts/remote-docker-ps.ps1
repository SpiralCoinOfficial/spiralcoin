$ErrorActionPreference = 'Stop'
$sshExe = 'ssh'
$sshArgs = @(
	'-o','BatchMode=yes',
	'-o','StrictHostKeyChecking=no',
	'root@174.138.37.6',
	'bash','-lc',
	'cd /root/spiralcoin; if docker compose ps >/dev/null 2>&1; then docker compose ps; elif [ -f docker-compose.prod.yaml ]; then docker compose -f docker-compose.prod.yaml ps; else docker ps; fi'
)
Write-Host "Running: ssh $($sshArgs -join ' ')" -ForegroundColor Cyan
& $sshExe @sshArgs
