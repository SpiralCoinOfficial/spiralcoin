# SpiralCoin Ops & Security Overview

This document captures the key operational and security settings for the production deployment at <https://www.spiralcoin.net>.

## TLS & HTTPS

- TLS protocols: TLSv1.2, TLSv1.3
- HSTS: max-age=31536000; includeSubDomains; preload
- OCSP stapling: enabled in Nginx; availability depends on CA chain/responder
- Certificates: provisioned via Certbot (Let’s Encrypt) using fullchain.pem and privkey.pem

## Reverse Proxy (Nginx)

- Canonical redirect: apex -> www
- CSP: allows CDN charts and streaming
- SSE proxy: buffering disabled under `/api/market/stream/`
- WebSocket upgrade under `/ws`
- Health endpoint proxied

## Backend Security

- Helmet enabled
- CORS restricted to localhost and spiralcoin.net
- Rate limiting:
  - Global: configurable window and max via env
  - API: tighter limit, SSE endpoints skipped
  - Trust proxy enabled for correct client IPs

Environment vars (see `.env.example`):

```env
TRUST_PROXY=1
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=120
RATE_LIMIT_API_MAX=60
```

## Monitoring & Backups

- Monitoring script deployed on server (`/root/monitor-spiralcoin.sh`)
- Daily backups via cron (`/root/backup-spiralcoin.sh`)
- Optional external alerting: Healthchecks.io / UptimeRobot (env placeholders provided)

## Log Rotation

- Templates included under `scripts/logrotate_*.conf`
- Install on server via `/etc/logrotate.d/` and verify with `logrotate -d`

## Endpoints

- Health: `/health`
- Market API: `/api/market/*` (quotes, candles, pairs, search)
- SSE: `/api/market/stream/{quotes,candles}`
- Auth: `/api/auth/*` (demo), `/api/account`
- Supply: `/api/supply/*`

## Recovery

- Docker stack managed via systemd (`spiralcoin.service`)
- Restart: `docker compose restart`
- Logs: `docker compose logs -f --tail=100`

## Notes

- OCSP stapling may show “no response sent” depending on issuer; TLS/HSTS/CSP remain strong.
- Trading page is served from backend image to preserve exact layout.
