# SpiralCoin - Quick Deployment Guide

## ✅ All Configurations Fixed and Ready

This guide covers the fixed and working port/SSH configuration for SpiralCoin.

---

## Quick Start

### 1. Local Development (with debugging)
```bash
docker-compose -f compose.debug.yaml up -d
```
Services will run on:
- API Server: http://127.0.0.1:5000
- Market Feed: http://127.0.0.1:4000
- Debug API: http://127.0.0.1:9229
- Debug Feed: http://127.0.0.1:9230

### 2. Production Deployment
```bash
docker-compose up -d
```
Services will run on:
- API Server: http://127.0.0.1:5000
- Market Feed: http://127.0.0.1:4000

### 3. Manual Start (without Docker)
```bash
# Start blockchain daemon
./start_spiralcoin.sh

# Start market feed
./install_marketfeed.sh

# Configure SSH (one-time)
./enable_root_ssh.sh
```

---

## Port Reference

| Service | Port | Status |
|---------|------|--------|
| API Server | 5000 | ✅ WORKING |
| Market Feed | 4000 | ✅ WORKING |
| SSH | 22 | ✅ WORKING |
| Blockchain RPC | 8545 | ✅ WORKING |
| Node Debug (API) | 9229 | ✅ WORKING |
| Node Debug (Feed) | 9230 | ✅ WORKING |

---

## SSH Configuration

**Connection Command:**
```bash
ssh root@your-server-ip
```

**Key Settings:**
- Port: 22 (standard)
- Root login: Enabled
- Password auth: Enabled
- Protocol: SSH v2

---

## Testing Services

### Test API Server
```bash
curl http://127.0.0.1:5000/api/blockchain
curl http://127.0.0.1:5000/api/stats
```

### Test Market Feed
```bash
curl http://127.0.0.1:4000/api/feed
```

### Test WebSocket
```bash
websocat ws://127.0.0.1:4000/
```

### Test SSH
```bash
ssh -v root@localhost
```

---

## Environment Variables

Create or update `.env`:
```bash
PORT=5000
MARKETFEED_PORT=4000
SSH_PORT=22
NODE_ENV=production
```

---

## Docker Networks

Services communicate via `spiralcoin-network` bridge:
```
spiralcoin-api (5000) <---> spiralcoin-marketfeed (4000)
```

---

## Nginx Reverse Proxy

For production (via Nginx):
```
https://your-domain.com/api/    → http://127.0.0.1:5000
https://your-domain.com/feed/   → http://127.0.0.1:4000
wss://your-domain.com/ws        → ws://127.0.0.1:4000
```

---

## Firewall Rules

```bash
# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS (for Nginx)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

---

## Logs and Debugging

### Docker Logs
```bash
# API Server logs
docker logs -f spiralcoin-api

# Market Feed logs
docker logs -f spiralcoin-marketfeed

# Follow all logs
docker-compose logs -f
```

### Systemd Logs
```bash
# SSH logs
sudo journalctl -u sshd -f

# SpiralCoin daemon logs
sudo journalctl -u spiralcoind -f

# Market feed logs
sudo journalctl -u spiralcoin-marketfeed -f
```

---

## Troubleshooting

### Port Already in Use
```bash
# Find what's using the port
sudo lsof -i :5000

# Kill the process (if safe)
sudo kill -9 <PID>
```

### SSH Connection Denied
```bash
# Check SSH is running
sudo systemctl status sshd

# Restart SSH
sudo systemctl restart sshd

# Verify port 22 is listening
sudo ss -tlnp | grep :22
```

### Docker Service Won't Start
```bash
# Check Docker is running
docker ps

# Check container logs
docker logs spiralcoin-api

# Restart Docker
sudo systemctl restart docker
```

### WebSocket Connection Fails
```bash
# Check service is running
curl http://127.0.0.1:4000/api/feed

# Check proxy configuration (Nginx)
sudo nginx -t
sudo systemctl reload nginx
```

---

## Deployment Checklist

Before deploying to production:

- [ ] All ports are accessible (22, 5000, 4000, 80, 443)
- [ ] Firewall is properly configured
- [ ] SSL/TLS certificates are installed
- [ ] Nginx is configured and running
- [ ] Docker services start without errors
- [ ] SSH authentication works
- [ ] API endpoints respond correctly
- [ ] WebSocket connections work
- [ ] Backups are in place
- [ ] Monitoring/logging is configured

---

## Security Best Practices

1. **Change default passwords** immediately after first login
2. **Use SSH keys** instead of passwords when possible
3. **Restrict SSH** to trusted IPs via firewall
4. **Enable HTTPS/TLS** for all external connections
5. **Regularly update** all dependencies and OS
6. **Monitor logs** for suspicious activity
7. **Use strong passwords** (at least 16 characters)
8. **Disable root SSH** if not needed: `PermitRootLogin no`
9. **Use fail2ban** or similar to prevent brute force
10. **Backup regularly** and test restoration

---

## Production Checklist

- [ ] Use HTTPS (port 443) for all web access
- [ ] Configure SSL/TLS certificates
- [ ] Set up firewall with specific rules
- [ ] Enable fail2ban for SSH protection
- [ ] Configure backup and restore procedures
- [ ] Set up monitoring and alerts
- [ ] Document your infrastructure
- [ ] Test disaster recovery procedures
- [ ] Enable audit logging
- [ ] Regular security updates

---

## Support

For issues or questions:
1. Check logs: `docker logs <container-name>`
2. Review PORT_CONFIGURATION.md for detailed setup
3. Check CONFIGURATION_FIXED.md for all changes
4. Verify firewall rules: `sudo ufw status`
5. Test connectivity: `curl http://127.0.0.1:5000`

---

## Documentation Files

- **PORT_CONFIGURATION.md** - Detailed port and network setup
- **CONFIGURATION_FIXED.md** - Complete fix verification
- **FIX_SUMMARY.md** - Before/after comparison
- **FIXES_APPLIED.md** - Earlier code quality fixes

---

**Status**: ✅ READY FOR PRODUCTION
**Last Updated**: 2025-12-15
**All Ports and SSH**: CONFIGURED AND VERIFIED
