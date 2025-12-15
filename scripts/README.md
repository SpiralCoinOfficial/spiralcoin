# 🔧 SpiralCoin Scripts Directory

All automation and management scripts for SpiralCoin production operations.

---

## 📂 Script Categories

### Server-Side Scripts (Bash)

**setup-automation.sh** - Master installer
- Deploys all automation to production server
- Installs backup, monitoring, and security scripts
- Sets up cron jobs
- **Usage**: `bash setup-automation.sh` (on server)

**backup-daily.sh** - Automated backups
- Creates daily backups at 2 AM
- 7-day rolling retention
- Automatic cleanup
- **Installed by**: setup-automation.sh

**monitor-health.sh** - Service monitoring
- Checks all 4 services every 5 minutes
- Auto-restarts failed services
- Logs all activity
- **Installed by**: setup-automation.sh

**security-hardening.sh** - Security lockdown
- One-time security configuration
- SSH hardening, fail2ban, auto-updates
- **Installed by**: setup-automation.sh

---

### Local Scripts (PowerShell)

**deploy-automation.ps1** - Deploy automation to server
- Helps upload and run setup-automation.sh
- Provides multiple deployment options
- Interactive SSH session launcher
- **Usage**: `.\scripts\deploy-automation.ps1`

**verify-deployment.ps1** - Comprehensive verification
- Tests all 10 critical deployment checks
- Service connectivity tests
- DNS/SSL verification
- Firewall checks
- **Usage**: `.\scripts\verify-deployment.ps1`

**quick-status.ps1** - Fast status dashboard
- Quick check of all services
- Color-coded status display
- Action recommendations
- **Usage**: `.\scripts\quick-status.ps1`
- **Recommended**: Run daily

**build_windows_mingw.ps1** - Windows build script
- Builds SpiralCoin on Windows using MinGW
- **Usage**: `.\scripts\build_windows_mingw.ps1`

---

## 🚀 Quick Start

### First Time Setup

**1. Verify Deployment**
```powershell
.\scripts\verify-deployment.ps1
```
Checks all services are running.

**2. Deploy Automation**
```powershell
.\scripts\deploy-automation.ps1
```
Installs backups & monitoring on server.

**3. Check Status**
```powershell
.\scripts\quick-status.ps1
```
Quick health check dashboard.

---

## 📊 Daily Operations

### Morning Check (30 seconds)
```powershell
.\scripts\quick-status.ps1
```

### Full Verification (2 minutes)
```powershell
.\scripts\verify-deployment.ps1
```

### SSH to Server
```powershell
ssh root@174.138.37.6
/root/status.sh
```

---

## 🔧 Script Details

### deploy-automation.ps1

**Purpose**: Simplify automation deployment

**What it does**:
- Tests server connectivity
- Provides 3 deployment options:
  1. Direct GitHub download (recommended)
  2. Upload local file via SCP
  3. Manual SSH instructions
- Opens SSH connection if requested

**Parameters**:
```powershell
-ServerIP "174.138.37.6"    # Server IP address
-Port 22                     # SSH port (tries 2222 if fails)
-Username "root"             # SSH username
```

**Example**:
```powershell
.\scripts\deploy-automation.ps1
.\scripts\deploy-automation.ps1 -Port 2222
```

---

### verify-deployment.ps1

**Purpose**: Comprehensive deployment verification

**10 Tests Performed**:
1. Server connectivity (SSH)
2. Web UI (port 3000)
3. Backend API (port 5000)
4. RPC Daemon (port 8545)
5. MarketFeed (port 4000)
6. SSL/HTTPS configuration
7. DNS resolution
8. SSH access
9. Firewall configuration
10. GitHub repository access

**Parameters**:
```powershell
-ServerIP "174.138.37.6"
-Port 22
-Username "root"
```

**Output**: Pass/fail for each test with remediation steps

**Example**:
```powershell
.\scripts\verify-deployment.ps1
```

---

### quick-status.ps1

**Purpose**: Fast daily status check

**What it shows**:
- All 4 service statuses (✅/❌)
- SSH connectivity
- Overall system health
- Quick action commands

**Parameters**:
```powershell
-ServerIP "174.138.37.6"
```

**Recommended**: Run every morning

**Example**:
```powershell
.\scripts\quick-status.ps1
```

---

### setup-automation.sh

**Purpose**: Install all automation on production server

**What it installs**:
- `/root/spiralcoin-backup.sh` - Daily backup script
- `/root/spiralcoin-monitor.sh` - 5-min health checks
- `/root/status.sh` - Status dashboard
- Cron jobs for automation
- Log files in `/var/log/`

