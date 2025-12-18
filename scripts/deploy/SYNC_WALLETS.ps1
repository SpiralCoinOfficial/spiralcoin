Param(
  [string]$Server = 'root@174.138.37.6',
  [string]$HostName = 'spiralcoin.net',
  [string]$LocalWallets = (Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) '..') 'data/wallets.json'),
  [string]$Addresses = '',  # optional comma-separated list to verify
  [long]$Min = 22000000000000
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $LocalWallets)) {
  Write-Error "Local wallets file not found: $LocalWallets"
}

$RemoteDir = '/root/spiralcoin/data'
$RemoteFile = "$RemoteDir/wallets.json"
$BackupName = "wallets.json.bak-$(Get-Date -UFormat %Y%m%d-%H%M%S)"
$RepoRoot = Resolve-Path (Join-Path (Join-Path $PSScriptRoot '..') '..')
$LocalInclude = Join-Path $RepoRoot 'include'
$LocalSrc = Join-Path $RepoRoot 'src'

Write-Host "[1/4] Backing up remote wallets.json..." -ForegroundColor Cyan
$backupCmd = "mkdir -p $RemoteDir; if [ -f $RemoteFile ]; then cp $RemoteFile $RemoteDir/$BackupName; fi"
ssh $Server $backupCmd

Write-Host "[2/4] Stopping daemon and uploading local wallets.json..." -ForegroundColor Cyan
$stopCmd = "cd /root/spiralcoin; docker compose stop daemon || docker-compose stop daemon"
ssh $Server $stopCmd
scp "$LocalWallets" "${Server}:$RemoteFile"

Write-Host "[2b/4] Syncing daemon source (include/, src/)..." -ForegroundColor Cyan
scp -r "$LocalInclude" "${Server}:/root/spiralcoin/"
scp -r "$LocalSrc" "${Server}:/root/spiralcoin/"

Write-Host "[3/4] Restarting daemon to reload state..." -ForegroundColor Cyan
$restartCmd = "cd /root/spiralcoin; docker compose up -d --build daemon || docker-compose up -d --build daemon; sleep 1"
ssh $Server $restartCmd

Write-Host "[4/4] Verifying supply totals..." -ForegroundColor Cyan
$verifyUrl = "https://$HostName/api/wallet/verify-supply"
if ($Addresses -or $Min) {
  $qs = @()
  if ($Addresses) { $qs += "addresses=$Addresses" }
  if ($Min) { $qs += "min=$Min" }
  $verifyUrl = $verifyUrl + '?' + ($qs -join '&')
}
ssh $Server "curl -s $verifyUrl | sed -e 's/{/{\n/g' -e 's/,/\n/g' | head -n 50"

Write-Host "Done." -ForegroundColor Green
