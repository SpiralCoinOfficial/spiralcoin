# 🎛️ Production Operations Dashboard

## Complete System Management Guide

---

## 🚀 Quick Start Commands

### System Status (Run Anytime)
```bash
ssh root@174.138.37.6
/root/status.sh
```

Output shows all services, resources, and recent activity in one view.

### View All Logs
```bash
# Real-time backup logs
tail -f /var/log/spiralcoin-backup.log

# Real-time monitoring logs
tail -f /var/log/spiralcoin-monitor.log

# Docker service logs (all)
cd /root/spiralcoin && docker compose logs -f

# Single service logs
docker compose logs -f backend
docker compose logs -f daemon
docker compose logs -f web
docker compose logs -f marketfeed
```

---

## 📊 Dashboard Layers

### Layer 1: Local Status Dashboard

**Command**: `/root/status.sh`

Shows real-time:
```
Services: Status of all 4 containers
Resources: Disk, memory, CPU usage
Recent Logs: Last 5 monitoring events
Performance: Response times
```

Runs: Manual (on demand)

### Layer 2: Local Health Monitoring

**Script**: `/root/spiralcoin-monitor.sh`

Runs: Every 5 minutes (automated)

Checks:
- Web UI availability
- Backend API health
- RPC daemon responsiveness
- MarketFeed WebSocket
- Disk usage (alert if >80%)
- Memory usage (alert if >90%)
- Docker service count (alert if <4)

Auto-restarts failed services.

### Layer 3: External Monitoring

**Service**: UptimeRobot

Runs: 24/7 (every 5 minutes)

Monitors:
- Main domain/IP availability
- 4 service endpoints
- Response times
- Global uptime percentage

Sends alerts via email/Discord/Slack.

### Layer 4: Automated Backups

**Script**: `/root/spiralcoin-backup.sh`

Runs: Daily at 2 AM

Creates:
- Compressed backup files
- 7-day rolling retention
- Automatic cleanup

---

## 🔍 Daily Operations

### Morning Check (30 seconds)

```bash
# SSH to server
ssh root@174.138.37.6

# Check status
/root/status.sh

# Expected output:
# ✓ All services running
# ✓ Disk < 80%
# ✓ Memory < 90%
# ✓ 0 incidents last 24 hours
```

### Weekly Review (15 minutes)

```bash
# 1. Check backup logs
tail -20 /var/log/spiralcoin-backup.log

# 2. Check monitoring logs
tail -20 /var/log/spiralcoin-monitor.log

# 3. Review UptimeRobot dashboard
# → https://uptimerobot.com

# 4. Check incident history
docker compose logs | grep -i error

# 5. Verify cron jobs
crontab -l
```

### Monthly Review (30 minutes)

```bash
# 1. Export uptime report
# → UptimeRobot → Export CSV

# 2. Review all logs
journalctl -u docker -n 100

# 3. Check disk usage
du -sh /root/spiralcoin/*

# 4. Verify backups
ls -lh /root/spiralcoin-backups/

# 5. Security audit
sudo ufw status
fail2ban-client status
```

---

## 🚨 Incident Response

### Service Goes Down

```bash
# 1. Immediate response
ssh root@174.138.37.6
/root/status.sh

# 2. Check service logs
docker compose logs backend | tail -50

# 3. Restart service
docker compose restart backend

# 4. Verify recovery
docker compose ps

# 5. Monitor for recurrence
tail -f /var/log/spiralcoin-monitor.log

# 6. Document incident
echo "Incident: backend down - $(date)" >> /var/log/incidents.log
```

### Disk Space Critical

```bash
# 1. Check usage
df -h

# 2. Find large files
du -sh /root/spiralcoin/* | sort -h

# 3. Clean old logs
find /var/log -name "*.log" -mtime +30 -delete

# 4. Clean docker cache
docker system prune -a

# 5. Check again
df -h
```

### Slow Performance

```bash
# 1. Check system resources
top
free -h
df -h

# 2. Check network
nethogs

# 3. Check service logs
docker compose logs | tail -100

# 4. Restart services
docker compose restart

# 5. Monitor recovery
/root/status.sh
```

### All Services Down

```bash
# 1. Check server status
ping 174.138.37.6

# 2. SSH and check docker
ssh root@174.138.37.6
docker ps -a

# 3. Check docker daemon
systemctl status docker

# 4. Restart docker if needed
sudo systemctl restart docker

# 5. Restart services
cd /root/spiralcoin
docker compose up -d

# 6. Verify recovery
docker compose ps
/root/status.sh
```

---

## 🔧 Maintenance Tasks

### Monthly Tasks (1st of month)

