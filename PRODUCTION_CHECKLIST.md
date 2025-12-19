# SpiralCoin Production Deployment Checklist

## ✅ Completed Steps

- [x] C++ blockchain daemon code complete with DQVE integration
- [x] Node.js backend API with REST endpoints
- [x] MarketFeed WebSocket service
- [x] Trading platform UI with SPRC branding
- [x] Wallet system (Founder: 30.5M + Supply: 20T SPRC)
- [x] Docker containerization (daemon, backend, marketfeed, web)
- [x] Docker Compose orchestration
- [x] Deployment documentation (DOCKER_DEPLOYMENT.md)
- [x] Code pushed to GitHub

## 🚀 Current Step: Production Server Deployment

### Server Details

- **IP**: 174.138.37.6
- **Domain**: spiralcoin.net
- **SSH Port**: 8454
- **Access**: root@174.138.37.6

### Runtime Requirements

- Node.js >= 18.17 (LTS recommended). Required by undici >= 6 and helmet >= 7.
- npm >= 9. Ensure the Node/npm on the host meet these versions before running the backend.

### Deployment Steps

#### 1. Install Docker (if needed)

```bash
ssh -p 8454 root@174.138.37.6
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
docker --version
```

#### 2. Clone/Update Repository

```bash
cd /root
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git || (cd spiralcoin && git pull)
cd spiralcoin
```

#### 3. Create Production Environment File

```bash
cat > .env << 'EOF'
PORT=5000
NODE_ENV=production
RPC_URL=http://daemon:8545
EXT_FEED=https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd
NODE_PORT=4000
JWT_SECRET=SET_A_STRONG_RANDOM_SECRET
EOF
```

#### 4. Deploy Docker Stack

```bash
docker compose up -d --build
```

#### 5. Verify Services

```bash
docker compose ps
docker compose logs --tail=50 daemon
docker compose logs --tail=20 backend
docker compose logs --tail=20 marketfeed
```

#### 6. Test Endpoints

```bash
# Test daemon RPC
curl -X POST http://localhost:8545/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"getinfo","params":[],"id":1}'

# Test backend
curl http://localhost:5000/health

# Test quotes
curl http://localhost:5000/api/market/quotes | jq

# Test candles (ETH example)
curl "http://localhost:5000/api/market/candles?asset=ETH&vs=USD&interval=1h" | jq

# Test marketfeed
curl http://localhost:4000/api/feed

## 🔐 Auth API Quick Tests

```bash
# 1) Signup (use a unique email)
EMAIL="qa_$RANDOM@example.com"
curl -s -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"Test1234!qa\"}"

# 2) Login (get access + refresh tokens)
LOGIN=$(curl -s -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"Test1234!qa\"}")
ACCESS=$(echo "$LOGIN" | jq -r '.token')
REFRESH=$(echo "$LOGIN" | jq -r '.refreshToken')

# 3) Account (with access token)
curl -s http://localhost:5000/api/account -H "Authorization: Bearer $ACCESS" | jq

