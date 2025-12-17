param(
    [string]$ZipPath = "",
    [string]$Remote = "root@174.138.37.6",
    [string]$RemoteDir = "/root/spiralcoin/exchange-pack"
)

$ErrorActionPreference = "Stop"

# Resolve workspace root
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $root "build"

if (-not $ZipPath) {
    $ZipPath = Join-Path $buildDir "SpiralCoin-Exchange-Pack.zip"
}

if (-not (Test-Path $ZipPath)) {
    throw "Zip not found at: $ZipPath. Run MAKE_EXCHANGE_PACK.ps1 first."
}

# Ensure scp exists
$scp = Get-Command scp -ErrorAction SilentlyContinue
if (-not $scp) {
    throw "scp not found. Install Windows OpenSSH client or use 'Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0'"
}

Write-Host "Uploading $ZipPath to $Remote:$RemoteDir" -ForegroundColor Cyan

# Create remote directory and upload
$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $ssh) {
    throw "ssh not found. Install Windows OpenSSH client."
}

# Create remote dir
ssh $Remote "mkdir -p $RemoteDir" | Out-Null

# Upload
scp $ZipPath "$Remote:$RemoteDir/" | Out-Null

Write-Host "Upload complete: $Remote:$RemoteDir/$(Split-Path $ZipPath -Leaf)" -ForegroundColor Green
