<#
SpiralCoin - Upload SSH Public Key to Remote
Safely installs your local SSH public key on the remote server's authorized_keys
for passwordless login. Prompts once for your password (no storing), then future
SSH/SCP will be key-based.
#>

param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22,
  [string]$PublicKeyPath = ""
)

$ErrorActionPreference = 'Stop'

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Upload SSH Key" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan

# Ensure OpenSSH client exists
$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $ssh) {
  Write-Host "[ERROR] ssh not found. Install OpenSSH Client:" -ForegroundColor Red
  Write-Host "        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0" -ForegroundColor Yellow
  exit 1
}

# Resolve a public key to use: prefer ed25519, fallback to rsa; else generate ed25519
if (-not $PublicKeyPath -or -not (Test-Path $PublicKeyPath)) {
  $ed25519 = Join-Path $HOME ".ssh/id_ed25519.pub"
  $rsa     = Join-Path $HOME ".ssh/id_rsa.pub"
  if (Test-Path $ed25519) {
    $PublicKeyPath = $ed25519
  } elseif (Test-Path $rsa) {
    $PublicKeyPath = $rsa
  } else {
    Write-Host "[STEP] No public key found. Generating ed25519 keypair..." -ForegroundColor Cyan
    $keyDir = Join-Path $HOME ".ssh"
    if (-not (Test-Path $keyDir)) { New-Item -ItemType Directory -Path $keyDir | Out-Null }
    & ssh-keygen -t ed25519 -N "" -C "$env:USERNAME@$env:COMPUTERNAME" -f (Join-Path $keyDir "id_ed25519") | Out-Null
    $PublicKeyPath = Join-Path $keyDir "id_ed25519.pub"
  }
}

if (-not (Test-Path $PublicKeyPath)) {
  Write-Host "[ERROR] Public key not found: $PublicKeyPath" -ForegroundColor Red
  exit 1
}

Write-Host "[INFO] Using public key: $PublicKeyPath" -ForegroundColor Green

# Upload public key to remote authorized_keys securely (prefers scp, falls back to pipe)
try {
  $remote = "$User@$RemoteHost"
  $pubKeyContent = Get-Content -Path $PublicKeyPath -Raw
  if (-not $pubKeyContent) { throw "Empty public key content" }

  Write-Host "[STEP] Uploading key to $remote (port $Port). You may be prompted for password once." -ForegroundColor Cyan

  $scp = Get-Command scp -ErrorAction SilentlyContinue
  if ($scp) {
    # Safer path: copy the key file, then append remotely and clean up
    $tmpRemote = "~/.ssh/spiralcoin.tmp.pub"
    & $scp.Source -P $Port -o StrictHostKeyChecking=no $PublicKeyPath "$remote:$tmpRemote"
    if ($LASTEXITCODE -ne 0) { throw "scp exited $LASTEXITCODE" }
    $remoteCmd = "umask 077; mkdir -p ~/.ssh; cat $tmpRemote >> ~/.ssh/authorized_keys; rm -f $tmpRemote; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
    & $ssh.Source -p $Port -o StrictHostKeyChecking=no $remote $remoteCmd
    if ($LASTEXITCODE -ne 0) { throw "ssh exited $LASTEXITCODE while appending key" }
  } else {
    # Fallback: pipe the key content
    $remoteCmd = "umask 077; mkdir -p ~/.ssh; cat >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
    $pubKeyContent | & $ssh.Source -p $Port -o StrictHostKeyChecking=no $remote $remoteCmd
    if ($LASTEXITCODE -ne 0) { throw "ssh exited $LASTEXITCODE while piping key" }
  }

  Write-Host "[OK] Key uploaded. Testing passwordless SSH..." -ForegroundColor Green
  # Test passwordless (non-interactive) now
  $test = & $ssh.Source -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no $remote "echo ok" 2>&1
  if ($LASTEXITCODE -eq 0 -and $test -match "ok") {
    Write-Host "[OK] Passwordless SSH works." -ForegroundColor Green
    exit 0
  } else {
    Write-Host "[WARN] Passwordless test did not succeed yet." -ForegroundColor Yellow
    Write-Host "       You may need to reconnect or ensure PermitRootLogin yes and PubkeyAuthentication yes on remote." -ForegroundColor Yellow
    exit 0
  }
}
catch {
  Write-Host "[ERROR] SSH key upload failed: $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "[HINT] Ensure the password you enter is correct, and SSH is enabled for $User on ${RemoteHost}:$Port." -ForegroundColor Yellow
  exit 1
}
