# SpiralCoin Server Recovery Plan

**Date**: December 15, 2025  
**Server**: 174.138.37.6  
**Issue**: SSH blocked, Backend API down, Web UI returning 404

---

## 🔴 Critical Issues Identified

### 1. SSH Access Completely Blocked
- **Impact**: Cannot perform server maintenance
- **Symptom**: `Connection timed out` on port 22 and 2222
- **Priority**: CRITICAL - Must fix first

### 2. Web UI Returns 404 Error
- **Impact**: Landing page not serving content
- **Symptom**: Port 3000 responds but returns 404 Not Found
- **Likely Cause**: Nginx misconfiguration or static files missing

### 3. Backend API Down
- **Impact**: No trading functionality, no API responses
- **Symptom**: Port 5000 not responding
- **Likely Cause**: Container crashed or stopped

### 4. RPC Daemon Status Unknown
- **Impact**: Blockchain operations may be impaired
- **Status**: Port 8545 connectivity unclear

---

## 📋 Recovery Steps (In Order)

### STEP 1: Restore SSH Access (5-10 minutes)

**Method A: DigitalOcean Droplet Console (RECOMMENDED)**

1. Open browser: https://cloud.digitalocean.com/droplets
2. Click your **spiralcoin** droplet
3. Click **"Console"** button (top right) or **Access** → **Launch Droplet Console**
4. Wait for console to load (may take 30 seconds)
5. Login:
   - Username: `root`
   - Password: `HarLand2025!`

6. Once logged in, diagnose SSH:
   ```bash
   # Check SSH service status
   systemctl status ssh
   
   # If not running, start it
   systemctl start ssh
   systemctl enable ssh
   
   # Check firewall rules
   ufw status verbose
   
   # Allow SSH if blocked
   ufw allow 22/tcp
   ufw reload
   
   # Verify SSH is listening
   netstat -tlnp | grep :22
   ```

7. Test SSH from your local machine:
   ```powershell
   ssh root@174.138.37.6
   ```

**Method B: DigitalOcean Cloud Firewall**

1. Go to: https://cloud.digitalocean.com/networking/firewalls
2. Find firewall attached to spiralcoin droplet
3. Check **Inbound Rules**:
   - Must have: **SSH | TCP | 22 | All IPv4 and IPv6**
4. If missing, click **"Edit"** → **Add Inbound Rule**:
   - Type: `SSH`
   - Protocol: `TCP`
   - Port: `22`
   - Sources: `All IPv4` and `All IPv6`
5. Click **"Save"**
6. Wait 30 seconds and test SSH again

**Method C: Check DigitalOcean Droplet Status**

1. Go to droplet dashboard
2. Verify droplet status shows **"Active"** (green dot)
3. If powered off or paused:
   - Click **Power** → **Power On**
4. If frozen:
   - Click **Power** → **Power Cycle**
5. Wait 2-3 minutes for boot
6. Test SSH again

---

### STEP 2: Fix Web UI 404 Error (2 minutes)

Once SSH is working, connect and run:

```bash
ssh root@174.138.37.6

# Check Docker containers
cd /root/spiralcoin
docker compose ps

# Check Nginx container logs
docker compose logs nginx | tail -50

# Check if static files exist
ls -la /root/spiralcoin/public/

# Restart all containers
docker compose restart

# Verify services
docker compose ps
```

**Expected Output**:
```
NAME                    STATUS
spiralcoin-nginx        Up
spiralcoin-backend      Up
spiralcoin-daemon       Up
spiralcoin-marketfeed   Up
```

**Test the fix**:
```bash
curl -I http://localhost:3000
# Should return: HTTP/1.1 200 OK
```

---

### STEP 3: Restore Backend API (1 minute)

```bash
# Still in SSH session
cd /root/spiralcoin

# Check backend logs for errors
docker compose logs backend | tail -100

# Restart backend specifically
docker compose restart backend

# Verify it's running
docker compose ps backend

# Test API endpoint
curl http://localhost:5000/api/stats
```

**Expected**: JSON response with stats data

---

### STEP 4: Deploy Automation Scripts (30 seconds)

```bash
# Download and run setup script
bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)

# Verify cron jobs installed
crontab -l

# Verify scripts exist
ls -l /root/*.sh
```

**Expected**:
- `/root/spiralcoin-backup.sh`
- `/root/spiralcoin-monitor.sh`
- `/root/status.sh`
- 4-5 cron jobs listed

---

### STEP 5: Verify Full Recovery (1 minute)

