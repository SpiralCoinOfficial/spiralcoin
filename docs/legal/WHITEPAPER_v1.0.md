# SpiralCoin (SPRC) Whitepaper v1.0

<!-- markdownlint-disable MD012 MD013 MD018 MD022 MD026 MD031 MD032 MD034 MD036 MD040 -->

**March 20, 2026**

## Executive Summary

SpiralCoin (SPRC) is a decentralized blockchain platform designed for high-throughput, low-latency trading and market data dissemination. Built with a dual-consensus architecture supporting both native SPRC transactions and EVM-compatible smart contracts, SpiralCoin enables efficient cross-chain asset trading and liquidity management.

**Token Details:**
- Symbol: SPRC
- Decimals: 8
- Total Supply: 22+ trillion SPRC (cold-stored in Primary Wallet + Supply Vault)
- Network: Decentralized with RPC endpoints and Nginx reverse proxy for public access
- Website: https://spiralcoin.net

---

## 1. Problem Statement

Current blockchain platforms face scalability challenges in high-frequency trading scenarios:
- Ethereum: ~12–15 TPS (transactions per second), high gas fees
- Bitcoin: ~7 TPS, settlement latency
- Traditional finance: Centralized, opaque market data

SpiralCoin addresses these gaps with:
1. **High throughput**: Target 1 block per ~10 seconds with optimized consensus
2. **Low latency**: Real-time market data streams (SSE, ~20 Hz updates)
3. **Interoperability**: Native SPRC + EVM compatibility for token swaps
4. **Transparency**: Public RPC, status endpoints, supply verification

---

## 2. Technical Architecture

### 2.1 Consensus Mechanism

- **Type**: Proof-of-Work (PoW) hybrid with configurable block times
- **Network**: Decentralized node operators maintain ledger
- **Block Time**: Target ~10 seconds (tunable via governance)
- **Finality**: Longest chain rule with 6-block confidence threshold

### 2.2 Dual-Mode Operation

#### Mode A: Native SPRC Transactions
- Direct SPRC transfer (via `sendtoaddress`, `getbalance`)
- Deterministic outputs
- Bitcoin-like UTXO model (internally)

#### Mode B: EVM Compatibility
- Smart contracts in Solidity
- ERC-20 token support (for cross-chain experiments)
- Compatible with MetaMask, Hardhat, Ethers.js

### 2.3 Infrastructure Stack

```
┌─ Public Web Interface (https://spiralcoin.net)
│   ├─ Trading Platform (live charts, paper trading)
│   ├─ Status Dashboard (/api/status)
│   └─ Market Stream (/api/market/stream)
│
├─ Reverse Proxy (Nginx)
│   ├─ TLS/HTTPS termination
│   ├─ Rate limiting per-IP
│   └─ Route management
│
├─ Backend (Node.js + Express)
│   ├─ Auth (/api/auth/register, /api/auth/login)
│   ├─ Trading (/api/trade/markets, /api/trade/order)
│   ├─ User Wallets (/api/user/wallet/my, /api/user/wallet/new)
│   └─ Supply Verification (/api/wallet/verify-supply)
│
├─ MarketFeed Service (WebSocket, SSE)
│   └─ Real-time price updates (~20 Hz)
│
└─ RPC Daemon (C++)
    ├─ Block validation & storage
    ├─ JSON-RPC interface (/api/rpc)
    ├─ Wallet management
    └─ Network consensus
```

---

## 3. Tokenomics

### 3.1 Supply Schedule

| Component | Amount | Status |
| --- | --- | --- |
| Total Supply | 22,000,000,000,000 SPRC | Fixed |
| Primary Wallet | 11,000,000,000,000 SPRC | Cold-stored |
| Supply Vault | 11,000,000,000,000 SPRC | Cold-stored (release schedule TBD) |
| Circulating (initial) | Based on vesting | Controlled release |

### 3.2 Emission Policy

- **No inflation**: Fixed cap of 22 trillion
- **Block rewards**: Configured per governance vote (initially TBD)
- **Vesting**: Locked period for vault supply (minimum 12 months at launch)
- **Burning**: Mechanism available via governance (burn transactions recorded on-chain)

### 3.3 Distribution

**Founder / Core Team**: 11T SPRC (Primary Wallet, cold-stored)
**Community / Liquidity Pool**: 11T SPRC (Supply Vault, vesting schedule)
**Exchanges / Partnerships**: Allocated from vesting schedule post-launch

---

## 4. Consensus & Governance

### 4.1 Network Changes

- **RFCs (Requests for Comments)**: Proposed on GitHub/forums
- **Voting**: Multi-party consensus from maintainers
- **Activation**: Scheduled block heights for network upgrades
- **Fallback**: Emergency patches via coordinated disclosure

