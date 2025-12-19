param(
  [string]$Host = "174.138.37.6",
  [int]$Port = 8454,
  [string]$User = "root",
  [string]$Domain = "spiralcoin.net",
  [string]$WWW = "www.spiralcoin.net",
  [switch]$RunCertbot
)

$ErrorActionPreference = 'Stop'
Write-Host "=== SpiralCoin: Apply Nginx Config to Production ===" -ForegroundColor Cyan
Write-Host "Target: $User@$Host:$Port for $Domain/$WWW"

# Ensure ssh/scp available
function Require-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "Missing command: $name. Install Windows OpenSSH client or Git for Windows (includes ssh/scp)."
  }
}
Require-Command ssh
Require-Command scp

# Compose Nginx config content
$nginx = @"
server {
    listen 80;
    server_name $Domain $WWW;
    return 301 https://$WWW$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $Domain $WWW;

    ssl_certificate /etc/letsencrypt/live/$Domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$Domain/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 1.1.1.1 1.0.0.1 valid=300s;
    resolver_timeout 5s;

    if ($host = $Domain) {
      return 301 https://$WWW$request_uri;
    }

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self' https: data blob; script-src 'self' https: 'unsafe-inline' 'unsafe-eval'; style-src 'self' https: 'unsafe-inline'; connect-src 'self' https: wss:; img-src 'self' https: data blob; font-src 'self' https: data; frame-ancestors 'self'; upgrade-insecure-requests" always;

    location = / {
      return 302 /trading_platform.html;
    }
    location / {
      proxy_pass http://localhost:3000;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }

    location = /trading_platform.html {
      proxy_pass http://localhost:5000/trading_platform.html;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
    location = /Trading_platform.html {
      proxy_pass http://localhost:5000/Trading_platform.html;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
    location = /trading {
      proxy_pass http://localhost:5000/trading;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /rpc/ {
      proxy_pass http://localhost:8545/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      if ($request_method != POST) { return 405; }
      access_log off;
    }

    location /api/market/stream/ {
      proxy_pass http://localhost:5000/api/market/stream/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_buffering off;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }
}
"@

# Write to temp file
$tmp = New-TemporaryFile
Set-Content -Path $tmp -Value $nginx -Encoding UTF8
Write-Host "Prepared Nginx config in $tmp"

# Upload and enable on server
$remotePath = "/etc/nginx/sites-available/$Domain"
$enableCmd = @(
  "set -e",
  "cp -f $remotePath $remotePath.bak || true",
  "ln -sf $remotePath /etc/nginx/sites-enabled/$Domain",
  "nginx -t",
  "systemctl reload nginx"
) -join '; '

Write-Host "Uploading config to $remotePath"
scp -P $Port $tmp "$User@$Host:$remotePath"

Write-Host "Enabling and reloading Nginx"
ssh -p $Port "$User@$Host" "$enableCmd"

if ($RunCertbot) {
  Write-Host "Running certbot for $Domain,$WWW" -ForegroundColor Yellow
  $certCmd = @(
    "apt-get update",
    "apt-get install -y certbot python3-certbot-nginx",
    "certbot --nginx -d $Domain -d $WWW --non-interactive --agree-tos -m admin@$Domain || true",
    "nginx -t",
    "systemctl reload nginx"
  ) -join ' && '
  ssh -p $Port "$User@$Host" "$certCmd"
}

Remove-Item $tmp -ErrorAction SilentlyContinue
Write-Host "Done."
