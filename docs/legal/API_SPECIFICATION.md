# API SPECIFICATION

**SpiralCoin REST & RPC API**

**Version**: 1.0
**Last Updated**: March 20, 2026
**Base URL**: https://api.spiralcoin.net or https://rpc.spiralcoin.net

---

## TABLE OF CONTENTS

1. [Authentication](#1-authentication)
2. [Health & Status Endpoints](#2-health--status-endpoints)
3. [Account Management](#3-account-management)
4. [Wallet Operations](#4-wallet-operations)
5. [Trading API](#5-trading-api)
6. [Market Data](#6-market-data)
7. [RPC Interface](#7-rpc-interface)
8. [Errors & Rate Limiting](#8-errors--rate-limiting)
9. [WebSocket & SSE Streams](#9-websocket--sse-streams)

---

## 1. AUTHENTICATION

### 1.1 JWT Token Authentication

**Endpoint**: `POST /api/auth/login`

**Request**:
```json
{
  "email": "user@example.com",
  "password": "secure_password"
}
```

**Response** (200 OK):
```json
{
  "ok": true,
  "user": {
    "id": "usr_123abc",
    "email": "user@example.com",
    "created_at": "2026-03-20T10:30:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 86400
}
```

**Usage**:
```bash
curl -H "Authorization: Bearer eyJhb..." https://api.spiralcoin.net/api/user/profile
```

**Token Validity**: 24 hours (expiration configurable)

### 1.2 API Key Authentication

**For programmatic access**, generate an API key:

**Endpoint**: `POST /api/auth/api-key/generate`

**Request** (authenticated):
```json
{
  "label": "My Trading Bot",
  "scopes": ["wallet:read", "trade:execute"]
}
```

**Response** (200 OK):
```json
{
  "ok": true,
  "api_key": "sk_live_abc123def456",
  "secret": "sk_secret_live_...",
  "created_at": "2026-03-20T10:30:00Z"
}
```

**Usage**:
```bash
curl -H "X-API-Key: sk_live_abc123def456" https://api.spiralcoin.net/api/trade/markets
```

### 1.3 No-Auth Endpoints

**Public endpoints** (no authentication required):
- `GET /health`
- `GET /api/status`
- `GET /api/market/price`
- `GET /api/market/stream` (SSE)
- `POST /api/rpc` (JSON-RPC, public methods only)

---

## 2. HEALTH & STATUS ENDPOINTS

### 2.1 Health Check

**Endpoint**: `GET /health`

**Response** (200 OK):
```json
{
  "status": "ok",
  "timestamp": "2026-03-20T10:30:00Z",
  "version": "1.0.0"
}
```

### 2.2 Platform Status

**Endpoint**: `GET /api/status`

**Response** (200 OK):
```json
{
  "ok": true,
  "blockchain": {
    "rpcUrl": "https://rpc.spiralcoin.net",
    "chainId": 1,
    "blockNumber": 123456,
    "blockTime": 10,
    "difficulty": 1048576,
    "networkHashrate": "1.2 PH/s"
  },
  "market": {
    "priceUsd": 0.001234,
    "priceEth": 0.00000042,
    "marketCapUsd": 27160000000,
    "volumeUsd24h": 5400000,
    "change24hPercent": 2.35
  },
  "trading": {
    "totalVolumeSPRC": 500000000,
    "activeOrders": 1234,
    "activePairs": 12
  },
  "infrastructure": {
    "apiUptime": 99.95,
    "nodeStatus": "healthy",
    "databaseLatency": "12ms",
    "cacheHitRatio": 0.94
  }
}
```

---

## 3. ACCOUNT MANAGEMENT

### 3.1 Register New Account

**Endpoint**: `POST /api/auth/register`

**Request**:
```json
{
  "email": "newuser@example.com",
  "password": "strong_password_123",
  "name": "John Doe"
}
```

**Response** (201 Created):
```json
{
  "ok": true,
  "user": {
    "id": "usr_new123",
    "email": "newuser@example.com",
    "name": "John Doe",
    "created_at": "2026-03-20T10:30:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 3.2 Get User Profile

**Endpoint**: `GET /api/user/profile`

**Authentication**: Required (JWT token)

**Response** (200 OK):
```json
{
  "ok": true,
  "user": {
    "id": "usr_123abc",
    "email": "user@example.com",
    "name": "John Doe",
    "kyc_status": "pending",
    "created_at": "2026-03-20T10:30:00Z",
    "last_login": "2026-03-20T15:45:00Z"
  }
}
```

### 3.3 Update Profile

**Endpoint**: `PUT /api/user/profile`

**Request**:
```json
{
  "name": "John Doe Updated",
  "preferredLanguage": "en"
}
```

**Response** (200 OK):
```json
{
  "ok": true,
  "user": { "id": "usr_123abc", "name": "John Doe Updated" }
}
```

---

## 4. WALLET OPERATIONS

### 4.1 Get My Wallets

**Endpoint**: `GET /api/user/wallet/my`

**Authentication**: Required

**Response** (200 OK):
```json
{
  "ok": true,
  "wallets": [
    {
      "id": "wallet_primary",
      "address": "0x1234567890abcdef...",
      "label": "My Main Wallet",
      "balance": {
        "sprc": "1000000",
        "usd": 1234.56
      },
      "created_at": "2026-03-20T10:30:00Z"
    }
  ]
}
```

### 4.2 Create New Wallet

**Endpoint**: `POST /api/user/wallet/new`

**Request**:
```json
{
  "label": "Trading Account"
}
```

**Response** (201 Created):
```json
{
  "ok": true,
  "wallet": {
    "id": "wallet_trading",
    "address": "0xabcdef1234567890...",
    "label": "Trading Account",
    "publicKey": "0x...",
    "created_at": "2026-03-20T10:30:00Z",
    "note": "Keep the private key secure and backed up."
  }
}
```

### 4.3 Send SPRC

**Endpoint**: `POST /api/user/wallet/send`

**Request**:
```json
{
  "from_wallet": "wallet_primary",
  "to_address": "0xrecipient...",
  "amount": "100",
  "memo": "Payment for trading fees"
}
```

**Response** (201 Accepted):
```json
{
  "ok": true,
  "transaction": {
    "id": "tx_abc123",
    "from": "0x1234567890abcdef...",
    "to": "0xrecipient...",
    "amount": "100",
    "status": "pending",
    "txHash": "0x123def456abc789...",
    "created_at": "2026-03-20T10:30:00Z",
    "confirmations": 0,
    "estimated_confirmation_time": "10s"
  }
}
```

### 4.4 Get Transaction History

**Endpoint**: `GET /api/user/wallet/transactions?wallet_id=wallet_primary&limit=50&offset=0`

**Response** (200 OK):
```json
{
  "ok": true,
  "transactions": [
    {
      "id": "tx_abc123",
      "from": "0x1234...",
      "to": "0x5678...",
      "amount": "100",
      "status": "confirmed",
      "txHash": "0x123def...",
      "block": 123456,
      "confirmations": 10,
      "timestamp": "2026-03-20T10:30:00Z"
    }
  ],
  "total": 150,
  "limit": 50,
  "offset": 0
}
```

### 4.5 Verify Supply

**Endpoint**: `GET /api/wallet/verify-supply`

**Authentication**: Optional

**Response** (200 OK):
```json
{
  "ok": true,
  "supplyVerification": {
    "totalSupply": 22000000000000,
    "verified": true,
    "addresses": [
      {
        "label": "Primary Wallet",
        "address": "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E",
        "balance": 11000000000000
      },
      {
        "label": "Supply Vault",
        "address": "0x9VaultAddress...",
        "balance": 11000000000000
      }
    ],
    "blockNumber": 123456,
    "timestamp": "2026-03-20T10:30:00Z"
  }
}
```

---

## 5. TRADING API

### 5.1 Get Trading Markets

**Endpoint**: `GET /api/trade/markets`

**Query Params**:
- `sort` (optional): `volume_desc`, `price_asc`, `change_24h_desc`
- `limit` (optional, default: 50)

**Response** (200 OK):
```json
{
  "ok": true,
  "markets": [
    {
      "pair": "SPRC/USD",
      "baseAsset": "SPRC",
      "quoteAsset": "USD",
      "lastPrice": 0.001234,
      "bid": 0.001230,
      "ask": 0.001238,
      "volume24h": 5400000,
      "change24hPercent": 2.35,
      "high24h": 0.001250,
      "low24h": 0.001190,
      "liquidity": "high"
    }
  ]
}
```

### 5.2 Place Order

**Endpoint**: `POST /api/trade/order`

**Authentication**: Required

**Request**:
```json
{
  "pair": "SPRC/USD",
  "type": "limit",
  "side": "buy",
  "quantity": "1000",
  "price": "0.001200",
  "timeInForce": "GTC"
}
```

**Response** (201 Created):
```json
{
  "ok": true,
  "order": {
    "id": "order_xyz789",
    "pair": "SPRC/USD",
    "side": "buy",
    "type": "limit",
    "quantity": "1000",
    "price": "0.001200",
    "status": "open",
    "filled": "0",
    "created_at": "2026-03-20T10:30:00Z"
  }
}
```

### 5.3 Get Order Status

**Endpoint**: `GET /api/trade/order/:order_id`

**Response** (200 OK):
```json
{
  "ok": true,
  "order": {
    "id": "order_xyz789",
    "status": "filled",
    "filled": "1000",
    "filledPrice": "0.001200",
    "totalValue": "1.20"
  }
}
```

### 5.4 Cancel Order

**Endpoint**: `DELETE /api/trade/order/:order_id`

**Response** (200 OK):
```json
{
  "ok": true,
  "message": "Order cancelled",
  "order": { "id": "order_xyz789", "status": "cancelled" }
}
```

---

## 6. MARKET DATA

### 6.1 Get Current Price

**Endpoint**: `GET /api/market/price`

**Query Params**:
- `pair` (optional): e.g., `SPRC/USD`, `SPRC/ETH`

**Response** (200 OK):
```json
{
  "ok": true,
  "price": {
    "timestamp": "2026-03-20T10:30:00Z",
    "usd": 0.001234,
    "eth": 0.00000042,
    "btc": 0.000000005
  }
}
```

### 6.2 Get Historical Price

**Endpoint**: `GET /api/market/history`

**Query Params**:
- `pair`: `SPRC/USD`
- `interval`: `1m`, `5m`, `15m`, `1h`, `4h`, `1d`
- `from`: Unix timestamp
- `to`: Unix timestamp (optional, default: now)


**Response** (200 OK):
```json
{
  "ok": true,
  "candles": [
    {
      "timestamp": 1711000000,
      "open": 0.001200,
      "high": 0.001250,
      "low": 0.001190,
      "close": 0.001234,
      "volume": 5000000
    }
  ]
}
```

### 6.3 Get Order Book

**Endpoint**: `GET /api/market/orderbook?pair=SPRC/USD&depth=50`

**Response** (200 OK):
```json
{
  "ok": true,
  "orderbook": {
    "timestamp": "2026-03-20T10:30:00Z",
    "pair": "SPRC/USD",
    "bids": [
      { "price": 0.001230, "quantity": 10000 },
      { "price": 0.001220, "quantity": 5000 }
    ],
    "asks": [
      { "price": 0.001238, "quantity": 15000 },
      { "price": 0.001250, "quantity": 8000 }
    ]
  }
}
```

---

## 7. RPC INTERFACE

### 7.1 JSON-RPC 2.0 Endpoint

**Endpoint**: `POST https://rpc.spiralcoin.net`

**Headers**:
```
Content-Type: application/json
```

### 7.2 Supported Methods

| Method | Parameters | Returns |
| --- | --- | --- |
| `getblockcount` | — | Block height |
| `getblockhash` | block_number | Block hash |
| `getblock` | hash, verbosity | Block details |
| `getbalance` | address, minconf | SPRC balance |
| `getnewaddress` | label* | New wallet address |
| `getwalletinfo` | — | Wallet information |
| `listwallets` | — | All wallet names |
| `sendtoaddress` | address, amount, comment* | TX hash |
| `gettransaction` | txid | Transaction details |
| `validateaddress` | address | Address validation |

### 7.3 Example: Get Balance

```bash
curl -s https://rpc.spiralcoin.net \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "getbalance",
    "params": ["0x928072b3A3A42e7dFD577a91167DfAa08f0E653E"]
  }'
```

**Response**:
```json
{
  "jsonrpc": "2.0",
  "result": {
    "balance": 11000000000000,
    "unconfirmed": 0
  },
  "id": 1
}
```

---

## 8. ERRORS & RATE LIMITING

### 8.1 Error Response Format

```json
{
  "ok": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field: amount",
    "details": { "field": "amount" }
  }
}
```

### 8.2 Common Error Codes

| Code | HTTP | Meaning |
| --- | --- | --- |
| `INVALID_REQUEST` | 400 | Missing/invalid parameters |
| `UNAUTHORIZED` | 401 | Missing/invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource state conflict |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

### 8.3 Rate Limiting

**Free Tier**:
- 1,000 requests per day
- 10 requests per second
- Rate limit headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

**Premium Tier** ($99/month):
- 100,000 requests per day
- 100 requests per second

**Response when rate-limited** (429):
```json
{
  "ok": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests",
    "retryAfter": 60
  }
}
```

---

## 9. WEBSOCKET & SSE STREAMS

### 9.1 Server-Sent Events (SSE) - Market Stream

**Endpoint**: `GET /api/market/stream`

**Connection**:
```bash
curl -H "Accept: text/event-stream" https://api.spiralcoin.net/api/market/stream
```

**Event Format**:
```
event: price_update
data: {"pair":"SPRC/USD","price":0.001234,"timestamp":"2026-03-20T10:30:00Z"}

event: order_update
data: {"order_id":"order_xyz789","status":"filled","timestamp":"..."}
```

### 9.2 WebSocket - Real-Time Order Updates

**Endpoint**: `wss://api.spiralcoin.net/ws`

**Connection**:
```javascript
const ws = new WebSocket('wss://api.spiralcoin.net/ws');
ws.send(JSON.stringify({
  "action": "subscribe",
  "channel": "orders",
  "token": "eyJhbGciOi..."
}));

ws.onmessage = (event) => {
  console.log(JSON.parse(event.data));
};
```

**Message Format**:
```json
{
  "event": "order_update",
  "data": {
    "order_id": "order_xyz789",
    "status": "filled",
    "filled": "1000",
    "timestamp": "2026-03-20T10:30:00Z"
  }
}
```

---

## APPENDIX A: AUTHENTICATION EXAMPLES

### Python
```python
import requests
import json

token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
headers = {"Authorization": f"Bearer {token}"}

response = requests.get(
    'https://api.spiralcoin.net/api/user/profile',
    headers=headers
)
print(response.json())
```

### JavaScript
```javascript
const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
const response = await fetch('https://api.spiralcoin.net/api/user/profile', {
  headers: { 'Authorization': `Bearer ${token}` }
});
const data = await response.json();
console.log(data);
```

---

## APPENDIX B: POSTMAN COLLECTION

A Postman collection (JSON) is available at:
`https://docs.spiralcoin.net/postman_collection.json`

Import into Postman for quick testing.

---

**API Version**: 1.0
**Last Updated**: March 20, 2026
**Status**: ✓ Production Ready