```bash
# Run status dashboard
/root/status.sh

# Expected: All 4 services show green/up

# Check from outside
exit
```

From local machine:
```powershell
# Test Web UI
curl http://174.138.37.6:3000

# Test Backend API
curl http://174.138.37.6:5000/api/stats

# Run comprehensive check
.\scripts\quick-status.ps1
```

---

## 🔍 Diagnostic Commands (If Issues Persist)

### Check Docker Status
```bash
docker ps -a
docker stats --no-stream
docker compose logs --tail=100
```

### Check Disk Space
```bash
df -h
du -sh /root/spiralcoin/*
```

### Check Memory
```bash
free -h
top -bn1 | head -20
```

### Check Network
```bash
netstat -tlnp
ufw status verbose
```

### Check System Logs
```bash
journalctl -xe | tail -100
dmesg | tail -50
```

---

## 📞 Emergency Contacts & Resources

### DigitalOcean Support
- Dashboard: https://cloud.digitalocean.com
- Support Tickets: https://cloud.digitalocean.com/support
- Community: https://www.digitalocean.com/community

### Quick Commands Reference
```bash
# Restart everything
docker compose restart

# Stop all
docker compose down

# Start fresh
docker compose up -d

# View all logs
docker compose logs -f

# Shell into container
docker compose exec backend sh
```

---

## ✅ Success Criteria

After recovery is complete, verify:

- [ ] SSH connection works from local machine
- [ ] Web UI loads at http://174.138.37.6:3000 (200 OK)
- [ ] Backend API responds at http://174.138.37.6:5000/api/stats
- [ ] RPC Daemon accessible on port 8545
- [ ] MarketFeed running on port 4000
- [ ] All 4 Docker containers show "Up" status
- [ ] Automation scripts installed (`crontab -l`)
- [ ] Status dashboard works (`/root/status.sh`)
- [ ] No 404 errors when accessing site
- [ ] `quick-status.ps1` shows all green

---

## 🎯 Root Cause Analysis (To Investigate)

After recovery, investigate:

1. **Why SSH was blocked**:
   - Check `/var/log/auth.log` for failed login attempts
   - Check `fail2ban` status if installed
   - Review UFW logs

2. **Why Web UI returned 404**:
   - Check nginx access logs: `docker compose logs nginx`
   - Verify static file paths in nginx.conf
   - Check if public/ directory mounted correctly

3. **Why Backend crashed**:
   - Check backend logs: `docker compose logs backend`
   - Look for out-of-memory errors
   - Check disk space issues

4. **Set up monitoring** to prevent recurrence:
   - Install UptimeRobot (external monitoring)
   - Enable automated health checks
   - Set up alerts for service failures

---

## 📝 Post-Recovery Actions

1. **Test full platform functionality**:
   ```bash
   # Test all endpoints
   curl http://174.138.37.6:3000
   curl http://174.138.37.6:5000/api/stats
   curl http://174.138.37.6:5000/api/blockchain/info
   ```

2. **Verify automation**:
   ```bash
   # Check cron is running
   systemctl status cron
   
   # Verify backup script works
   /root/spiralcoin-backup.sh
   ls -l /root/spiralcoin-backups/
   ```

3. **Set up external monitoring**:
   - Go to https://uptimerobot.com
   - Add monitor for http://174.138.37.6:3000
   - Set 5-minute check interval
   - Configure email alerts

4. **Document what happened**:
   - Note date/time of failure
   - List steps taken to recover
   - Update runbook with lessons learned

5. **Commit all changes**:
   ```powershell
   git add -A
   git commit -m "docs: Add server recovery plan and procedures"
   git push origin main
   ```

---

## 🚨 If Nothing Works

Last resort options:

### Option 1: Rebuild from Backup
```bash
# Restore latest backup
cd /root/spiralcoin-backups
ls -lt | head -5
# Extract and restore most recent backup
```

### Option 2: Redeploy from Scratch
1. Create new droplet
2. Run deployment script: `.\digitalocean-deploy.ps1`
3. Restore data from backups
4. Update DNS

### Option 3: Contact DigitalOcean Support
1. Open support ticket at https://cloud.digitalocean.com/support
2. Provide:
   - Droplet ID
   - Error messages
   - Steps already taken
3. Request assistance accessing console or diagnosing network issues

---

**Remember**: The Droplet Console is your emergency access method when SSH fails. Bookmark this URL:  
https://cloud.digitalocean.com/droplets

**Current Status**: Awaiting SSH access restoration to proceed with recovery.
