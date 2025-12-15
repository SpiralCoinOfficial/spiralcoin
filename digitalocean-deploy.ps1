# DigitalOcean SpiralCoin Deployment Script
# This script deploys your SpiralCoin trading platform to DigitalOcean

param(
    [string]$ApiToken,
    [string]$AppName = "spiralcoin",
    [string]$Region = "nyc3"
)

# Get API token from environment variable if not provided
if ([string]::IsNullOrEmpty($ApiToken)) {
    $ApiToken = $env:DIGITALOCEAN_API_TOKEN
    if ([string]::IsNullOrEmpty($ApiToken)) {
        Write-Host "❌ Error: API token not provided!" -ForegroundColor Red
        Write-Host "Usage: .\digitalocean-deploy.ps1 -ApiToken 'your_token_here'" -ForegroundColor Yellow
        Write-Host "Or set environment variable: `$env:DIGITALOCEAN_API_TOKEN = 'your_token'" -ForegroundColor Yellow
        exit 1
    }
}

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting SpiralCoin Deployment to DigitalOcean..." -ForegroundColor Green

# 1. Create Droplet
Write-Host "`n📦 Creating DigitalOcean Droplet..." -ForegroundColor Yellow

$dropletBody = @{
    name = $AppName
    region = $Region
    size = "s-2vcpu-4gb"
    image = "ubuntu-22-04-x64"
    backups = $true
    ipv6 = $true
    user_data = @"
#!/bin/bash
cd /root
apt-get update
apt-get install -y curl git
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs
git clone https://github.com/yourusername/spiralcoin.git
cd spiralcoin
npm install
npm start
"@
    tags = @("spiralcoin", "trading-platform")
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" `
        -Method Post `
        -Headers $headers `
        -Body $dropletBody

    $dropletId = $response.droplet.id
    Write-Host "✅ Droplet created: ID $dropletId" -ForegroundColor Green

    # Wait for droplet to boot
    Write-Host "`n⏳ Waiting for droplet to boot..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Get droplet IP
    $dropletInfo = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$dropletId" `
        -Method Get `
        -Headers $headers

    $ipAddress = $dropletInfo.droplet.networks.v4[0].ip_address
    Write-Host "✅ Droplet IP: $ipAddress" -ForegroundColor Green

    # 2. Create DNS record (requires domain already in DigitalOcean)
    Write-Host "`n🌐 Creating DNS record..." -ForegroundColor Yellow

    $dnsBody = @{
        type = "A"
        name = "spiralcoin"
        data = $ipAddress
        ttl = 3600
    } | ConvertTo-Json

    try {
        $dnsResponse = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/domains/spiralcoin.net/records" `
            -Method Post `
            -Headers $headers `
            -Body $dnsBody
        Write-Host "✅ DNS record created" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ DNS setup skipped (domain needs to be added to DigitalOcean first)" -ForegroundColor Yellow
    }

    Write-Host "`n✨ Deployment Complete!" -ForegroundColor Green
    Write-Host "Your SpiralCoin Trading Platform is now running at: http://$ipAddress" -ForegroundColor Cyan
    Write-Host "Domain: https://spiralcoin.net (once DNS propagates)" -ForegroundColor Cyan

}
catch {
    Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
    exit 1
}
