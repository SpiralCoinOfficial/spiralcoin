# SpiralCoin - Windows OpenSSH dual-port setup (22 and 2222)
# Run in elevated PowerShell (Run as Administrator)

$ErrorActionPreference = 'Stop'

Write-Host '=== SpiralCoin: Windows OpenSSH Setup ===' -ForegroundColor Cyan

# 1) Install OpenSSH Server if missing
$cap = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'OpenSSH.Server*' }
if ($cap.State -ne 'Installed') {
  Write-Host '[*] Installing OpenSSH Server capability...' -ForegroundColor Yellow
  Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null
}

# 2) Ensure services are enabled
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd
Set-Service -Name ssh-agent -StartupType Automatic
Start-Service ssh-agent

# 3) Configure sshd_config to listen on 22 and 2222; enable password auth
$cfgPath = Join-Path $env:ProgramData 'ssh\sshd_config'
$backup = "$cfgPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
if (Test-Path $cfgPath) { Copy-Item $cfgPath $backup }

$content = Get-Content $cfgPath -ErrorAction SilentlyContinue
if (-not $content) { $content = @() }

# Remove existing Port lines
$content = $content | Where-Object { $_ -notmatch '^\s*Port\s+' }

# Ensure dual ports and auth settings
$add = @(
  'Port 22',
  'Port 2222',
  'PasswordAuthentication yes',
  'PubkeyAuthentication yes',
  'ChallengeResponseAuthentication no',
  'UsePAM no'
)

foreach ($line in $add) {
  if (-not ($content -match "^\s*${line.Replace(' ','\s+')}\s*$")) {
    $content += $line
  }
}

Set-Content -Path $cfgPath -Value $content -Encoding ascii

# 4) Open firewall ports
$rules = @(
  @{ Name='OpenSSH-Server-In-TCP-22'; Port=22 },
  @{ Name='OpenSSH-Server-In-TCP-2222'; Port=2222 }
)
foreach ($r in $rules) {
  if (-not (Get-NetFirewallRule -DisplayName $r.Name -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $r.Name -Direction Inbound -Protocol TCP -LocalPort $r.Port -Action Allow -Profile Any | Out-Null
  }
}

# 5) Restart and validate
Restart-Service sshd
Start-Sleep -Seconds 1

$ok22 = (Test-NetConnection -ComputerName '127.0.0.1' -Port 22).TcpTestSucceeded
$ok2222 = (Test-NetConnection -ComputerName '127.0.0.1' -Port 2222).TcpTestSucceeded

if ($ok22 -or $ok2222) {
  Write-Host ('SSH listening - 22: ' + $ok22 + ', 2222: ' + $ok2222) -ForegroundColor Green
  Write-Host 'Done.' -ForegroundColor Green
} else {
  Write-Host 'SSH not listening; check Event Viewer logs for sshd.' -ForegroundColor Red
}
