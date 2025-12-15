# 🔄 SpiralCoin Automated Operations Setup

## Overview

Complete automation for backups, monitoring, and security updates.

---

## 🚀 Quick Setup (30 seconds)

### Option 1: Automated (Recommended)
```bash
ssh root@174.138.37.6
bash < <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)
```

### Option 2: Manual
```bash
ssh root@174.138.37.6
cd /root
wget https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh
bash setup-automation.sh
```

---

## What Gets Installed

### 1. 🔄 Daily Backups
- Runs every day at 2 AM
- Creates compressed backups
- Keeps rolling 7-day backup
- Auto-deletes old backups

### 2. 📊 Health Monitoring
- Checks services every 5 minutes
- Monitors disk/memory
- Logs all issues
- Auto-restarts failed services

### 3. 🔒 Security Hardening
- Automatic security updates (weekly)
- Log rotation (keeps 14 days)
- Firewall logging enabled
- Fail2ban protection

### 4. 🔧 Cron Jobs
Automatic tasks:
- 2 AM: Daily backup
- Every 5 min: Health check
- Every 10 min: Service restart check
- Sunday 3 AM: Security updates
- Monthly: Log cleanup

---

## Available Commands

### Check System Status
```bash
/root/status.sh
```

Output shows:
```
Services:
NAME           STATUS    PORTS
spiralcoin-web   Up        3000
spiralcoin-api   Up        5000
spiralcoin-rpc   Up        8545
spiralcoin-feed  Up        4000

System Resources:
Disk:   15%
Memory: 42%
CPU:    Load average: 0.45, 0.38, 0.35

Recent Logs (last 5 entries):
[2025-12-15 14:32:15] Health check started
[2025-12-15 14:32:16] Web UI OK
[2025-12-15 14:32:16] API OK
[2025-12-15 14:32:16] RPC OK
[2025-12-15 14:32:16] Health check completed
```

### View Backup Logs
```bash
tail -f /var/log/spiralcoin-backup.log
```

Output:
```
[2025-12-15 02:00:01] Starting SpiralCoin backup...
[2025-12-15 02:00:15] Backup successful: spiralcoin-backup-20251215_020001.tar.gz (245M)
[2025-12-15 02:00:16] Retained 7 backups (keeping 7 days)
[2025-12-15 02:00:16] Backup job completed
```

### View Health Logs
```bash
tail -f /var/log/spiralcoin-monitor.log
```

Output:
```
[2025-12-15 14:32:15] Health check started
[2025-12-15 14:32:16] ✓ Web UI OK
[2025-12-15 14:32:16] ✓ Backend API OK
[2025-12-15 14:32:16] ✓ RPC Daemon OK
[2025-12-15 14:32:16] ✓ MarketFeed OK
[2025-12-15 14:32:16] ✓ Disk usage: 15%
[2025-12-15 14:32:16] ✓ Memory usage: 42%
[2025-12-15 14:32:16] ✓ All 4 Docker services running
[2025-12-15 14:32:16] Health check completed
```

### Manage Cron Jobs
```bash
# List all cron jobs
crontab -l

# Edit cron jobs
crontab -e

# View cron logs
journalctl -u cron -f
```

### Test Backup
```bash
# Run backup manually
/root/spiralcoin-backup.sh

# View backups
ls -lh /root/spiralcoin-backups/
```

### Test Monitoring
```bash
# Run health check manually
/root/spiralcoin-monitor.sh

# View recent health checks
tail -10 /var/log/spiralcoin-monitor.log
```

---

## 🔌 Restore from Backup

If you need to restore from backup:

```bash
# List available backups
ls -lh /root/spiralcoin-backups/

# Stop services
cd /root/spiralcoin
docker compose down

# Restore backup
tar -xzf /root/spiralcoin-backups/spiralcoin-backup-TIMESTAMP.tar.gz -C /

# Verify restore
ls -l /root/spiralcoin/data/

# Start services
docker compose up -d
```

---

## 🚨 Troubleshooting