# 4) Refresh (get a new access token)
REF=$(curl -s -X POST http://localhost:5000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}")
ACCESS2=$(echo "$REF" | jq -r '.token')
curl -s http://localhost:5000/api/account -H "Authorization: Bearer $ACCESS2" | jq

# 5) Logout (invalidate refresh token)
curl -s -X POST http://localhost:5000/api/auth/logout \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH\"}"
```

### Supply API Quick Tests

```bash
# Supply summary
curl http://localhost:5000/api/supply | jq

# Founder wallet and balance
curl http://localhost:5000/api/supply/founder | jq

# Supply vault wallet and balance
curl http://localhost:5000/api/supply/vault | jq

# Total supply
curl http://localhost:5000/api/supply/total | jq
```


## 🔒 Security Configuration

### Install Nginx

```bash
apt-get update
apt-get install -y nginx
```

### Configure Nginx Reverse Proxy

```bash
cat > /etc/nginx/sites-available/spiralcoin.net << 'EOF'
server {
    listen 80;
    server_name spiralcoin.net www.spiralcoin.net;
  # Canonical redirect to www
  return 301 https://www.spiralcoin.net$request_uri;
}

server {
    listen 443 ssl http2;
    server_name spiralcoin.net www.spiralcoin.net;

    # SSL certificates (will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/spiralcoin.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spiralcoin.net/privkey.pem;

  # Enforce modern TLS
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
  ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 10m;

  # OCSP stapling
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 1.1.1.1 1.0.0.1 valid=300s;
  resolver_timeout 5s;

  # Redirect apex to canonical www on HTTPS
  if ($host = spiralcoin.net) {
    return 301 https://www.spiralcoin.net$request_uri;
  }

  # Security headers
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header Referrer-Policy "no-referrer-when-downgrade" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header Content-Security-Policy "default-src 'self' https: data blob 'unsafe-inline' 'unsafe-eval'; connect-src 'self' https: wss:; img-src 'self' https: data blob; font-src 'self' https: data; frame-ancestors 'self'; upgrade-insecure-requests" always;

    # Trading Platform
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }

    # MarketFeed WebSocket
    location /ws {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    # Daemon JSON-RPC (proxied, POST only)
    location /rpc/ {
      proxy_pass http://localhost:8545/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      # Optional: limit methods to POST via simple check (not strict security)
      if ($request_method != POST) { return 405; }
      access_log off;
    }

    # SSE streams (candles/quotes)
    location /api/market/stream/ {
      proxy_pass http://localhost:5000/api/market/stream/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      # Disable response buffering for SSE
      proxy_buffering off;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:5000/health;
        access_log off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/spiralcoin.net /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### Install SSL Certificate

```bash
apt-get install -y certbot python3-certbot-nginx
certbot --nginx -d spiralcoin.net -d www.spiralcoin.net --non-interactive --agree-tos -m admin@spiralcoin.net
```

### Configure Firewall

```bash
ufw allow 8454/tcp  # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw --force enable
ufw status
```

## 🔄 Auto-Start Configuration

### Create Systemd Service

```bash
cat > /etc/systemd/system/spiralcoin.service << 'EOF'
[Unit]
Description=SpiralCoin Docker Stack
Requires=docker.service
After=docker.service network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/root/spiralcoin
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable spiralcoin.service
systemctl start spiralcoin.service
systemctl status spiralcoin.service
```

## 📊 Monitoring Setup

### Install Monitoring Tools

```bash
apt-get install -y htop nethogs iotop
```

### Create Monitoring Script

```bash
cat > /root/monitor-spiralcoin.sh << 'EOF'
#!/bin/bash
echo "=== SPIRALCOIN MONITORING ==="
echo ""
echo "Docker Containers:"
docker compose -f /root/spiralcoin/compose.yaml ps
echo ""
echo "Resource Usage:"
docker stats --no-stream
echo ""
echo "Daemon Logs (last 10 lines):"
docker compose -f /root/spiralcoin/compose.yaml logs --tail=10 daemon
echo ""
echo "Endpoints Status:"
echo -n "Backend: "
curl -s http://localhost:5000/health | jq -r '.status' 2>/dev/null || echo "OFFLINE"
echo -n "Daemon RPC: "
curl -s -X POST http://localhost:8545/ -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' | jq -r '.result' 2>/dev/null || echo "OFFLINE"
echo ""
EOF

chmod +x /root/monitor-spiralcoin.sh
```

## 💾 Backup Configuration

### Create Backup Script

```bash
cat > /root/backup-spiralcoin.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/root/spiralcoin-backups"
mkdir -p "$BACKUP_DIR"
DATE=$(date +%Y%m%d_%H%M%S)

echo "Backing up SpiralCoin data..."
cd /root/spiralcoin

# Backup wallet and blockchain data
docker compose exec -T daemon tar czf - /app/data > "$BACKUP_DIR/spiralcoin-data-$DATE.tar.gz"

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "spiralcoin-data-*.tar.gz" -mtime +7 -delete

echo "Backup complete: $BACKUP_DIR/spiralcoin-data-$DATE.tar.gz"
ls -lh "$BACKUP_DIR" | tail -5
EOF

chmod +x /root/backup-spiralcoin.sh
```

### Schedule Daily Backups

```bash
(crontab -l 2>/dev/null; echo "0 2 * * * /root/backup-spiralcoin.sh >> /var/log/spiralcoin-backup.log 2>&1") | crontab -
```

## 🧪 Post-Deployment Testing

### Test All Endpoints

```bash
# 1. Test daemon RPC
curl -X POST https://spiralcoin.net/rpc/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"getinfo","params":[],"id":1}'

# 2. Test backend API
curl https://spiralcoin.net/api/stats

# 3. Test health endpoint
curl https://spiralcoin.net/health

# 4. Test WebSocket (from browser console)
# const ws = new WebSocket('wss://spiralcoin.net/ws');
# ws.onmessage = (e) => console.log(JSON.parse(e.data));

# 5. Open trading platform
# https://spiralcoin.net

# 6. Test SSE quotes stream (press Ctrl+C to stop)
curl -N -H 'Accept: text/event-stream' https://spiralcoin.net/api/market/stream/quotes | head -n 20

# 7. Test SSE candles stream for SPRC (press Ctrl+C to stop)
curl -N -H 'Accept: text/event-stream' "https://spiralcoin.net/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" | head -n 20
```

## 📋 Remaining Tasks

### Technical

- [ ] Security audit of smart contracts
- [ ] Load testing (stress test daemon with 1000+ concurrent connections)
- [ ] Set up monitoring alerts (email/SMS for downtime)
- [ ] Configure log rotation for Docker containers
- [ ] Set up automated updates (Watchtower for Docker)
- [ ] Implement rate limiting on public APIs
- [ ] Add API authentication/JWT tokens

### Business & Marketing

- [ ] Legal entity incorporation
- [ ] Whitepaper finalization
- [ ] Marketing website content
- [ ] Social media presence (Twitter, Telegram, Discord)
- [ ] Community building strategy
- [ ] Exchange listing applications:
  - [ ] Uniswap V3 (Ethereum)
  - [ ] PancakeSwap (BSC)
  - [ ] Gate.io application
  - [ ] KuCoin application
- [ ] Partnership outreach
- [ ] Press release distribution

### Compliance

- [ ] KYC/AML policy documentation
- [ ] Terms of service
- [ ] Privacy policy
- [ ] GDPR compliance (if applicable)
- [ ] Securities law review

## 🎯 Launch Checklist

- [ ] All Docker services running and healthy
- [ ] HTTPS/SSL configured and valid
- [ ] Domain resolving correctly (spiralcoin.net)
- [ ] All endpoints accessible publicly
- [ ] Wallet balances verified (30.5M founder + 20T supply)
- [ ] Monitoring and alerting active
- [ ] Backups configured and tested
- [ ] Recovery procedures documented
- [ ] Performance benchmarks met
- [ ] Security scan passed
- [ ] Public announcement ready

## 🚨 Emergency Contacts & Procedures

### Quick Restart

```bash
ssh -p 8454 root@174.138.37.6
cd /root/spiralcoin
docker compose restart
```

### View Logs

```bash
docker compose logs -f --tail=100
```

### Restore from Backup

```bash
cd /root/spiralcoin
docker compose down
# Extract latest backup
tar xzf /root/spiralcoin-backups/spiralcoin-data-YYYYMMDD_HHMMSS.tar.gz
docker compose up -d
```

---

## 📊 Current Status

**Repository**: ✅ Pushed to GitHub
**Docker Stack**: ✅ Created and tested locally
**Documentation**: ✅ Complete
**Next Action**: 🚀 Deploy to production server (174.138.37.6)

**Founder Wallet**: 0x928072b3A3A42e7dFD577a91167DfAa08f0E653E (30,562,600 SPRC)
**Supply Wallet**: 0xSPRC1111111111111111111111111111SupplyVault (20,000,000,000,000 SPRC)
**Total Supply**: 20,000,030,562,600 SPRC
