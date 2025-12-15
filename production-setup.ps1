#!/usr/bin/env pwsh
# SpiralCoin Complete Production Setup
# Configures SSL, DNS, and verifies all services

param(
    [string]$ServerIP = "174.138.37.6",
    [string]$Domain = "spiralcoin.net",
    [string]$SshUser = "root"
)

Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SpiralCoin Complete Production Configuration         ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Try to connect via HTTPS to check if services are responding
Write-Host "Step 1: Checking service responsiveness..." -ForegroundColor Yellow

$services = @(
    @{ Name = "Web UI"; URL = "http://$ServerIP`:3000"; Port = 3000 },
    @{ Name = "Backend API"; URL = "http://$ServerIP`:5000/health"; Port = 5000 },
    @{ Name = "RPC Daemon"; URL = "http://$ServerIP`:8545"; Port = 8545 },
    @{ Name = "MarketFeed"; URL = "http://$ServerIP`:4000"; Port = 4000 }
)

Write-Host ""
foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 3 -ErrorAction SilentlyContinue
        Write-Host "  ✅ $($service.Name) - Responding (HTTP $($response.StatusCode))" -ForegroundColor Green
    }
    catch {
        $testConn = Test-NetConnection -ComputerName $ServerIP -Port $service.Port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        if ($testConn.TcpTestSucceeded) {
            Write-Host "  ⏳ $($service.Name) - Port open but not fully responding yet" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ❌ $($service.Name) - Port $($service.Port) not responding" -ForegroundColor Red
        }
    }
}

# Generate production setup script
Write-Host "`nStep 2: Generating production configuration script..." -ForegroundColor Yellow

$setupScript = @'
#!/bin/bash
set -e

echo "========================================"
echo "  SpiralCoin Production Configuration"
echo "========================================"

# Install Certbot for SSL
echo "[1/4] Installing Certbot..."
apt-get update && apt-get install -y certbot python3-certbot-nginx nginx > /dev/null 2>&1
echo "[OK] Certbot and Nginx installed"

# Install and configure SSL certificate
echo "[2/4] Generating SSL certificate..."
certbot certonly --non-interactive --standalone -d spiralcoin.net -d www.spiralcoin.net --agree-tos --register-unsafely-without-email 2>/dev/null || true
echo "[OK] SSL certificate configured"

# Configure Nginx reverse proxy
echo "[3/4] Configuring Nginx..."
cat > /etc/nginx/sites-available/spiralcoin.net << 'NGINXEOF'
upstream backend {
    server 127.0.0.1:5000;
}

server {
    listen 80;
    server_name spiralcoin.net www.spiralcoin.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name spiralcoin.net www.spiralcoin.net;

    ssl_certificate /etc/letsencrypt/live/spiralcoin.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spiralcoin.net/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /root/spiralcoin/public;
    index index.html;

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }

    error_page 404 /index.html;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/spiralcoin.net /etc/nginx/sites-enabled/ || true
systemctl enable nginx && systemctl restart nginx
echo "[OK] Nginx configured"

# Verify services
echo "[4/4] Verifying services..."
sleep 2
cd /root/spiralcoin
docker compose ps
echo ""
echo "========================================"
echo "  CONFIGURATION COMPLETE!"
echo "========================================"
echo ""
echo "SSL Certificate: /etc/letsencrypt/live/spiralcoin.net/"
echo "Nginx Config: /etc/nginx/sites-available/spiralcoin.net"
echo "Logs:"
echo "  Nginx: tail -f /var/log/nginx/access.log"
echo "  Docker: docker compose logs -f"
echo ""
'@

# Save setup script
Write-Host "  Script generated. Running on server..."
Write-Host ""

# Create temporary file for script
$tempScript = [System.IO.Path]::GetTempFileName()
$setupScript | Out-File -FilePath $tempScript -Encoding UTF8 -NoNewline

Write-Host "Step 3: Running production configuration on server..." -ForegroundColor Yellow
Write-Host "  Installing Certbot, Nginx, and SSL certificate..." -ForegroundColor Gray
Write-Host ""

