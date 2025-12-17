# SpiralCoin - Remote SSH Hardening
param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22
)

$ErrorActionPreference = 'Stop'

function Invoke-Remote($cmd){ ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" $cmd }
function Copy-RemoteFile([string]$src,[string]$dst){ & scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$src" "$dst" }

Write-Host "Hardening SSH on $User@$RemoteHost ..." -ForegroundColor Cyan

# Backup sshd_config
Invoke-Remote "cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak-$(date -u +%Y%m%d%H%M%S)"

# Create an override file to avoid risky in-place sed on main config
$override = @'
# SpiralCoin hardening overrides
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes
# Allow root via pubkey only; consider creating a non-root sudo user later
PermitRootLogin prohibit-password
'@

$tmp = New-TemporaryFile
[IO.File]::WriteAllText($tmp.FullName, $override)
Copy-RemoteFile $tmp.FullName ("{0}@{1}:/etc/ssh/sshd_config.d/99-spiralcoin-hardening.conf" -f $User,$RemoteHost)
Remove-Item $tmp -Force

# Test config
Invoke-Remote "sshd -t"

# Reload service safely
try {
  Invoke-Remote "systemctl reload sshd || systemctl reload ssh || service ssh reload"
} catch {
  Write-Warning "Reload failed, attempting restart"
  Invoke-Remote "systemctl restart sshd || systemctl restart ssh || service ssh restart"
}

# Validate that SSH still works using a fresh connection
try {
  Invoke-Remote "echo 'SSH OK after hardening'"
  Write-Host "SSH hardening applied successfully." -ForegroundColor Green
} catch {
  Write-Error "SSH validation failed. Attempting rollback..."
  Invoke-Remote "rm -f /etc/ssh/sshd_config.d/99-spiralcoin-hardening.conf; systemctl reload sshd || systemctl reload ssh || service ssh reload || true"
  throw
}
