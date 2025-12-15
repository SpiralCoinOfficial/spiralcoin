# Helper to add SSH key and run remote commands using password auth
# Usage: ./ssh_auth_helper.ps1 -Server 174.138.37.6 -Password "HarLand2025a" -Command "whoami"

param(
    [string]$Server = "174.138.37.6",
    [string]$User = "root",
    [string]$Password,
    [string]$Command,
    [string]$KeyPath = "$env:USERPROFILE\.ssh\spiralcoin_ed25519"
)

$ErrorActionPreference = 'Stop'

# Try using the SSH key first (if already added)
Write-Host "[$Server] Attempting SSH with key..." -ForegroundColor Cyan
try {
    $result = ssh -i $KeyPath -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "$User@$Server" $Command 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[✓] SSH key auth successful" -ForegroundColor Green
        Write-Host $result
        return
    }
}
catch {
    Write-Host "Key auth failed (expected if key not added yet)" -ForegroundColor Yellow
}

# Fallback: Use password via sshpass if available (Windows with WSL or Git Bash)
$sshpass = Get-Command sshpass -ErrorAction SilentlyContinue
if ($sshpass) {
    Write-Host "[$Server] Using sshpass with password..." -ForegroundColor Cyan
    $env:SSHPASS = $Password
    sshpass -e ssh -o StrictHostKeyChecking=accept-new "$User@$Server" $Command
    return
}

# Fallback: Manual instruction
Write-Host ""
Write-Host "=== MANUAL SETUP REQUIRED ===" -ForegroundColor Red
Write-Host ""
Write-Host "To add the SSH key, paste this into DigitalOcean console:"
Write-Host ""
Write-Host "mkdir -p /root/.ssh"
Write-Host "cat >> /root/.ssh/authorized_keys << 'EOF'"
Get-Content $KeyPath.Replace('.key', '.pub')
Write-Host "EOF"
Write-Host ""
Write-Host "chmod 700 /root/.ssh"
Write-Host "chmod 600 /root/.ssh/authorized_keys"
Write-Host "systemctl restart ssh || systemctl restart sshd"
Write-Host ""
Write-Host "Or run this one-liner (it will prompt for password once):"
Write-Host ""
$pubkey = (Get-Content $KeyPath.Replace('.key', '.pub'))
Write-Host "ssh root@$Server `"mkdir -p /root/.ssh; echo '$pubkey' >> /root/.ssh/authorized_keys; chmod 700 /root/.ssh; chmod 600 /root/.ssh/authorized_keys`""
Write-Host ""
