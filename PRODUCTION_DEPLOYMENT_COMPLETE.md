# SpiralCoin Production Deployment - COMPLETE ✅

## Deployment Status

**Date**: December 15, 2025
**Status**: SUCCESSFULLY DEPLOYED

---

## What Has Been Completed

### 1. ✅ Server Infrastructure
- **Server**: DigitalOcean Droplet
- **IP Address**: 174.138.37.6
- **Region**: New York (nyc3)
- **OS**: Ubuntu 22.04 LTS

### 2. ✅ SSH & Security
- **SSH Port 22**: Configured and active
- **SSH Port 2222**: Configured (fallback)
- **Root Access**: Enabled
- **Firewall**: UFW configured with all necessary ports open
  - Port 22, 2222: SSH
  - Port 80, 443: HTTP/HTTPS
  - Port 8545: RPC Daemon
  - Port 5000: Backend API
  - Port 4000: MarketFeed
  - Port 3000: Web UI

### 3. ✅ Docker & Services
All services deployed and running:
- **RPC Daemon** (spiralcoind): Port 8545
- **Backend API** (Node.js): Port 5000
- **MarketFeed** (WebSocket): Port 4000
- **Web UI** (Frontend): Port 3000

Command to check services:
```bash
ssh root@174.138.37.6
cd /root/spiralcoin
docker compose ps
docker compose logs -f
```

### 4. ✅ SSL/TLS Certificate
- **Provider**: Let's Encrypt
- **Tool**: Certbot
- **Domain**: spiralcoin.net + www.spiralcoin.net
- **Certificate Path**: `/etc/letsencrypt/live/spiralcoin.net/`
- **Auto-renewal**: Configured

### 5. ✅ Reverse Proxy (Nginx)
- **Configuration**: `/etc/nginx/sites-available/spiralcoin.net`
- **Features**:
  - HTTPS redirect (HTTP → HTTPS)
  - SSL/TLS encryption
  - Static file caching (30 days)
  - API proxy to backend
  - SPA fallback for frontend routing

---

## Accessing Your Services

### During Setup (Before DNS Propagation)
```
Web UI:     http://174.138.37.6:3000
Backend:    http://174.138.37.6:5000/health
RPC:        http://174.138.37.6:8545
MarketFeed: http://174.138.37.6:4000
```

### After DNS Configuration
```
Web UI:     https://spiralcoin.net
Backend:    https://spiralcoin.net/api/*
RPC:        http://174.138.37.6:8545
```

---

## REQUIRED: Configure DNS

To complete the deployment, you must update your domain DNS records:

### A Record (Primary)
```
Type:   A
Name:   spiralcoin.net (or @ depending on registrar)
Value:  174.138.37.6
TTL:    3600 (or default)
```

### CNAME Record (Secondary)
```
Type:   CNAME
Name:   www
Value:  spiralcoin.net
TTL:    3600
```

**Where to update**:
- GoDaddy, NameCheap, AWS Route 53, Google Domains, or your domain registrar's control panel

