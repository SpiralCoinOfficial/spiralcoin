# SpiralCoin (SPRC) – Exchange Submission Pack

This document provides the essential information for listing SpiralCoin (SPRC) on centralized (CEX) and decentralized (DEX) exchanges.

## Asset Overview
- **Name:** SpiralCoin
- **Ticker:** SPRC
- **Decimals:** 8 (configurable depending on chain implementation)
- **Website:** https://spiralcoin.net
- **Explorer / Status:** https://spiralcoin.net (Network status shown on homepage)
- **Public RPC:** https://spiralcoin.net/api/rpc (JSON-RPC proxy)

## Chain & RPC
- **Chain ID:** Reported via `/api/status` and `/api/exchange/info` (EVM-style fallback)
- **Latest Block:** Exposed via `/api/status` (`blockNumber`) or RPC `getblockcount`
- **Peer Count:** `/api/status` (`peerCount`) when available
- **RPC Methods (common):** `getblockcount`, `getbalance`, `getwalletinfo`, `getnewaddress`, `sendtoaddress` (plus EVM-style fallbacks where supported)

## Public Endpoints
- **Health:** `/health` → `{ status, ts }`
- **Status:** `/api/status` → `{ rpcUrl, chainId, blockNumber, gasPriceWei, peerCount }`
- **RPC Proxy:** `/api/rpc` → POST JSON-RPC
- **Market Price:** `/api/market/price`
- **Market Stream (SSE):** `/api/market/stream` (~20 Hz updates)
- **Aggregate Info:** `/api/exchange/info`
- **Auth:** `/api/auth/register`, `/api/auth/login`
- **User:** `/api/user/me`, `/api/user/wallet/my`, `/api/user/wallet/new`
- **Trading (paper):** `/api/trade/markets`, `/api/trade/order`, `/api/trade/orders`

## Supply Proof
- **Primary Wallet:** 0x928072b3A3A42e7dFD577a91167DfAa08f0E653E
- **Supply Vault:** 0xSPRC1111111111111111111111111111SupplyVault
- **Expected Minimum Total:** 22,000,000,000,000 SPRC (across primary + vault)
- **Verification Endpoint:** `/api/wallet/verify-supply` → `{ ok, expectedMin, total, addresses[] }`

## Branding
- **Logo:** `public/assets/SpiralCoin_logo.png`
- **Colors:** Gold `#ffcc00`, Dark `#0f0f23`
- **Landing Page:** `public/index.html` → Overview branding and links

## Trading UI
- **Professional UI:** `public/trading_platform.html`
- **Live Charts:** Lightweight Charts with SSE and polling fallback
- **Orders (paper):** Integrated with `/api/trade/order` and `/api/trade/orders`

## Security & Infrastructure
- **Reverse Proxy:** Nginx with TLS (Let’s Encrypt)
- **HTTPS:** Enforced (HTTP → HTTPS redirect)
- **Rate Limiting:** Moderate per-IP limits on backend
- **Docker Compose:** Services for daemon, backend, marketfeed, nginx

## Contacts
- **Technical:** support@spiralcoin.net
- **Listing:** listing@spiralcoin.net

## Quick Checks
```bash
# Health
curl -s https://spiralcoin.net/health | jq

# Status
curl -s https://spiralcoin.net/api/status | jq

# RPC
curl -s https://spiralcoin.net/api/rpc -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}' | jq

# Supply
curl -s https://spiralcoin.net/api/wallet/verify-supply | jq

# Market stream
curl -sN https://spiralcoin.net/api/market/stream | head -n 5
```
