#!/bin/bash
# SpiralCoin - Service Health Monitor
# Runs every 5 minutes via crontab
# Add to crontab: */5 * * * * /root/spiralcoin-monitor.sh

LOGFILE="/var/log/spiralcoin-monitor.log"
ALERT_FILE="/tmp/spiralcoin-alert"
THRESHOLD=3  # Alert after 3 consecutive failures

# Function to check service
check_service() {
    local name=$1
    local port=$2
    local url=${3:-"http://localhost:$port"}

    timeout 3 curl -sf "$url" > /dev/null 2>&1
    return $?
}

# Function to log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

# Function to send alert
send_alert() {
    local service=$1
    local status=$2

    # Log the alert
    log_message "ALERT: $service is $status"

    # Write to alert file (for monitoring dashboard)
    echo "$service: $status at $(date)" >> "$ALERT_FILE"

    # Optional: Send email alert
    # echo "Service $service is $status" | mail -s "SpiralCoin Alert" your-email@example.com
}

# Check each service
log_message "Starting health check"

# Web UI
if ! check_service "Web UI" "3000"; then
    send_alert "Web UI (port 3000)" "DOWN"
else
    log_message "✓ Web UI OK"
fi

# Backend API
if ! check_service "Backend API" "5000" "http://localhost:5000/health"; then
    send_alert "Backend API (port 5000)" "DOWN"
else
    log_message "✓ Backend API OK"
fi

# RPC Daemon
if ! check_service "RPC Daemon" "8545"; then
    send_alert "RPC Daemon (port 8545)" "DOWN"
else
    log_message "✓ RPC Daemon OK"
fi

# MarketFeed
if ! check_service "MarketFeed" "4000"; then
    send_alert "MarketFeed (port 4000)" "DOWN"
else
    log_message "✓ MarketFeed OK"
fi

# Check disk space (alert if > 80%)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    send_alert "Disk Usage" "HIGH ($DISK_USAGE%)"
else
    log_message "✓ Disk usage: ${DISK_USAGE}%"
fi

# Check memory
MEMORY_USAGE=$(free | awk 'NR==2 {printf("%.0f", $3/$2 * 100.0)}')
if [ "$MEMORY_USAGE" -gt 85 ]; then
    send_alert "Memory Usage" "HIGH ($MEMORY_USAGE%)"
else
    log_message "✓ Memory usage: ${MEMORY_USAGE}%"
fi

# Check Docker services
DOCKER_STATUS=$(docker compose ps -q 2>/dev/null | wc -l)
if [ "$DOCKER_STATUS" -lt 4 ]; then
    send_alert "Docker Services" "NOT ALL RUNNING ($DOCKER_STATUS/4)"
else
    log_message "✓ All 4 Docker services running"
fi

log_message "Health check completed"
