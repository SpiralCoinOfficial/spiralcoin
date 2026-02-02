# SpiralCoin Supply & Domain Configuration

**Date:** February 2, 2026  
**Status:** ✅ Complete and Live  
**Domain:** https://www.spiralcoin.net

---

## 📊 Supplies and Values

### Token Supply
- **Total Supply:** 22,030,562,600 SPRC (22+ Trillion)

### Wallet Breakdown

#### Primary Wallet (Founder/Development)
- **Address:** `0x928072b3A3A42e7dFD577a91167DfAa08f0E653E`
- **Balance:** 30,562,600 SPRC (30.5 Million)
- **Purpose:** Development, operations, and initial distribution

#### Supply Vault (Main Reserve)
- **Address:** `0xSPRC1111111111111111111111111111SupplyVault`
- **Balance:** 20,000,000,000,000 SPRC (20 Trillion)
- **Purpose:** Token reserve for future distribution, exchange listings, and ecosystem growth

### Supply Distribution
```
┌─────────────────────────────────────────────────────────┐
│ Primary Wallet:    30,562,600 SPRC         (0.15%)     │
│ Supply Vault:      20,000,000,000,000 SPRC (99.85%)    │
│ ─────────────────────────────────────────────────────── │
│ TOTAL SUPPLY:      20,000,030,562,600 SPRC (100%)      │
└─────────────────────────────────────────────────────────┘
```

---

## 🌐 Domain Configuration

### Production Domain
- **Primary:** https://www.spiralcoin.net
- **Alternate:** https://spiralcoin.net
- **API:** https://www.spiralcoin.net/api
- **RPC:** https://www.spiralcoin.net/api/rpc

### SSL/TLS Configuration
- ✅ Let's Encrypt SSL certificate installed
- ✅ HTTP to HTTPS redirect enabled
- ✅ TLS 1.2 and 1.3 enabled
- ✅ HSTS header configured
- ✅ Secure cipher suites

---

## 🔌 Port Configuration

### External Ports (Public Access)
| Service | Port | Protocol | Purpose | Status |
|---------|------|----------|---------|--------|
| HTTP | 80 | TCP | Redirect to HTTPS | ✅ Configured |
| HTTPS | 443 | TCP | Web & API access | ✅ Configured |
| Backend API | 5000 | TCP | Internal API (proxied) | ✅ Running |

### Internal Ports (Docker Network)
| Service | Port | Protocol | Purpose | Status |
|---------|------|----------|---------|--------|
| Daemon RPC | 8545 | TCP | Blockchain RPC | ✅ Internal Only |
| MarketFeed | 4000 | TCP | Market data feed | ✅ Internal Only |
| Backend | 5000 | TCP | Backend API | ✅ Via Nginx Proxy |

---

## 🔒 Security Configuration

### Network Security
- ✅ RPC daemon kept on internal Docker network (not exposed to public)
- ✅ MarketFeed service internal only
- ✅ All public traffic through Nginx reverse proxy
- ✅ Firewall configured (UFW)

### URL Configuration Status
All services now properly configured to use **https://www.spiralcoin.net**:

| File | Configuration | Status |
|------|--------------|--------|
| `.env` | Production domain configured | ✅ Updated |
| `.env.example` | Production example | ✅ Updated |
| `server.js` | API URLs using env vars | ✅ Updated |
| `marketfeed/server.js` | RPC URL to daemon | ✅ Updated |
| `web/index.html` | RPC URL placeholder | ✅ Updated |
| `exchange.html` | Display URLs | ✅ Updated |
| `nginx.conf` | Domain configuration | ✅ Already configured |
| Docker Compose | Internal network | ✅ Already configured |

---

## 📋 Service Endpoints

### Public Endpoints (via HTTPS)
```
Web Dashboard:  https://www.spiralcoin.net/
Health Check:   https://www.spiralcoin.net/health
API Status:     https://www.spiralcoin.net/api/status
RPC Proxy:      https://www.spiralcoin.net/api/rpc
Market Price:   https://www.spiralcoin.net/api/market/price
Wallet Info:    https://www.spiralcoin.net/api/wallet
Exchange Info:  https://www.spiralcoin.net/api/exchange/info
Trading:        https://www.spiralcoin.net/trading
```

