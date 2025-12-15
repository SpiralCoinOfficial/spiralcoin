#!/usr/bin/env bash
# SpiralCoin - On-server production health check
set -euo pipefail

cd /root/spiralcoin

if ! command -v docker >/dev/null 2>&1; then
  echo "docker missing" >&2
  exit 1
fi

echo "=== docker compose ps ==="
docker compose ps

echo "=== HTTP checks ==="
check() {
  url="$1"
  name="$2"
  if curl -fsS --max-time 3 "$url" >/dev/null; then
    echo "OK $name ($url)"
  else
    echo "FAIL $name ($url)"
  fi
}

check "http://localhost:8545" "daemon rpc"
check "http://localhost:5000/health" "backend health"
check "http://localhost:4000/api/feed" "marketfeed"
check "http://localhost:3000" "web ui"