```bash
# 1. Update system packages
ssh root@174.138.37.6
sudo apt update && sudo apt upgrade -y

# 2. Update docker images
docker pull spiralcoin/web:latest
docker pull spiralcoin/backend:latest
docker pull spiralcoin/daemon:latest
docker pull spiralcoin/marketfeed:latest

# 3. Rebuild containers
cd /root/spiralcoin
docker compose down
docker compose up -d

# 4. Verify all services
docker compose ps
/root/status.sh

# 5. Test restore procedure
# (dry-run of backup restoration)
```

### Quarterly Tasks (Every 3 months)

```bash
# 1. Security audit
sudo ufw status
fail2ban-client status

# 2. SSL certificate check
sudo certbot certificates

# 3. Backup integrity check
# Restore latest backup to test environment

# 4. Performance benchmarking
ab -n 1000 -c 10 https://spiralcoin.net

# 5. Log rotation review
ls -lh /var/log/
```

### Annual Tasks (Yearly)

```bash
# 1. Full security audit
# → Run with security firm

# 2. Disaster recovery drill
# → Full restore from backup

# 3. Infrastructure review
# → Upgrade if needed

# 4. Capacity planning
# → Current growth trajectory

# 5. Cost optimization
# → Review DigitalOcean spend
```

---

## 📈 Performance Monitoring

### Key Metrics to Track

| Metric | Current | Target | Alert |
|--------|---------|--------|-------|
| **Uptime** | 99.9% | 99.9%+ | <99% |
| **Response Time** | 150ms | <200ms | >500ms |
| **Error Rate** | <0.1% | <0.1% | >1% |
| **Disk Usage** | 35% | <70% | >80% |
| **Memory Usage** | 45% | <80% | >90% |
| **CPU Usage** | 20% avg | <50% | >80% |

### Collect Metrics

```bash
# CPU & Memory
top -b -n 1 | head -15

# Disk usage
df -h
du -sh /root/spiralcoin

# Network activity
nethogs -b

# Service response times
time curl https://spiralcoin.net

# Error rates
grep "ERROR" /var/log/*.log | wc -l
```

### Build Monitoring Dashboard

Create `dashboard.sh`:

```bash
#!/bin/bash
while true; do
    clear
    echo "=== SpiralCoin Operations Dashboard ==="
    echo "Updated: $(date)"
    echo ""
    echo "Services:"
    docker compose ps --format "table {{.Names}}\t{{.Status}}"
    echo ""
    echo "System Resources:"
    echo "Disk: $(df / | awk 'NR==2 {print $5}')"
    echo "Memory: $(free | awk 'NR==2 {printf "%.1f", $3/$2*100}')%"
    echo "CPU Load: $(uptime | awk '{print $(NF-2)}')"
    echo ""
    echo "Recent Errors:"
    tail -3 /var/log/spiralcoin-monitor.log
    echo ""
    sleep 30
done
```

Run:
```bash
chmod +x dashboard.sh
./dashboard.sh
```

---

## 🔐 Security Operations

### Daily Security Checks

```bash
# Check SSH logs for suspicious activity
grep "Failed password" /var/log/auth.log | tail -5

# Check firewall logs
sudo ufw status verbose

# Monitor fail2ban
fail2ban-client status

# Check user accounts
cat /etc/passwd | grep -E ":(0|[1-9]+):" | grep -v root
```

### Weekly Security Tasks

```bash
# 1. Review SSH access logs
journalctl -u ssh -n 50

# 2. Check for unauthorized sudo access
grep "sudo" /var/log/auth.log | grep -v COMMAND

# 3. Verify firewall rules
sudo ufw status numbered

# 4. Check failed login attempts
fail2ban-client status sshd
```

### Incident Investigation

```bash
# If you suspect a breach:

# 1. Check system integrity
ls -la /root/
ls -la /etc/ssh/

# 2. Check running processes
ps aux | grep -v root

# 3. Check recent logins
who
w

# 4. Check SSH keys
cat ~/.ssh/authorized_keys

# 5. Review audit logs
sudo ausearch -ts recent
```

---

## 🆘 Emergency Procedures

### Service Recovery

**If all services crash:**

```bash
ssh root@174.138.37.6
cd /root/spiralcoin

# Check status
docker compose ps -a

# View error logs
docker compose logs | tail -100

# Force restart
docker compose down
sleep 10
docker compose up -d

# Verify recovery
docker compose ps
```

**If disk space full:**

```bash
# 1. Find largest files
find /root -type f -size +1G

# 2. Clean unnecessary data
docker system prune -a
find /var/log -name "*.log" -delete

# 3. Clear old backups (keep last 3)
ls -t /root/spiralcoin-backups/ | tail -n +4 | xargs rm

# 4. Check recovery
df -h
```

**If network unreachable:**

```bash
# 1. Check IP configuration
ip addr show

# 2. Test connectivity
ping 8.8.8.8
curl https://google.com

# 3. Check firewall
sudo ufw status

# 4. Restart network interface
sudo ip link set eth0 down
sudo ip link set eth0 up

# 5. Test again
ping 8.8.8.8
```

