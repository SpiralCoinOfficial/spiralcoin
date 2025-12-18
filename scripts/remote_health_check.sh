#!/usr/bin/env bash
# SpiralCoin - Remote Health Check
# Verifies core services and attempts recovery if needed.
set -euo pipefail
LOG_FILE=/var/log/spiralcoin-health.log
TS() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "[$(TS)] $*" | tee -a "$LOG_FILE"; }

cd /root/spiralcoin || true
OK=1

check_http() {
  local url="$1" name="$2"
  if curl -fsS --max-time 5 "$url" >/dev/null; then
    log "OK ${name}: $url"
  else
    log "WARN ${name} unreachable: $url"; OK=0
  fi
}

# Local service checks
check_http "http://127.0.0.1:5000/health" "Backend /health"
check_http "http://127.0.0.1:5000/api/status" "Backend /api/status"

# RPC check (JSON-RPC getblockcount via backend proxy)
if curl -fsS -m 5 -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}' \
  "http://127.0.0.1:5000/api/rpc" | grep -q 'result'; then
  log "OK RPC responded via backend /api/rpc"
else
  log "WARN RPC no response via backend /api/rpc"
  OK=0
fi

# nginx (public) via local
if curl -fsS -m 5 http://127.0.0.1/ >/dev/null; then
  log "OK nginx root on :80"
else
  log "WARN nginx not responding on :80"; OK=0
fi

# Attempt recovery if any check failed
if [[ "$OK" -ne 1 ]]; then
  log "ACTION restarting compose services"
  docker compose ps >> "$LOG_FILE" 2>&1 || true
  docker compose up -d >> "$LOG_FILE" 2>&1 || true
  sleep 5
  # Recheck backend
  if curl -fsS -m 5 http://127.0.0.1:5000/health >/dev/null; then
    log "RECOVERY backend healthy after restart"
  else
    log "RECOVERY backend still failing"
  fi
fi

log "Health check complete"
