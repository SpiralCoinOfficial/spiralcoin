# SpiralCoin Docker Deployment Guide

## 🐳 Quick Start (Docker Compose)

### Prerequisites
- Docker Engine 20.10+
- Docker Compose v2+
- 2GB RAM minimum
- 10GB disk space

### Local Development

```bash
# Clone the repository
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin

# Build and start all services
docker compose up --build

# Or run in detached mode
docker compose up -d --build
```

### Services & Ports

| Service | Port | Description |
|---------|------|-------------|
| **daemon** | 8545 | C++ Blockchain Daemon (RPC) |
| **backend** | 5000 | Node.js REST API |
| **marketfeed** | 4000 | WebSocket Market Feed |
| **web** | 3000 | Trading Platform UI |

### Testing Endpoints

```bash
# Test daemon RPC
curl -X POST http://localhost:8545/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"getinfo","params":[],"id":1}'

# Test backend health
curl http://localhost:5000/health

# Test marketfeed
curl http://localhost:4000/api/feed

# Open web interface
open http://localhost:3000
```

### Service Management

```bash
# View logs
docker compose logs -f daemon
docker compose logs -f backend
docker compose logs -f marketfeed

# Stop services
docker compose down

# Restart a service
docker compose restart daemon

# Rebuild after code changes
docker compose up --build daemon
```

## 🚀 Production Server Deployment

### Server: 174.138.37.6 (spiralcoin.net)

```bash
# SSH into production server
ssh -p 8454 root@174.138.37.6

# Clone repository
cd /root
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin

# Create production .env
cat > .env << EOF
PORT=5000
NODE_ENV=production
RPC_URL=http://daemon:8545
EXT_FEED=https://api.coingecko.com/api/v3/coins/markets
NODE_PORT=4000
EOF

# Build and start services
docker compose up -d --build

# Check status
docker compose ps
docker compose logs --tail=50
```

### Nginx Reverse Proxy (Production)

```nginx
# /etc/nginx/sites-available/spiralcoin.net

server {
    listen 80;
    server_name spiralcoin.net www.spiralcoin.net;

    # Redirect to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name spiralcoin.net www.spiralcoin.net;

    ssl_certificate /etc/letsencrypt/live/spiralcoin.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/spiralcoin.net/privkey.pem;

    # Trading Platform
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # MarketFeed WebSocket
    location /ws/ {
        proxy_pass http://localhost:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # RPC Endpoint (Optional - restrict access)
    location /rpc/ {
        # Allow only internal IPs
        allow 127.0.0.1;
        deny all;

        proxy_pass http://localhost:8545/;
        proxy_set_header Host $host;
    }
}
```

### SSL Setup (Let's Encrypt)

```bash
# Install certbot
apt-get update
apt-get install -y certbot python3-certbot-nginx

# Get SSL certificate
certbot --nginx -d spiralcoin.net -d www.spiralcoin.net

# Auto-renewal
systemctl enable certbot.timer
```

### Firewall Configuration

```bash
# Allow SSH (custom port)
ufw allow 8454/tcp

# Allow HTTP/HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Block direct access to internal ports (optional)
ufw deny 8545/tcp
ufw deny 4000/tcp
ufw deny 5000/tcp

# Enable firewall
ufw enable
```

### Auto-Start on Reboot

```bash
# Create systemd service
cat > /etc/systemd/system/spiralcoin.service << EOF
[Unit]
Description=SpiralCoin Docker Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/root/spiralcoin
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl daemon-reload
systemctl enable spiralcoin.service
systemctl start spiralcoin.service
```

## 🔧 Troubleshooting

### Daemon Not Starting

```bash
# Check logs
docker compose logs daemon

# Common issue: Data directory permissions
docker compose exec daemon ls -la /app/data

# Rebuild daemon
docker compose build --no-cache daemon
docker compose up -d daemon
```

### Backend/MarketFeed Cannot Connect to Daemon

```bash
# Verify internal network
docker network inspect spiralcoin_spiralcoin-network

# Check daemon is accessible
docker compose exec backend curl http://daemon:8545/

# Restart services in order
docker compose restart daemon
docker compose restart backend marketfeed
```

### Data Persistence

```bash
# Backup wallet data
docker compose exec daemon cat /app/data/wallets.json > wallets_backup.json

# Backup blockchain
docker compose exec daemon cat /app/data/blockchain.json > blockchain_backup.json

# Restore data
docker compose cp wallets_backup.json daemon:/app/data/wallets.json
docker compose restart daemon
```

## 📊 Monitoring

```bash
# Resource usage
docker stats

# Service health
watch -n 5 'docker compose ps'

# Real-time logs
docker compose logs -f --tail=100

# Check RPC connectivity
curl -X POST http://localhost:8545/ \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}'
```

## 🔒 Security Best Practices

1. **Change default ports** in production
2. **Use strong passwords** for SSH
3. **Restrict RPC access** to localhost only
4. **Enable fail2ban** for SSH protection
5. **Regular backups** of wallet and blockchain data
6. **Monitor logs** for suspicious activity
7. **Keep Docker updated**: `apt-get update && apt-get upgrade docker-ce`

## 📦 Maintenance

### Update to Latest Version

```bash
cd /root/spiralcoin
git pull origin main
docker compose down
docker compose up -d --build
```

### Clean Up Old Images

```bash
docker system prune -a
docker volume prune
```

### Database Backup Schedule

```bash
# Add to crontab
0 2 * * * cd /root/spiralcoin && docker compose exec daemon tar -czf /tmp/backup-$(date +\%Y\%m\%d).tar.gz /app/data && mv /tmp/backup-*.tar.gz /root/backups/
```

---

## 🎯 Next Steps

1. ✅ Docker configuration complete
2. ⏳ Install Docker on production server (174.138.37.6)
3. ⏳ Deploy stack with `docker compose up -d`
4. ⏳ Configure nginx reverse proxy
5. ⏳ Set up SSL with Let's Encrypt
6. ⏳ Configure firewall and security
7. ⏳ Test all endpoints
8. ⏳ Set up monitoring and backups
9. ⏳ Go live at spiralcoin.net

**Founder Wallet**: 0x928072b3A3A42e7dFD577a91167DfAa08f0E653E (30,562,600 SPRC)
**Supply Wallet**: 0xSPRC1111111111111111111111111111SupplyVault (20,000,000,000,000 SPRC)
**Total Supply**: 20,000,030,562,600 SPRC
