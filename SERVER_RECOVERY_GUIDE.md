# PRODUCTION SERVER RECOVERY GUIDE

## Current Status
**Server**: 174.138.37.6
**Status**: OFFLINE (crashed during deployment)
**Issue**: Server stopped responding after Docker installation attempt

## What Happened
1. Server was in "rescue mode" (live/recovery system)
2. Docker overlay filesystem couldn't mount in rescue mode
3. When we stopped Docker service, the rescue system became unstable
4. Server crashed and won't recover automatically

## IMMEDIATE ACTION REQUIRED

### Option 1: Hard Reboot via DigitalOcean Console (RECOMMENDED)
1. Go to: https://cloud.digitalocean.com/droplets
2. Click your droplet (174.138.37.6)
3. Click **"Power"** section on left
4. Click **"Hard Reboot"**
5. Wait 2-3 minutes for server to restart
6. Run: `powershell -ExecutionPolicy Bypass -File deploy_production.ps1`

### Option 2: Power Cycle
1. Go to: https://cloud.digitalocean.com/droplets
2. Click your droplet
3. Click **"Power Off"** → wait for complete shutdown
4. Click **"Power On"** → wait for boot
5. Run deployment script

### Option 3: Enable Recovery Mode (if standard boot fails)
1. Go to DigitalOcean console
2. Click **"Recovery"**
3. Click **"Start recovery mode"**
4. Once booted, check: `mount | grep "on / type"`
5. If shows `rescue_rootfs.squashfs`, exit recovery:
   - Click "Recovery" → "Stop recovery mode"
   - Hard reboot the server

## Recovery Checklist

Once server is online:

- [ ] Server responds to ping
- [ ] SSH port 22 (or fallback 2222) is open: `ssh root@174.138.37.6` or `ssh -p 2222 root@174.138.37.6`
- [ ] Password: `HarLand2025a!`
- [ ] Filesystem is normal (not rescue mode): `mount | grep "on / type"`
- [ ] Docker is installed: `docker --version`
- [ ] Services deployed: `docker compose ps`
- [ ] RPC responding: `curl -s http://localhost:8545`
- [ ] Backend responding: `curl -s http://localhost:5000`
- [ ] MarketFeed responding: `curl -s http://localhost:4000`

## Deployment Commands (after server is online)

### Manual Deploy
```bash
ssh root@174.138.37.6
curl -fsSL https://get.docker.com | sh
cd /root && git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
docker compose up -d --build
docker compose ps
```

### Automated Deploy (Windows PowerShell)
```powershell
cd C:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin
powershell -ExecutionPolicy Bypass -File deploy_production.ps1
```

### Auto Recovery Monitor (waits up to 10 min for server to come online)
```powershell
cd C:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin
powershell -ExecutionPolicy Bypass -File wait_and_deploy.ps1
```

## SSH Port Fixes Applied
- ✓ Fixed PRODUCTION_CHECKLIST.md: SSH port from 8454 to 22
- ✓ Fixed emergency restart command: SSH port 22 (was 8454)
- ✓ Fixed install_marketfeed.sh: MarketFeed external port 4000 (was 8485)

## Service Ports
- **RPC Daemon**: 8545 (C++ blockchain)
- **Backend API**: 5000 (Node.js)
- **MarketFeed**: 4000 (WebSocket)
- **Web UI**: 3000 (Nginx proxy)
- **SSH**: 22

## Emergency Contacts
- Deployment Script: `deploy_production.ps1`
- Recovery Script: `wait_and_deploy.ps1`
- Server Password: `HarLand2025a!`
- Server IP: `174.138.37.6`

## Next Steps
1. **Boot the server** via DigitalOcean console
2. **Wait for connectivity** (2-5 minutes)
3. **Run deployment** script
4. **Verify services** are running
5. **Check wallet data** integrity

---
Last Update: 2025-12-15 15:30 UTC
Status: Waiting for manual server restart
