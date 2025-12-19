#!/usr/bin/env bash
set -euo pipefail
BASE=${1:-https://www.spiralcoin.net}

status() {
  url="$1"; echo -n "[${url}] "; curl -s -o /dev/null -w "%{http_code}\n" "$url"; }

echo "== Basic pages =="
status "$BASE/"
status "$BASE/trading_platform.html"
status "$BASE/health"

echo "\n== Quotes/Candles =="
status "$BASE/api/market/quotes"
status "$BASE/api/market/candles?asset=ETH&vs=USD&interval=1h"

echo "\n== SSE (first lines) =="
echo "-- quotes --"
if command -v head >/dev/null 2>&1; then
  curl -N -H 'Accept: text/event-stream' "$BASE/api/market/stream/quotes" | head -n 10 || true
else
  curl -N -H 'Accept: text/event-stream' "$BASE/api/market/stream/quotes" | sed -n '1,10p' || true
fi

echo "-- candles (SPRC 1m) --"
if command -v head >/dev/null 2>&1; then
  curl -N -H 'Accept: text/event-stream' "$BASE/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" | head -n 10 || true
else
  curl -N -H 'Accept: text/event-stream' "$BASE/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" | sed -n '1,10p' || true
fi

echo "\n== TLS quick check =="
if command -v openssl >/dev/null 2>&1; then
  echo | openssl s_client -connect "$(echo "$BASE" | sed -E 's|https?://||;s|/.*||')":443 -servername "$(echo "$BASE" | sed -E 's|https?://||;s|/.*||')" -status -brief 2>/dev/null | sed -n '1,40p'
fi

echo "\nDone."