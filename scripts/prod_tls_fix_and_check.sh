#!/usr/bin/env bash
set -euo pipefail

# Usage: sudo ./scripts/prod_tls_fix_and_check.sh spiralcoin.net www.spiralcoin.net
DOMAINS=("$@")
EMAIL=${EMAIL:-admin@spiralcoin.net}

if [[ ${#DOMAINS[@]} -eq 0 ]]; then
  echo "Usage: $0 domain1 [domain2 ...]" >&2
  exit 2
fi

command -v certbot >/dev/null 2>&1 || {
  apt-get update && apt-get install -y certbot python3-certbot-nginx || true
}

# Issue or renew certs and configure Nginx
certbot --nginx $(printf ' -d %q' "${DOMAINS[@]}") --non-interactive --agree-tos -m "$EMAIL"

# Test Nginx and reload
nginx -t
systemctl reload nginx

PRIMARY="${DOMAINS[-1]}"

# Show quick TLS info
set +e
openssl s_client -connect "$PRIMARY:443" -servername "$PRIMARY" -showcerts -status </dev/null | sed -n '1,120p'
set -e

# Basic HTTPS check
curl -Iv "https://$PRIMARY/" 2>&1 | sed -n '1,40p'

# Optional SSE checks (quotes and candles)
echo "\n-- SSE quotes (first lines) --"
if command -v head >/dev/null 2>&1; then
  curl -N -H 'Accept: text/event-stream' "https://$PRIMARY/api/market/stream/quotes" | head -n 20 || true
else
  curl -N -H 'Accept: text/event-stream' "https://$PRIMARY/api/market/stream/quotes" | sed -n '1,20p' || true
fi

echo "\n-- SSE candles (SPRC 1m) --"
if command -v head >/dev/null 2>&1; then
  curl -N -H 'Accept: text/event-stream' "https://$PRIMARY/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" | head -n 20 || true
else
  curl -N -H 'Accept: text/event-stream' "https://$PRIMARY/api/market/stream/candles?asset=SPRC&vs=USD&interval=1m" | sed -n '1,20p' || true
fi

echo "\nDone. Review output above for chain, OCSP status, and SSE connectivity."