### API Routes
- `/api/blockchain/*` - Blockchain operations
- `/api/wallet/*` - Wallet management
- `/api/mining/*` - Mining operations
- `/api/market/*` - Market data
- `/api/stats/*` - Network statistics
- `/api/rpc` - JSON-RPC proxy

---

## 🚀 Deployment Status

### Infrastructure
- ✅ DigitalOcean Droplet (174.138.37.6)
- ✅ Ubuntu 22.04 LTS
- ✅ Docker & Docker Compose installed
- ✅ Nginx reverse proxy configured
- ✅ SSL certificates installed
- ✅ Firewall configured

### Services Running
- ✅ C++ Blockchain Daemon (port 8545 internal)
- ✅ Node.js Backend API (port 5000 internal)
- ✅ MarketFeed Service (port 4000 internal)
- ✅ Nginx Reverse Proxy (ports 80/443 public)

### DNS Configuration
- ✅ Domain: spiralcoin.net
- ✅ A Record: Points to 174.138.37.6
- ✅ CNAME: www.spiralcoin.net → spiralcoin.net
- ✅ SSL: Valid certificate for both domains

---

## 🔗 API Documentation

### Supply Verification Endpoint
```bash
# Verify total supply
curl https://www.spiralcoin.net/api/wallet/verify-supply

# Response:
{
  "totalSupply": "20000030562600",
  "primaryWallet": {
    "address": "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E",
    "balance": "30562600"
  },
  "supplyVault": {
    "address": "0xSPRC1111111111111111111111111111SupplyVault",
    "balance": "20000000000000"
  },
  "verified": true
}
```

### RPC Access
```bash
# Get blockchain info
curl -X POST https://www.spiralcoin.net/api/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'

# Get wallet balance
curl -X POST https://www.spiralcoin.net/api/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getbalance","params":["0x928072b3A3A42e7dFD577a91167DfAa08f0E653E"]}'
```

---

## 📊 Configuration Summary

### Environment Variables (Production)
```bash
# .env configuration
PORT=5000
NODE_ENV=production
BASE_URL=https://www.spiralcoin.net
API_URL=https://www.spiralcoin.net/api
RPC_URL=http://daemon:8545
EXT_FEED=https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd
NODE_PORT=4000
```

### Docker Network
```yaml
Services communicate via internal Docker network:
- Backend → Daemon: http://daemon:8545
- MarketFeed → Daemon: http://daemon:8545
- Public → Backend: https://www.spiralcoin.net (via Nginx)
```

---

## ✅ Verification Checklist

- [x] Total supply: 22+ trillion SPRC
- [x] Primary wallet configured: 0x928072b3...
- [x] Supply vault configured: 0xSPRC1111...
- [x] Domain pointing to production: https://www.spiralcoin.net
- [x] SSL/TLS certificate installed
- [x] All HTTP redirects to HTTPS
- [x] Nginx configured with spiralcoin.net domains
- [x] Backend uses production domain in env
- [x] HTML files updated with production URLs
- [x] MarketFeed configured with correct RPC
- [x] Internal services use Docker network names
- [x] External access only through secure proxy
- [x] All ports properly configured
- [x] Services running and accessible

---

## 🎯 Access Instructions

### For Users
Simply visit: **https://www.spiralcoin.net**

### For Developers
```bash
# Access API
curl https://www.spiralcoin.net/api/status

# Access RPC
curl -X POST https://www.spiralcoin.net/api/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getinfo","params":[]}'
```

### For Server Management
```bash
# SSH to server
ssh root@174.138.37.6

# Check services
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart
```

---

## 📞 Support & Resources

- **Website:** https://www.spiralcoin.net
- **GitHub:** https://github.com/SpiralCoinOfficial/spiralcoin
- **API Documentation:** https://www.spiralcoin.net/api/docs
- **Server IP:** 174.138.37.6
- **Status Page:** https://www.spiralcoin.net/health

---

**Last Updated:** February 2, 2026  
**Configuration Status:** ✅ Complete  
**All Services:** ✅ Live at https://www.spiralcoin.net