### Restore from Backup

```bash
# 1. Stop services
cd /root/spiralcoin
docker compose down

# 2. List available backups
ls -lh /root/spiralcoin-backups/

# 3. Select and restore
BACKUP="spiralcoin-backup-20251215_020001.tar.gz"
tar -xzf /root/spiralcoin-backups/$BACKUP -C /

# 4. Verify restore
ls -l /root/spiralcoin/data/

# 5. Start services
docker compose up -d

# 6. Verify functionality
/root/status.sh
```

---

## 📞 Command Reference

### Essential Commands

```bash
# Status & Monitoring
/root/status.sh                    # Full dashboard
docker compose ps                  # Service status
docker compose logs -f             # Real-time logs
tail -f /var/log/spiralcoin-*.log # Application logs

# Management
docker compose up -d               # Start all services
docker compose down                # Stop all services
docker compose restart             # Restart all services
docker compose restart backend     # Restart single service

# Maintenance
docker system prune -a             # Clean docker cache
docker compose pull                # Update images
docker compose logs --tail=100     # Last 100 log lines

# Backups
/root/spiralcoin-backup.sh        # Run backup now
ls /root/spiralcoin-backups/      # List backups

# SSH & Access
ssh root@174.138.37.6             # SSH to server
ssh -p 2222 root@174.138.37.6     # Alternate SSH port
```

### Diagnostic Commands

```bash
# System resources
top                                # Real-time system stats
free -h                            # Memory usage
df -h                              # Disk usage
ps aux | grep spiralcoin           # Process list

# Network
netstat -tlnp                      # Open ports
curl -v https://spiralcoin.net     # Test connectivity
dig spiralcoin.net                 # DNS resolution
traceroute 174.138.37.6            # Network path

# Security
sudo ufw status                    # Firewall rules
fail2ban-client status             # Fail2ban status
sudo journalctl -u ssh -n 20       # SSH logs
cat /etc/ssh/sshd_config           # SSH config
```

---

## 📋 Runbook Templates

### Runbook: Deploy New Feature

```
1. Pull latest code
   cd /root/spiralcoin
   git pull origin main

2. Rebuild images
   docker compose build

3. Test on staging
   Create test environment first

4. Deploy to production
   docker compose down
   docker compose up -d

5. Verify
   /root/status.sh
   Test critical functionality

6. Monitor
   Watch logs for 1 hour
   tail -f /var/log/spiralcoin-monitor.log

7. Document
   Record deployment time/changes
   Note any issues
```

### Runbook: Emergency Rollback

```
1. Stop services
   docker compose down

2. Revert code
   git checkout [previous-commit]

3. Rebuild
   docker compose build

4. Start
   docker compose up -d

5. Verify
   /root/status.sh

6. Post-mortem
   Investigate what failed
   Plan fix
```

---

## 💾 Backup & Disaster Recovery

### Backup Strategy

- **Daily**: Automated daily backups (2 AM)
- **Retention**: 7-day rolling window
- **Location**: Local (/root/spiralcoin-backups/)
- **Size**: ~250MB per backup
- **Recovery Time**: <5 minutes

### Backup Test Schedule

```
Weekly: List backups and verify file integrity
Monthly: Restore latest backup to test environment
Quarterly: Full disaster recovery drill
```

### Test Restore Procedure

```bash
# 1. Create test directory
mkdir -p /tmp/spiralcoin-test

# 2. Restore backup
tar -xzf /root/spiralcoin-backups/LATEST.tar.gz \
    -C /tmp/spiralcoin-test

# 3. Verify data
ls -l /tmp/spiralcoin-test/root/spiralcoin/data/

# 4. Cleanup
rm -rf /tmp/spiralcoin-test
```

---

## 📊 Operations Metrics

**Track Monthly**:
- Uptime: Target 99.9%
- Incidents: Target 0-1
- MTTR: Target <10 minutes
- Backup success rate: Target 100%

**Track Weekly**:
- Service response times
- Error rates
- Disk usage trend
- Backup completion

**Track Daily**:
- All 4 services running
- Disk <70%
- Memory <80%
- No critical errors

---

## 🎓 Best Practices

✅ **DO**:
- Check status daily
- Review logs weekly
- Test backups monthly
- Update systems regularly
- Monitor continuously
- Document incidents
- Plan ahead

❌ **DON'T**:
- Ignore alerts
- Delay security updates
- Skip backup tests
- Make changes untested
- Leave logs unbounded
- Run single copy of data
- Deploy without verification

---

**Status**: Operations infrastructure ready  
**Time to Mastery**: 1-2 weeks  
**Support**: Full documentation + automation scripts  
**Objective**: Reliable, hands-off 24/7 operations