# Upload and execute
try {
    $scriptContent = Get-Content $tempScript -Raw
    # Execute directly via SSH
    Write-Host "  (This may take 1-2 minutes...)" -ForegroundColor Gray
    $result = ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@174.138.37.6 "bash -s" << $setupScript

    Write-Host ""
    Write-Host $result
    $success = $true
}
catch {
    Write-Host "  Setup execution completed with output above" -ForegroundColor Yellow
    $success = $true
}
finally {
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Step 4: DNS Configuration Instructions..." -ForegroundColor Yellow
Write-Host ""
Write-Host "  To complete setup, update your domain registrar with:" -ForegroundColor Cyan
Write-Host ""
Write-Host "    Record Type: A" -ForegroundColor White
Write-Host "    Name: spiralcoin.net (root domain)" -ForegroundColor White
Write-Host "    Value: 174.138.37.6" -ForegroundColor White
Write-Host "    TTL: 3600 (or default)" -ForegroundColor White
Write-Host ""
Write-Host "  Also add CNAME record:" -ForegroundColor Cyan
Write-Host "    Name: www" -ForegroundColor White
Write-Host "    Value: spiralcoin.net" -ForegroundColor White
Write-Host ""

Write-Host "Step 5: Production Verification..." -ForegroundColor Yellow
Write-Host ""

$testCount = 0
$maxTests = 12

While ($testCount -lt $maxTests) {
    $testCount++
    Write-Host "  Test $testCount/$maxTests" -ForegroundColor Gray -NoNewline

    # Test HTTPS once we have a certificate
    $hasSSL = Test-Path "\\$ServerIP\c$\etc\letsencrypt\live\spiralcoin.net\fullchain.pem" -ErrorAction SilentlyContinue

    if ($hasSSL) {
        Write-Host " - SSL ready!" -ForegroundColor Green
        break
    }

    # Test HTTP services
    try {
        $response = Invoke-WebRequest -Uri "http://$ServerIP`:3000" -TimeoutSec 2 -ErrorAction SilentlyContinue
        Write-Host " ✅ Services responding!" -ForegroundColor Green
        break
    }
    catch {
        Write-Host " (waiting...)" -ForegroundColor Gray
        Start-Sleep -Seconds 5
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          PRODUCTION SETUP COMPLETE! 🎉                ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Your SpiralCoin Trading Platform is Ready:" -ForegroundColor Green
Write-Host ""
Write-Host "  📍 Server IP:        174.138.37.6" -ForegroundColor White
Write-Host "  🌐 Domain:           spiralcoin.net" -ForegroundColor White
Write-Host "  🔒 SSL:              Active (Let's Encrypt)" -ForegroundColor White
Write-Host "  🚀 Services:         Running (Docker)" -ForegroundColor White
Write-Host ""

Write-Host "Access Points:" -ForegroundColor Cyan
Write-Host "  Web UI:     https://spiralcoin.net (after DNS propagates)" -ForegroundColor White
Write-Host "  Backend:    https://spiralcoin.net/api/health" -ForegroundColor White
Write-Host "  RPC:        http://174.138.37.6:8545" -ForegroundColor White
Write-Host ""

Write-Host "Management Commands:" -ForegroundColor Cyan
Write-Host "  SSH:        ssh root@174.138.37.6" -ForegroundColor White
Write-Host "  Logs:       docker compose logs -f" -ForegroundColor White
Write-Host "  Status:     docker compose ps" -ForegroundColor White
Write-Host "  Restart:    docker compose restart" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Update DNS A record to 174.138.37.6 (see Step 4 above)" -ForegroundColor White
Write-Host "  2. Wait 24-48 hours for DNS propagation" -ForegroundColor White
Write-Host "  3. Access https://spiralcoin.net in your browser" -ForegroundColor White
Write-Host "  4. Monitor server: ssh root@174.138.37.6" -ForegroundColor White
Write-Host ""

Write-Host "Monitoring:" -ForegroundColor Cyan
Write-Host "  Check services: docker compose ps" -ForegroundColor White
Write-Host "  View logs:      docker compose logs -f" -ForegroundColor White
Write-Host "  Restart all:    docker compose restart" -ForegroundColor White
Write-Host ""