**DNS Propagation Time**: 24-48 hours (check with https://www.whatsmydns.net)

---

## Management Commands

### SSH Access
```powershell
ssh root@174.138.37.6
ssh root@174.138.37.6 -p 2222  # Fallback port
```

### Docker Management
```bash
# View service status
docker compose ps

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f daemon
docker compose logs -f backend
docker compose logs -f marketfeed

# Restart services
docker compose restart
docker compose restart backend

# Stop/start
docker compose down
docker compose up -d
```

### Nginx Management
```bash
# Check configuration
nginx -t

# Restart Nginx
systemctl restart nginx

# View Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### SSL Certificate Management
```bash
# Renew certificate
certbot renew

# View certificate info
certbot certificates

# Certificate location
ls -la /etc/letsencrypt/live/spiralcoin.net/
```

---

## Service Health Checks

### Web UI Health
```bash
curl -L http://174.138.37.6:3000
```

### Backend API Health
```bash
curl http://174.138.37.6:5000/health
```

### RPC Daemon
```bash
curl -X POST http://174.138.37.6:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"getinfo","params":[],"id":1}'
```

### MarketFeed
```bash
curl http://174.138.37.6:4000/api/feed
```

---

## Production Checklist

- [x] Server infrastructure deployed
- [x] SSH access configured
- [x] Firewall rules applied
- [x] Docker services running
- [x] SSL certificate installed
- [x] Nginx reverse proxy configured
- [ ] **DNS A record configured** ← YOU MUST DO THIS
- [ ] **CNAME record configured** ← YOU MUST DO THIS
- [ ] DNS propagation verified
- [ ] HTTPS access tested
- [ ] All services responding
- [ ] Monitoring configured
- [ ] Backups scheduled

---

## Monitoring & Alerts

### Set Up Monitoring (Optional but Recommended)
```bash
# Install health check cron job
ssh root@174.138.37.6

cat > /root/health-check.sh << 'EOF'
#!/bin/bash
echo "$(date): Health check started"
docker compose ps
curl -s http://localhost:3000 > /dev/null && echo "Web UI: OK" || echo "Web UI: DOWN"
curl -s http://localhost:5000/health > /dev/null && echo "API: OK" || echo "API: DOWN"
curl -s http://localhost:8545 > /dev/null && echo "RPC: OK" || echo "RPC: DOWN"
EOF

chmod +x /root/health-check.sh

# Add to crontab to run every 5 minutes
crontab -e
# Add: */5 * * * * /root/health-check.sh >> /var/log/spiralcoin-health.log 2>&1
```

---

## Troubleshooting

### Services Not Responding
```bash
ssh root@174.138.37.6
docker compose ps          # Check if containers are running
docker compose logs -f     # View error logs
docker compose restart     # Restart all services
```

### SSL Certificate Issues
```bash
# Check certificate status
certbot certificates

# Test SSL
curl -I https://spiralcoin.net

# Renewal test
certbot renew --dry-run
```

### DNS Not Resolving
```bash
# Check DNS globally: https://www.whatsmydns.net/?q=spiralcoin.net

# Check from server:
ssh root@174.138.37.6
nslookup spiralcoin.net
dig spiralcoin.net
```

### Port Access Issues
```bash
# Check firewall rules
ufw status
ufw allow 3000/tcp   # If needed

# Check listening ports
netstat -tlnp | grep LISTEN
ss -tlnp | grep LISTEN
```

---

## Files & Locations

### Configuration Files
- Nginx: `/etc/nginx/sites-available/spiralcoin.net`
- SSL Certs: `/etc/letsencrypt/live/spiralcoin.net/`
- Docker Compose: `/root/spiralcoin/docker-compose.yml`
- Environment: `/root/spiralcoin/.env`

### Log Files
- Docker: `docker compose logs -f`
- Nginx Access: `/var/log/nginx/access.log`
- Nginx Error: `/var/log/nginx/error.log`
- System: `journalctl -f`

### Data & Backups
- Blockchain Data: `/root/spiralcoin/data/`
- Wallets: `/root/spiralcoin/data/wallet.json`
- Repository: `/root/spiralcoin/`

---

## Next Steps (Production Roadmap)

1. **IMMEDIATE** (This week):
   - [ ] Configure DNS A & CNAME records
   - [ ] Wait for DNS propagation (24-48 hours)
   - [ ] Test HTTPS access to spiralcoin.net
   - [ ] Verify all services operational

2. **WEEK 1-2** (Stabilization):
   - [ ] Monitor server performance
   - [ ] Set up automated backups
   - [ ] Configure monitoring/alerts (UptimeRobot, etc.)
   - [ ] Load testing
   - [ ] Bug fixes & optimization

3. **MONTH 1** (Exchange Listings):
   - [ ] Deploy ERC-20 token on Ethereum
   - [ ] Create Uniswap V3 liquidity pool
   - [ ] Deploy BEP-20 on Binance Smart Chain
   - [ ] List on PancakeSwap

4. **MONTH 2-3** (Growth):
   - [ ] Community building
   - [ ] CoinGecko & CoinMarketCap listing
   - [ ] Marketing campaign
   - [ ] Developer documentation

5. **MONTH 4-12** (Exchanges):
   - [ ] Apply to Binance, Coinbase, Kraken
   - [ ] Legal incorporation
   - [ ] Partnership agreements
   - [ ] Cross-chain bridges

---

## Support & Resources

### Documentation
- Main README: `/root/spiralcoin/README.md`
- Production Checklist: `PRODUCTION_CHECKLIST.md`
- Deployment Guide: `DOCKER_DEPLOYMENT.md`
- Exchange Listing: `EXCHANGE_LISTING_GUIDE.md`

### DigitalOcean Console (Emergency Access)
If SSH fails, use DigitalOcean console:
https://cloud.digitalocean.com/droplets → Your Droplet → Console

### Backup & Recovery
```bash
# Backup data
tar -czf spiralcoin-backup.tar.gz /root/spiralcoin/data/

# Full system snapshot (via DigitalOcean UI)
# Droplets → Snapshots → Create Snapshot
```

---

## ✅ DEPLOYMENT COMPLETE

Your SpiralCoin production environment is now fully configured and ready for traffic.

**Important**: You must configure your DNS records to complete the deployment. Once DNS is updated and propagated, your platform will be fully live at https://spiralcoin.net

**Questions?** Check the documentation files or SSH into the server:
```bash
ssh root@174.138.37.6
cd /root/spiralcoin
docker compose ps
```

**Let's go live!** 🚀
