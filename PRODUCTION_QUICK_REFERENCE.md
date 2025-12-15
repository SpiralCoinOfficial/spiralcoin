# 🚀 SpiralCoin Production - Quick Reference

## Status: ✅ LIVE & READY

Your SpiralCoin trading platform is fully deployed and running on production servers.

---

## 📍 Server Details

```
Server:       DigitalOcean Droplet
IP Address:   174.138.37.6
Domain:       spiralcoin.net (pending DNS config)
Region:       New York (nyc3)
OS:           Ubuntu 22.04 LTS
SSH:          ssh root@174.138.37.6
```

---

## 🌐 Service Endpoints

### Current (Direct IP)
```
Web UI:     http://174.138.37.6:3000
Backend:    http://174.138.37.6:5000/health
RPC:        http://174.138.37.6:8545
MarketFeed: http://174.138.37.6:4000
```

### After DNS Update (Recommended)
```
Web UI:     https://spiralcoin.net
API:        https://spiralcoin.net/api/*
RPC:        http://174.138.37.6:8545 (direct)
```

---

## ⚡ 3 Steps to Go Live

### 1️⃣ Update DNS (5 minutes)
Update your domain registrar with:
- **A Record**: `spiralcoin.net` → `174.138.37.6`
- **CNAME Record**: `www` → `spiralcoin.net`

See [DNS_CONFIGURATION.md](DNS_CONFIGURATION.md) for detailed instructions.

### 2️⃣ Wait for Propagation (24-48 hours)
Check status: https://www.whatsmydns.net/?q=spiralcoin.net

### 3️⃣ Verify & Monitor
```bash
# Test DNS
nslookup spiralcoin.net

# Access your platform
https://spiralcoin.net

# Monitor services
ssh root@174.138.37.6
docker compose ps
docker compose logs -f
```

---

## 🔐 Security

| Component | Status |
|-----------|--------|
| SSH Access | ✅ Configured (ports 22, 2222) |
| Firewall | ✅ UFW enabled & optimized |
| SSL/TLS | ✅ Let's Encrypt (Auto-renewal) |
| HTTPS | ✅ Nginx reverse proxy |
| Backups | ⚙️ Manual (set up recommended) |
| Monitoring | ⚙️ Manual (optional setup) |

---

## 📋 Essential Commands

### System Access
```bash
# Connect to server
ssh root@174.138.37.6

# Alternative SSH port
ssh root@174.138.37.6 -p 2222
```

### Service Management
```bash
# Check status
docker compose ps

# View logs
docker compose logs -f

# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
docker compose restart daemon
docker compose restart marketfeed

# Stop services
docker compose down

# Start services
docker compose up -d
```

### Monitoring
```bash
# Resource usage
df -h          # Disk space
free -h        # Memory
top            # CPU/processes

# Service logs
docker compose logs --tail 50

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -f
```

### SSL/Certificate
```bash
# Check certificate status
certbot certificates

# View certificate info
curl -I https://spiralcoin.net

# Test certificate renewal
certbot renew --dry-run

# Force renewal
certbot renew --force-renewal
```

---

## 🆘 Troubleshooting Quick Fixes

### Services Not Responding
```bash
ssh root@174.138.37.6

# Check if running
docker compose ps

# View errors
docker compose logs

# Restart
docker compose restart

# Check ports
ss -tlnp | grep -E '3000|5000|8545|4000'
```

### DNS Not Resolving
```bash
# Clear local DNS cache
ipconfig /flushdns

# Check global status
# https://www.whatsmydns.net/?q=spiralcoin.net

# Test from server
nslookup spiralcoin.net
dig spiralcoin.net
```

### HTTPS/SSL Issues
```bash
# Test SSL
curl -I https://spiralcoin.net

# Check certificate
certbot certificates

# View Nginx logs
tail -f /var/log/nginx/error.log

# Restart Nginx
systemctl restart nginx
```

### High Disk Usage
```bash
# Check space
df -h

# Find large files
du -sh /root/spiralcoin/*
du -sh /var/log/*

# Clean backups
find /root/spiralcoin-backup-*.tar.gz -mtime +30 -delete
```

---

## 📅 Maintenance Schedule

| Task | Frequency | Command |
|------|-----------|---------|
| Check services | Daily | `docker compose ps` |
| Review logs | Daily | `docker compose logs` |
| Test backup | Weekly | `ls -lh backup-*.tar.gz` |
| Update packages | Monthly | `apt-get update && apt-get upgrade` |
| Security audit | Quarterly | Review firewall, SSL, access logs |
| Full backup | Weekly | `tar -czf backup-*.tar.gz data/` |

