#!/usr/bin/env bash
# SpiralCoin - Production Health Watchdog
# Exit code 0 = healthy, non-zero = one or more checks failed.
set -euo pipefail

FAIL=0

ROOT_DIR="/root/spiralcoin"
if [[ -d "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" ]]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "FAIL docker is not installed or not on PATH" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "FAIL curl is required for health checks" >&2
  exit 1
fi

ok() { echo "OK   $*"; }
warn() { echo "WARN $*"; }
fail() { echo "FAIL $*"; FAIL=1; }

check_http() {
  local url="$1" name="$2"
  if curl -fsS --max-time 5 "$url" >/dev/null; then
    ok "$name ($url)"
  else
    fail "$name ($url)"
  fi
}

check_container() {
  local container="$1" required="$2"

  if ! docker inspect "$container" >/dev/null 2>&1; then
    if [[ "$required" == "required" ]]; then
      fail "container missing: $container"
    else
      warn "optional container missing: $container"
    fi
    return
  fi

  local state
  state="$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo unknown)"
  local health
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || echo unknown)"

  if [[ "$state" != "running" ]]; then
    fail "$container not running (state=$state)"
    return
  fi

  if [[ "$health" == "healthy" || "$health" == "none" ]]; then
    ok "$container running (health=$health)"
  else
    fail "$container unhealthy (health=$health)"
  fi
}

echo "=== docker compose ps ==="
docker compose ps || true

echo "=== container checks ==="
check_container "spiralcoin-daemon" "required"
check_container "spiralcoin-backend" "required"
check_container "spiralcoin-marketfeed" "required"
check_container "spiralcoin-nginx" "optional"

echo "=== backend/API checks ==="
check_http "http://127.0.0.1:5000/health" "backend health"
check_http "http://127.0.0.1:5000/api/status" "backend status"

RPC_PAYLOAD='{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
if curl -fsS --max-time 5 -H 'Content-Type: application/json' -d "$RPC_PAYLOAD" \
  "http://127.0.0.1:5000/api/rpc" | grep -q '"result"'; then
  ok "backend RPC proxy getblockcount"
else
  fail "backend RPC proxy getblockcount"
fi

echo "=== nginx checks (optional) ==="
if docker inspect spiralcoin-nginx >/dev/null 2>&1; then
  if curl -fsS -k --max-time 5 -H 'Host: spiralcoin.net' "https://127.0.0.1/health" >/dev/null; then
    ok "nginx https health"
  else
    fail "nginx https health"
  fi

  REDIRECT="$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 5 -H 'Host: www.spiralcoin.net' 'http://127.0.0.1:8080/health' || true)"
  if [[ "$REDIRECT" == 301*"https://spiralcoin.net/health"* ]]; then
    ok "nginx www->apex redirect"
  else
    fail "nginx www->apex redirect (got: $REDIRECT)"
  fi
else
  warn "nginx container not running; skipping nginx endpoint checks"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "\nRESULT: FAILED"
  exit 1
fi

echo "\nRESULT: PASSED"
exit 0
