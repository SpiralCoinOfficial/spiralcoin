#!/bin/bash
# SpiralCoin - Automated Setup Script
# Installs backups, monitoring, and security hardening
# Run this once on server: bash setup-automation.sh

echo "======================================"
echo "  SpiralCoin Automation Setup"
echo "======================================"

# 1. Create directories
echo "[1/5] Creating directories..."
mkdir -p /root/spiralcoin-backups
mkdir -p /var/log/spiralcoin

# 2. Download scripts (from GitHub or local)
echo "[2/5] Setting up scripts..."
cat > /root/spiralcoin-backup.sh << 'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/root/spiralcoin-backups"
SPIRALCOIN_DIR="/root/spiralcoin"
MAX_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/spiralcoin-backup-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
echo "[$(date)] Starting backup..." >> /var/log/spiralcoin-backup.log
tar -czf "$BACKUP_FILE" "$SPIRALCOIN_DIR/data/" "$SPIRALCOIN_DIR/docker-compose.yml" "$SPIRALCOIN_DIR/.env" 2>> /var/log/spiralcoin-backup.log

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup OK: $BACKUP_FILE ($BACKUP_SIZE)" >> /var/log/spiralcoin-backup.log
    find "$BACKUP_DIR" -name "spiralcoin-backup-*.tar.gz" -mtime +$MAX_DAYS -delete
else
    echo "[$(date)] Backup FAILED!" >> /var/log/spiralcoin-backup.log
fi
BACKUP_SCRIPT

chmod +x /root/spiralcoin-backup.sh

cat > /root/spiralcoin-monitor.sh << 'MONITOR_SCRIPT'
#!/bin/bash
LOGFILE="/var/log/spiralcoin-monitor.log"
log_message() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"; }
log_message "Health check started"

timeout 3 curl -sf http://localhost:3000 > /dev/null || log_message "Web UI DOWN"
timeout 3 curl -sf http://localhost:5000/health > /dev/null || log_message "API DOWN"
timeout 3 curl -sf http://localhost:8545 > /dev/null || log_message "RPC DOWN"
timeout 3 curl -sf http://localhost:4000 > /dev/null || log_message "MarketFeed DOWN"

DISK=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
[ "$DISK" -gt 80 ] && log_message "Disk HIGH: ${DISK}%"

docker compose ps -q | wc -l | grep -q 4 || log_message "Not all services running"
log_message "Health check completed"
MONITOR_SCRIPT

chmod +x /root/spiralcoin-monitor.sh

# 3. Set up cron jobs
echo "[3/5] Setting up cron jobs..."
CRONTAB_FILE="/tmp/spiralcoin-cron"
cat > "$CRONTAB_FILE" << 'EOF'
# Daily backups at 2 AM
0 2 * * * /root/spiralcoin-backup.sh

# Health monitoring every 5 minutes
*/5 * * * * /root/spiralcoin-monitor.sh

# Restart failed services (every 10 minutes)
*/10 * * * * cd /root/spiralcoin && docker compose ps -q | xargs -r docker restart 2>/dev/null || true

# Weekly security updates (Sunday 3 AM)
0 3 * * 0 apt-get update && apt-get upgrade -y

# Clear old logs (monthly on 1st at 4 AM)
0 4 1 * * find /var/log -name "spiralcoin-*.log" -mtime +30 -delete
EOF

crontab "$CRONTAB_FILE"
rm "$CRONTAB_FILE"

# 4. Enable automatic updates
echo "[4/5] Enabling automatic security updates..."
apt-get install -y unattended-upgrades
systemctl enable unattended-upgrades

# 5. Create health status file
echo "[5/5] Setting up monitoring dashboard..."
cat > /root/status.sh << 'STATUS_SCRIPT'
#!/bin/bash
clear
echo "╔════════════════════════════════════════════════╗"
echo "║  SpiralCoin System Status                      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "Services:"
docker compose ps 2>/dev/null | tail -n +2
echo ""
echo "System Resources:"
echo "Disk:   $(df -h / | awk 'NR==2 {print $5}')"
echo "Memory: $(free -h | awk 'NR==2 {printf("%d%%\n", $3/$2*100)}')"
echo "CPU:    $(uptime | awk -F'load average:' '{print $2}')"
echo ""
echo "Recent Logs (last 5 entries):"
tail -5 /var/log/spiralcoin-monitor.log 2>/dev/null || echo "No logs yet"
echo ""
STATUS_SCRIPT

chmod +x /root/status.sh

echo ""
echo "======================================"
echo "  Automation Setup Complete!"
echo "======================================"
echo ""
echo "✅ Installed:"
echo "  • Daily backups (2 AM)"
echo "  • Health monitoring (every 5 min)"
echo "  • Automatic restarts (every 10 min)"
echo "  • Security updates (weekly)"
echo "  • Log rotation"
echo ""
echo "📊 Check Status:"
echo "  /root/status.sh"
echo ""
echo "📋 View Logs:"
echo "  tail -f /var/log/spiralcoin-monitor.log"
echo "  tail -f /var/log/spiralcoin-backup.log"
echo ""
echo "🔧 Manage Cron:"
echo "  crontab -l    (list jobs)"
echo "  crontab -e    (edit jobs)"
echo ""
