#!/bin/bash
# SpiralCoin - Automated Daily Backup Script
# Runs daily at 2 AM, keeps 7-day rolling backup
# Add to crontab: 0 2 * * * /root/spiralcoin-backup.sh

BACKUP_DIR="/root/spiralcoin-backups"
SPIRALCOIN_DIR="/root/spiralcoin"
MAX_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/spiralcoin-backup-$TIMESTAMP.tar.gz"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting SpiralCoin backup..." >> /var/log/spiralcoin-backup.log

# Create backup
tar -czf "$BACKUP_FILE" \
    "$SPIRALCOIN_DIR/data/" \
    "$SPIRALCOIN_DIR/docker-compose.yml" \
    "$SPIRALCOIN_DIR/.env" \
    2>> /var/log/spiralcoin-backup.log

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup successful: $BACKUP_FILE ($BACKUP_SIZE)" >> /var/log/spiralcoin-backup.log

    # Delete old backups (older than MAX_DAYS)
    find "$BACKUP_DIR" -name "spiralcoin-backup-*.tar.gz" -mtime +$MAX_DAYS -delete

    # Count remaining backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/spiralcoin-backup-*.tar.gz 2>/dev/null | wc -l)
    echo "[$(date)] Retained $BACKUP_COUNT backups (keeping $MAX_DAYS days)" >> /var/log/spiralcoin-backup.log
else
    echo "[$(date)] ERROR: Backup failed!" >> /var/log/spiralcoin-backup.log
    # Optional: Send alert email here
    # mail -s "SpiralCoin Backup Failed" your-email@example.com
fi

echo "[$(date)] Backup job completed" >> /var/log/spiralcoin-backup.log
