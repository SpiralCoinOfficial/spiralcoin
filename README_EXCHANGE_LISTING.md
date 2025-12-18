# SpiralCoin Exchange Listing Pack

This guide summarizes endpoints and steps to prepare for exchange listing.

## Asset Basics

- **Name:** SpiralCoin
- **Symbol:** SPRC
- **RPC URL (public):** Use `/api/rpc` over HTTPS (e.g., `https://spiralcoin.net/api/rpc`). Internally, the backend forwards to the configured upstream `RPC_URL`.
- **Status Dashboard:** Homepage shows live status at `/` (see Network Status section)
- **Exchange Info Page:** `/exchange` or `/listing`

## Public API Endpoints

- **Health:** `/health` — returns `{ status, ts }`
- **Status:** `/api/status` — returns `{ rpcUrl, chainId, blockNumber, gasPriceWei, peerCount }` with fallbacks
- **RPC Proxy:** `/api/rpc` — POST JSON-RPC body forwarded to RPC URL
- **Market Price:** `/api/market/price` — current market price (from marketfeed)
- **Market Stream (SSE):** `/api/market/stream` — Server-Sent Events stream with `Content-Type: text/event-stream`; ~20 Hz updates; auto reconnect-friendly
- **Wallet:** `/api/wallet/...` — wallet operations
- **Aggregate Info:** `/api/exchange/info` — combines info and status into a single payload
 - **Auth:** `/api/auth/register`, `/api/auth/login` — JWT-based authentication
 - **User:** `/api/user/me`, `/api/user/wallet/my`, `/api/user/wallet/new` — JWT-protected user profile and wallet management

## Deployment

- **Local:** Use `START_LOCAL_STACK.ps1` task to start backend and (optionally) daemon
- **Docker Compose:** Run `DEPLOY_ALL_PROD.ps1` to build and start daemon, backend, marketfeed, and nginx
- **Remote SSL:** Run `REMOTE_SSL_SETUP.ps1` after DNS is configured to set up HTTPS via Let’s Encrypt

## Verification

- Run `VERIFY_LOCAL.ps1` to check:
  - `/health`
  - `/api/status`
  - `/api/market/price`
  - RPC `/api/rpc` with `getblockcount`
  - Supply verification at `/api/wallet/verify-supply` (expects ≥ 22,000,000,000,000 SPRC total across primary + vault)

### Supply & Vault

- **Primary Wallet:** `0x928072b3A3A42e7dFD577a91167DfAa08f0E653E`
- **Supply Vault:** `0xSPRC1111111111111111111111111111SupplyVault`
- **Expected Minimum Total:** `22,000,000,000,000` SPRC across the two addresses
- Endpoint: `/api/wallet/verify-supply` returns `{ ok, expectedMin, total, addresses[] }`

Example RPC check:

```bash
curl -s https://spiralcoin.net/api/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
```

Example supply verification:

```bash
# Default (PRIMARY_WALLET + SUPPLY_VAULT from env, min 22T)
curl -s https://spiralcoin.net/api/wallet/verify-supply | jq

# Custom addresses and threshold
curl -s "https://spiralcoin.net/api/wallet/verify-supply?addresses=0x928072b3A3A42e7dFD577a91167DfAa08f0E653E,0xSPRC1111111111111111111111111111SupplyVault&min=22000000000000" | jq
```

If needed, the daemon supports one-time seeding via `data/wallets.override.json` (applied on startup and then renamed) to initialize balances, including the vault allocation.

### Accounts & Dashboard

- **Pages:** `/login`, `/register`, `/dashboard` (served via backend; proxied by Nginx over HTTPS)
- **JWT:** Issued on register/login; send as `Authorization: Bearer <token>`
- **Create Address:** `POST /api/user/wallet/new` calls daemon RPC `getnewaddress`; if unavailable, backend may attempt EVM-compatible `personal_newAccount`.
- **List Balances:** `GET /api/user/wallet/my` returns associated addresses and current on-chain balances via daemon RPC `getbalance`.

Example SSE stream consumption:

```javascript
const es = new EventSource('https://spiralcoin.net/api/market/stream');
es.onmessage = (e) => {
  const data = JSON.parse(e.data);
  // { price, ts } — update chart/UI here
};
es.onerror = () => {
  // network hiccup: EventSource auto-reconnects
};
```

## Next Steps for Exchanges

- Provide this document and the `/exchange` page link
- Confirm RPC availability, peer count, and latest block are incrementing
- Share market feed details for price source if required
- Ensure branding, logo, and homepage are ready

> Note: If RPC daemon is not EVM-compatible, `/api/status` falls back to non-EVM calls and local chain length.
