param(
    [string]$ApiToken,
    [string]$AppName = "spiralcoin",
    [string]$Region = "nyc3"
)

if ([string]::IsNullOrEmpty($ApiToken)) {
    $ApiToken = $env:DIGITALOCEAN_API_TOKEN
    if ([string]::IsNullOrEmpty($ApiToken)) {
        Write-Host "Error: API token not provided" -ForegroundColor Red
        exit 1
    }
}

$ErrorActionPreference = "Stop"
Write-Host "Starting SpiralCoin Deployment to DigitalOcean..." -ForegroundColor Green
Write-Host "=" -ForegroundColor Gray -NoNewline
Write-Host ("=" * 50) -ForegroundColor Gray

Write-Host ""
Write-Host "Creating DigitalOcean Droplet..." -ForegroundColor Yellow

$userData = @"
#!/bin/bash
cd /root
apt-get update
apt-get install -y curl git nodejs npm
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
git pull origin main
npm install
pm2 start server.js --name spiralcoin
pm2 startup
pm2 save
"@

$dropletObject = @{
    name = $AppName
    region = $Region
    size = "s-2vcpu-4gb"
    image = "ubuntu-22-04-x64"
    backups = $true
    ipv6 = $true
    user_data = $userData
    tags = @("spiralcoin", "trading-platform")
}

$dropletBody = $dropletObject | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $ApiToken"
    "Content-Type" = "application/json"
}

try {
    Write-Host "Sending request to DigitalOcean API..." -ForegroundColor Yellow
    $response = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets" `
        -Method Post `
        -Headers $headers `
        -Body $dropletBody

    $dropletId = $response.droplet.id
    Write-Host "Droplet created successfully. ID: $dropletId" -ForegroundColor Green
    Write-Host ""
    Write-Host "Waiting for droplet to boot (30 seconds)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    Write-Host "Getting droplet IP address..." -ForegroundColor Yellow
    $dropletInfo = Invoke-RestMethod -Uri "https://api.digitalocean.com/v2/droplets/$dropletId" `
        -Method Get `
        -Headers $headers

    $ipAddress = $dropletInfo.droplet.networks.v4[0].ip_address
    Write-Host "Droplet IP Address: $ipAddress" -ForegroundColor Green

    Write-Host ""
    Write-Host "Creating DNS record..." -ForegroundColor Yellow

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
        Write-Host "DNS record created successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Note: DNS setup requires domain in DigitalOcean account" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host "DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Access your SpiralCoin server:" -ForegroundColor Cyan
    Write-Host "  IP Address: http://$ipAddress" -ForegroundColor White
    Write-Host "  Domain: https://spiralcoin.net" -ForegroundColor White
    Write-Host ""
    Write-Host "The server will be fully ready in 2-3 minutes" -ForegroundColor Yellow
    Write-Host "SSH into server: ssh root@$ipAddress" -ForegroundColor White
    Write-Host ""

}
catch {
    Write-Host "Deployment Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