### 4.2 Emergency Procedures

- **Security Issues**: Reported to security@spiralcoin.net (72-hour response target)
- **Coordinated Disclosure**: Fixes prepared privately, disclosed once mitigations deployed
- **Rollback Plan**: Defined for each major upgrade

---

## 5. Public Endpoints & APIs

### 5.1 Health & Status

```bash
GET /health
→ { "status": "ok", "ts": "2026-03-20T..." }

GET /api/status
→ { "rpcUrl": "...", "chainId": 1, "blockNumber": 123456,
    "gasPriceWei": "1000000000", "peerCount": 42 }
```

### 5.2 RPC Interface

```bash
POST /api/rpc
→ JSON-RPC 2.0 compatible
   Methods: getblockcount, getbalance, getwalletinfo, getnewaddress, sendtoaddress
```

### 5.3 Market Data

```bash
GET /api/market/price
→ { "usd": 0.001234, "ts": 1711000000 }

GET /api/market/stream (SSE)
→ Continuous price updates, ~20 Hz
```

### 5.4 Supply Verification

```bash
GET /api/wallet/verify-supply
→ { "ok": true, "expectedMin": 22000000000000,
    "total": 22000000000000,
    "addresses": ["0x928...", "0xSPRC..."] }
```

---

## 6. Security & Compliance

### 6.1 On-Chain Security

- **Consensus validation**: All transactions verified via PoW
- **Double-spend protection**: 6-block finality threshold
- **Replay protection**: Network ID in transaction signature
- **Smart contract audits**: Third-party reviews for high-value contracts (in progress)

### 6.2 Off-Chain Security

- **TLS/HTTPS**: All public endpoints encrypted
- **Rate limiting**: Per-IP throttling on API endpoints
- **JWT authentication**: Session tokens with expiration
- **Node operator vetting**: Community consensus on network peers

### 6.3 Compliance

- **KYC/AML**: User registration requires email verification (no phone/ID at MVP)
- **Transaction monitoring**: Flagging suspicious patterns (future enhancement)
- **Regulatory alignment**: Monitoring CFTC, SEC, FinCEN guidance
- **Data privacy**: GDPR-compliant data retention (details in Privacy Policy)

---

## 7. Roadmap

### Phase 1 (Q2 2026): Mainnet Launch
- ✓ RPC daemon + backend online
- ✓ Docker Compose deployment tested
- ✓ Public endpoints fully operational
- [ ] Community Discord initialized
- [ ] Trading volume thresholds (500K+ daily)

### Phase 2 (Q3 2026): DEX Listings
- [ ] Uniswap V3 liquidity pool (Ethereum)
- [ ] PancakeSwap listing (Binance Smart Chain)
- [ ] QuickSwap listing (Polygon)

### Phase 3 (Q4 2026): CEX Applications
- [ ] Mid-tier CEX submissions (Gate.io, KuCoin, Huobi)
- [ ] Full compliance documentation complete
- [ ] Security audit finalized

### Phase 4 (2027): Tier-1 Exchange Listings
- [ ] Binance listing application
- [ ] Coinbase listing application
- [ ] Kraken listing application

---

## 8. Risk Disclosures

### 8.1 Technology Risks

- **Software vulnerabilities**: Smart contract exploits, consensus bugs
- **Network partitions**: Temporary chain splits during major outages
- **Performance degradation**: High-load scenarios may exhibit latency

### 8.2 Market Risks

- **Volatility**: Cryptocurrency markets are highly volatile; SPRC price may fluctuate significantly
- **Liquidity**: Early-stage tokens may have limited trading depth
- **Regulatory uncertainty**: Cryptocurrency regulations evolving globally

### 8.3 Operational Risks

- **Key management failures**: Loss of private keys = irreversible fund loss
- **Exchange insolvency**: Centralized CEXs may fail; use non-custodial wallets when possible
- **Team availability**: Early-stage project dependent on small core team

---

## 9. Team & Contacts

| Role | Name | Contact |
| --- | --- | --- |
| Founder, Developer, Owner | Matthew Ian Dreyer | mattdreyer356@gmail.com |
| Technical Support | Team | support@spiralcoin.net |
| Exchange Listings | Team | listing@spiralcoin.net |
| Security Issues | Team | security@spiralcoin.net |

---

## 10. Legal Disclaimer

This whitepaper is for informational purposes only and does not constitute financial, legal, or investment advice. SpiralCoin token holders and users acknowledge the risks outlined in Section 8 and accept responsibility for their participation. The project team makes no warranties about future performance, regulatory status, or exchange listings.

---

**Whitepaper Version**: 1.0
**Date Published**: March 20, 2026
**Next Review**: Q2 2026

---

*For more information, visit https://spiralcoin.net or email listing@spiralcoin.net*