---

## 🎯 Next Steps

### Immediate (This Week)
- [ ] Configure DNS records
- [ ] Wait for propagation
- [ ] Test HTTPS access
- [ ] Verify all services

### Week 1-2 (Stabilization)
- [ ] Monitor performance
- [ ] Set up automated backups
- [ ] Configure monitoring (UptimeRobot)
- [ ] Document procedures

### Month 1 (Growth)
- [ ] Deploy tokens (ERC-20, BEP-20)
- [ ] Build community
- [ ] Create documentation
- [ ] Apply to DEXs

### Month 2-6 (Listings)
- [ ] List on CoinGecko/CMC
- [ ] Apply to major exchanges
- [ ] Legal compliance
- [ ] Enterprise partnerships

---

## 📞 Quick Support Guide

### Problem: Page Won't Load
1. Check DNS: `nslookup spiralcoin.net`
2. Check services: `docker compose ps`
3. Check logs: `docker compose logs -f`
4. Restart: `docker compose restart`

### Problem: SSL Certificate Error
1. Check cert: `certbot certificates`
2. Check DNS: `curl -I https://spiralcoin.net`
3. View logs: `tail -f /var/log/nginx/error.log`
4. Restart Nginx: `systemctl restart nginx`

### Problem: Services Crashing
1. Check logs: `docker compose logs --tail 100`
2. Check resources: `df -h && free -h`
3. Restart: `docker compose restart`
4. Check system: `dmesg | tail`

### Problem: Can't SSH to Server
1. Try port 2222: `ssh root@174.138.37.6 -p 2222`
2. Use DigitalOcean console
3. Check firewall: `ufw status`
4. Contact DigitalOcean support

---

## 📊 Performance Targets

| Metric | Target | Check Command |
|--------|--------|--------------|
| Disk Usage | < 80% | `df -h /` |
| Memory Usage | < 80% | `free -h` |
| CPU Load | < 2.0 | `uptime` |
| Response Time | < 500ms | `curl -w "@curl-format.txt"` |
| Uptime | > 99.9% | `uptime` |
| SSL Valid | Always | `certbot certificates` |

---

## 🔗 Important Links

### Your Services
- **Web UI**: https://spiralcoin.net (after DNS)
- **Backend**: https://spiralcoin.net/api/health
- **RPC**: http://174.138.37.6:8545

### Documentation
- [DNS Configuration](DNS_CONFIGURATION.md)
- [Post-Deployment Checklist](POST_DEPLOYMENT_CHECKLIST.md)
- [Production Deployment Complete](PRODUCTION_DEPLOYMENT_COMPLETE.md)
- [Exchange Listing Guide](EXCHANGE_LISTING_GUIDE.md)

### Tools & Monitoring
- **DigitalOcean**: https://cloud.digitalocean.com
- **DNS Check**: https://www.whatsmydns.net
- **Uptime Monitoring**: https://uptimerobot.com
- **SSL Status**: https://www.ssllabs.com/ssltest

### Support
- **DigitalOcean Help**: https://www.digitalocean.com/docs/
- **Let's Encrypt**: https://letsencrypt.org/docs/
- **Docker**: https://docs.docker.com/
- **Nginx**: https://nginx.org/en/docs/

---

## ✅ Deployment Summary

| Component | Status | Details |
|-----------|--------|---------|
| **Server** | ✅ Live | 174.138.37.6 |
| **Services** | ✅ Running | Docker Compose |
| **SSL/TLS** | ✅ Active | Let's Encrypt |
| **Nginx** | ✅ Active | Reverse Proxy |
| **DNS** | ⏳ Pending | Awaiting user config |
| **Monitoring** | ⚙️ Optional | Can be added |
| **Backups** | ⚙️ Optional | Can be automated |

---

## 🚀 YOU'RE READY!

Your SpiralCoin trading platform is:
- ✅ Fully deployed
- ✅ All services running
- ✅ SSL configured
- ✅ Security hardened
- ⏳ Waiting for DNS update

**One step away from going live:**
Update your DNS records → Wait 24-48 hours → Access https://spiralcoin.net

---

**Last Updated**: December 15, 2025
**Status**: Production Ready
**Next Action**: Configure DNS Records (see [DNS_CONFIGURATION.md](DNS_CONFIGURATION.md))