### Backup Not Running
```bash
# Check if backup script exists
ls -l /root/spiralcoin-backup.sh

# Test backup manually
/root/spiralcoin-backup.sh

# Check cron logs
sudo journalctl -u cron -n 20
```

### Monitoring Not Working
```bash
# Check if monitor script exists
ls -l /root/spiralcoin-monitor.sh

# Test monitoring manually
/root/spiralcoin-monitor.sh

# View latest logs
tail -20 /var/log/spiralcoin-monitor.log
```

### Disk Space Full
```bash
# Check disk usage
df -h

# Find large files
du -sh /root/spiralcoin/*
du -sh /var/log/*

# Clean old logs manually
find /var/log -name "*.log" -mtime +30 -delete
```

### Services Keep Crashing
```bash
# Check service logs
docker compose logs -f backend
docker compose logs -f daemon

# Check system resources
top
free -h
df -h

# Try manual restart
docker compose restart
```

---

## 📅 Maintenance Schedule

| Task | Frequency | Command |
|------|-----------|---------|
| Check status | Daily | `/root/status.sh` |
| View backup logs | Weekly | `tail -f /var/log/spiralcoin-backup.log` |
| Test restore | Monthly | Restore to test environment |
| Security audit | Quarterly | Review logs & firewall rules |
| Full backup review | Quarterly | Verify backup integrity |

---

## 🔒 Security Checklist

- [x] Automatic backups daily
- [x] Backups stored locally (add remote backup for DR)
- [x] Health monitoring active
- [x] Automatic service restart
- [x] Security updates enabled
- [x] Log rotation configured
- [x] Firewall logging on
- [ ] Add remote backup (optional)
- [ ] Add email alerts (optional)
- [ ] Add UptimeRobot monitoring (optional)

---

## Optional: Additional Monitoring

### Add UptimeRobot (Free)
```
1. Go to https://uptimerobot.com
2. Create free account
3. Add monitor for: https://spiralcoin.net
4. Get alerts if site goes down
```

### Add Email Alerts (Optional)
Edit `/root/spiralcoin-monitor.sh` and uncomment:
```bash
# mail -s "SpiralCoin Alert" your-email@example.com
```

### Add Remote Backup (Optional)
```bash
# Install rsync
apt-get install -y rsync

# Sync to remote server
rsync -avz /root/spiralcoin-backups/ user@remote:/backups/spiralcoin/
```

---

## ✅ Verification Checklist

After setup, verify everything is working:

```bash
# 1. Check automation scripts exist
ls -l /root/spiralcoin-*.sh

# 2. Check cron jobs
crontab -l

# 3. Check backup logs
tail -5 /var/log/spiralcoin-backup.log

# 4. Check monitor logs
tail -5 /var/log/spiralcoin-monitor.log

# 5. Check system status
/root/status.sh

# 6. Check docker services
docker compose ps
```

All should show successful completion.

---

## 📊 Dashboard Commands

Create a quick dashboard in your terminal:

```bash
# Add to .bashrc or .zshrc
alias spiralcoin-status="/root/status.sh"
alias spiralcoin-logs-backup="tail -f /var/log/spiralcoin-backup.log"
alias spiralcoin-logs-monitor="tail -f /var/log/spiralcoin-monitor.log"
alias spiralcoin-backups="ls -lh /root/spiralcoin-backups/"
```

Then just run:
```bash
spiralcoin-status          # Show status
spiralcoin-backups         # List backups
spiralcoin-logs-monitor    # View monitoring logs
```

---

## 🎯 Next Steps

1. ✅ Run setup script (shown above)
2. ⏳ Wait 5 minutes for first health check
3. 📊 Run `/root/status.sh` to verify
4. 🔍 Review logs to confirm everything working
5. 📋 Add to your daily monitoring routine

---

## Support

If automation setup fails:

```bash
# SSH to server
ssh root@174.138.37.6

# Run setup manually
cd /root
bash setup-automation.sh

# Verify services
docker compose ps
/root/status.sh
```

---

**Status**: Ready to automate all operations
**Next Action**: Run setup script on server
**Time Required**: 30 seconds