**Cron jobs created**:
```
0 2 * * *       Daily backup (2 AM)
*/5 * * * *     Health monitoring (every 5 min)
*/10 * * * *    Auto-restart (every 10 min)
0 3 * * 0       Security updates (Sunday 3 AM)
```

**Usage**:
```bash
# On server
bash setup-automation.sh

# Or from local
ssh root@174.138.37.6 "bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)"
```

---

### backup-daily.sh

**Purpose**: Automated daily backups

**What it backs up**:
- Blockchain data (`/root/spiralcoin/data/`)
- Configuration files
- Environment variables
- Docker compose config

**Backup location**: `/root/spiralcoin-backups/`

**Retention**: 7 days (automatic cleanup)

**Schedule**: Daily at 2 AM

**Logs**: `/var/log/spiralcoin-backup.log`

**Manual run**:
```bash
/root/spiralcoin-backup.sh
```

---

### monitor-health.sh

**Purpose**: Continuous service monitoring

**What it monitors**:
- Web UI health (port 3000)
- Backend API (port 5000)
- RPC Daemon (port 8545)
- MarketFeed (port 4000)
- Disk usage (alert >80%)
- Memory usage (alert >90%)
- Docker service count

**Actions**:
- Logs all checks
- Auto-restarts failed services
- Alerts on resource issues

**Schedule**: Every 5 minutes

**Logs**: `/var/log/spiralcoin-monitor.log`

**Manual run**:
```bash
/root/spiralcoin-monitor.sh
```

---

### security-hardening.sh

**Purpose**: One-time security lockdown

**What it does**:
- Disables root password login
- Enables SSH key-only auth
- Installs fail2ban
- Enables automatic security updates
- Configures log rotation

**Usage** (run once):
```bash
/root/security-hardening.sh
```

⚠️ **Warning**: Run only once after SSH key setup

---

## 📋 Workflow Examples

### Initial Setup Workflow

```powershell
# 1. Verify everything is working
.\scripts\verify-deployment.ps1

# 2. Deploy automation
.\scripts\deploy-automation.ps1

# 3. Verify automation installed
ssh root@174.138.37.6
/root/status.sh
crontab -l
```

---

### Daily Operations Workflow

```powershell
# Morning check
.\scripts\quick-status.ps1

# If issues found
ssh root@174.138.37.6
docker compose logs -f
docker compose restart
```

---

### Troubleshooting Workflow

```powershell
# 1. Check status
.\scripts\quick-status.ps1

# 2. Full verification
.\scripts\verify-deployment.ps1

# 3. SSH to investigate
ssh root@174.138.37.6
/root/status.sh
tail -100 /var/log/spiralcoin-monitor.log
docker compose logs backend
```

---

## 🔐 Security Notes

**Server-side scripts**:
- All run as root (required for system operations)
- Logs stored in `/var/log/` (restricted access)
- Cron jobs run as root user

**Local scripts**:
- No elevated permissions required
- Network connectivity tests only
- No destructive operations

---

## 🆘 Common Issues

**"Cannot reach server"**
- Check server is online: `Test-NetConnection 174.138.37.6`
- Try alternate SSH port: `.\scripts\deploy-automation.ps1 -Port 2222`
- Check firewall rules

**"Service not responding"**
- Run: `ssh root@174.138.37.6`
- Check: `docker compose ps`
- Restart: `docker compose restart`

**"Automation not running"**
- Verify installation: `crontab -l`
- Check logs: `tail /var/log/spiralcoin-backup.log`
- Reinstall: Run `setup-automation.sh` again

---

## 📚 Related Documentation

- **OPERATIONS_AUTOMATION.md** - Full automation guide
- **QUICK_REFERENCE_CARD.md** - Essential commands
- **PRODUCTION_OPERATIONS_DASHBOARD.md** - Daily procedures
- **PRODUCTION_QUICK_REFERENCE.md** - Troubleshooting

---

## ✅ Script Checklist

Server-side (Bash):
- [x] setup-automation.sh - Master installer
- [x] backup-daily.sh - Daily backups
- [x] monitor-health.sh - Health checks
- [x] security-hardening.sh - Security lockdown

Local (PowerShell):
- [x] deploy-automation.ps1 - Deploy helper
- [x] verify-deployment.ps1 - Full verification
- [x] quick-status.ps1 - Quick dashboard
- [x] build_windows_mingw.ps1 - Windows build

---

**Status**: All scripts production-ready  
**Documentation**: Complete  
**Testing**: Verified on Ubuntu 22.04 LTS  
**Support**: Full automation with monitoring
