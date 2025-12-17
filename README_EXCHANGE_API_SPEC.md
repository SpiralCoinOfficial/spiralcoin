# SpiralCoin Exchange API Spec

This spec describes the minimal endpoints an exchange can use to integrate SpiralCoin.

## Endpoints
- **GET /health**
  - Response: `{ "status": "healthy", "ts": "2025-12-17T00:00:00Z" }`
- **GET /api/status**
  - Response: `{ "rpcUrl": string, "chainId": string, "blockNumber": number, "gasPriceWei": number, "peerCount": number }`
  - Notes: Falls back to non-EVM `getblockcount` and local chain length when Ethereum-style RPC methods aren’t available.
- **POST /api/rpc**
  - Body: Any JSON-RPC payload, e.g. `{ "jsonrpc": "2.0", "id": 1, "method": "getblockcount", "params": [] }`
  - Response: Forwarded JSON-RPC result from the daemon
- **GET /api/info**
  - Response: `{ "name": "SpiralCoin", "symbol": "SPIRAL", "chainId": string, "rpcUrl": string, "endpoints": { health, status, rpcProxy, marketPrice, wallet } }`
- **GET /api/exchange/info**
  - Response: Combined info + status payload:
    ```json
    {
      "name": "SpiralCoin",
      "symbol": "SPRC",
      "rpcUrl": "http://127.0.0.1:8545",
      "chainId": "0x1",
      "blockNumber": 12345,
      "peerCount": 8,
      "endpoints": {
        "health": "/health",
        "status": "/api/status",
        "rpcProxy": "/api/rpc",
        "marketPrice": "/api/market/price",
        "wallet": "/api/wallet"
      },
      "error": null
    }
    ```

## Frontend Pages
- **/exchange** — Exchange info page
- **/status.html** — Auto-refresh status dashboard
- **/trading_platform.html** — Trading UI

## Environment Variables
- `PORT` (default: `5000`)
- `RPC_URL` (default: `http://127.0.0.1:8545`; defaults to `/rpc` path if none specified)
- `NAME` (default: `SpiralCoin`)
- `SYMBOL` (default: `SPIRAL`)

## Example Requests
- Health:
  ```bash
  curl http://localhost:5000/health
  ```
- Status:
  ```bash
  curl http://localhost:5000/api/status
  ```
- RPC (getblockcount):
  ```bash
  curl -X POST http://localhost:5000/api/rpc \
       -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
  ```
