# SpiralCoin Exchange Listing Pack

This guide summarizes endpoints and steps to prepare for exchange listing.

## Asset Basics

- **Name:** SpiralCoin
- **Symbol:** SPRC
- **RPC URL:** Configurable via `.env` (`RPC_URL`), default `http://127.0.0.1:8545` (calls `/rpc` by default)
- **Status Dashboard:** `/status.html`
- **Exchange Info Page:** `/exchange` or `/listing`

## Public API Endpoints

- **Health:** `/health` — returns `{ status, ts }`
- **Status:** `/api/status` — returns `{ rpcUrl, chainId, blockNumber, gasPriceWei, peerCount }` with fallbacks
- **RPC Proxy:** `/api/rpc` — POST JSON-RPC body forwarded to RPC URL
- **Market Price:** `/api/market/price` — current market price (from marketfeed)
- **Wallet:** `/api/wallet/...` — wallet operations
- **Aggregate Info:** `/api/exchange/info` — combines info and status into a single payload

## Deployment

- **Local:** Use `START_LOCAL_STACK.ps1` task to start backend and (optionally) daemon
- **Docker Compose:** Run `DEPLOY_ALL_PROD.ps1` to build and start daemon, backend, marketfeed, and nginx
- **Remote SSL:** Run `REMOTE_SSL_SETUP.ps1` after DNS is configured to set up HTTPS via Let’s Encrypt

## Verification

- Run `VERIFY_LOCAL.ps1` to check:
  - `/health`
  - `/api/status`
  - `/api/market/price`
  - RPC `/rpc` with `getblockcount`

## Next Steps for Exchanges

- Provide this document and the `/exchange` page link
- Confirm RPC availability, peer count, and latest block are incrementing
- Share market feed details for price source if required
- Ensure branding, logo, and homepage are ready

> Note: If RPC daemon is not EVM-compatible, `/api/status` falls back to non-EVM calls and local chain length.
