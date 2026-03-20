# Exchange Listing Workflow Guide

## Overview

This document describes the complete end-to-end workflow for preparing and publishing SpiralCoin for exchange listing.

**Current Status:** Repository-side automation is complete (commit 45238b0). Only two external inputs are required to achieve listing readiness.

## Workflow Steps

### 1. Pre-Publication Validation (Local)

Run the comprehensive readiness gate to validate all requirements:

```bash
npm run exchange:ready:gate
```

**Output Files:**
- `build/exchange-readiness-gate.txt` — Human-readable report
- `build/exchange-readiness-gate.json` — Machine-readable verdict

**What It Checks:**
1. ✅ Exchange pack builds successfully (`npm run exchange:pack:ready`)
2. ✅ All 39 deployment validations pass
3. ✅ All 44 E2E tests pass
4. ✅ All 4 local services are healthy
5. ⚠️ **BLOCKER:** SUPPLY_VAULT is not placeholder
6. ⚠️ **BLOCKER:** SSH authentication to remote publish target works

**Verdict:** `READY_FOR_EXCHANGE_LISTING`
- **YES** — Both blockers resolved; proceed to publish
- **NO** — Blockers present; see below for resolution

---

### 2. Resolve External Blockers

#### Blocker 1: SUPPLY_VAULT Address

**Problem:** SUPPLY_VAULT is currently a placeholder (`0xSPRC1111111111111111111111111111SupplyVault`).

**Resolution:**
1. Set the real ERC-20 supply vault contract address in `.env`:
   ```bash
   SUPPLY_VAULT=0x<your_real_vault_address>
   ```
2. Or update `.env.example` if deploying in production environment
3. Re-run the gate to verify:
   ```bash
   npm run exchange:ready:gate
   ```

#### Blocker 2: SSH Authentication

**Problem:** Cannot authenticate to remote publish target (`root@174.138.37.6`).

**Resolution:**
1. Ensure SSH key for `root@174.138.37.6` is loaded in your SSH agent:
   ```bash
   ssh-add ~/.ssh/id_rsa  # or your key path
   ```
2. (Optional) Test connectivity:
   ```bash
   ssh -o StrictHostKeyChecking=no root@174.138.37.6 echo "SSH OK"
   ```
3. Re-run the gate to verify:
   ```bash
   npm run exchange:ready:gate
   ```

---

### 3. Publish Exchange Pack (Once Blockers Resolved)

Once `npm run exchange:ready:gate` reports `READY_FOR_EXCHANGE_LISTING=YES`:

#### Preview First (Recommended)

```bash
npm run exchange:publish:dry-run
```

Sample output:
```
ℹ Publishing to: Primary
ℹ Remote: root@174.138.37.6 @ /root/spiralcoin/exchange-pack
⚠ [DRY-RUN] Would test SSH → root@174.138.37.6
⚠ [DRY-RUN] Would create dir → /root/spiralcoin/exchange-pack
⚠ [DRY-RUN] Would upload → /workspaces/spiralcoin/build/SpiralCoin-Exchange-Pack.zip

ℹ PUBLISH SUMMARY
⚠ DRY-RUN MODE
ℹ Exchange pack: SpiralCoin-Exchange-Pack.zip
ℹ Targets configured: 1
  • Primary → root@174.138.37.6
```

#### Perform Actual Publish

```bash
npm run exchange:publish
```

Or with verbose output:
```bash
npm run exchange:publish:verbose
```

**What It Does:**
1. Validates exchange pack ZIP exists
2. For each target in `EXCHANGE_PUBLISH.targets.json`:
   - Tests SSH connectivity
   - Creates remote directory
   - Uploads ZIP via SCP
   - Creates MANIFEST.json on remote

---

## Exchange Pack Contents

The exchange pack built by `npm run exchange:pack:ready` includes:

```
build/SpiralCoin-Exchange-Pack.zip
├── README_EXCHANGE_API_SPEC.md        # API documentation
├── exchange.html                       # Web UI specification
├── logo/                               # Branding assets
│   ├── spiralcoin-logo.svg
│   ├── spiralcoin-logo.png
│   └── spiralcoin-favicon.ico
├── documentation/                      # Full technical docs
│   ├── SECURITY.md
│   ├── API_ENDPOINTS.md
│   └── ...
└── spiralcoin_manifest.json           # Pack metadata
```

The manifest includes:
- API endpoints (blockchain, wallet, market, mining, stats)
- Port configuration (5000 for backend, 6379 for cache)
- Supported networks (mainnet, testnet)
- Smart contract addresses
- Fee structure
- Logo and branding URLs

---

## Configuration Files

### EXCHANGE_PUBLISH.targets.json

This file defines where the exchange pack is published:

```json
{
  "zipPath": "build/SpiralCoin-Exchange-Pack.zip",
  "targets": [
    {
      "name": "Primary",
      "remote": "root@174.138.37.6",
      "remoteDir": "/root/spiralcoin/exchange-pack",
      "zipName": "SpiralCoin-Exchange-Pack.zip"
    }
  ]
}
```

To add more targets, add entries to the `targets` array. Each target requires:
- `name` — Friendly name for the target
- `remote` — SSH user@host
- `remoteDir` — Directory path on remote
- `zipName` — ZIP filename at destination

### .env Configuration

Key variables for exchange listing:

```bash
# Smart contract addresses (ERC-20 / blockchain mainnet)
CONTRACT_ADDRESS=0x<spiralcoin_token>
SUPPLY_VAULT=0x<supply_vault>  # Must be REAL address (not placeholder)

# API configuration
API_PORT=5000
PUBLIC_API_URL=https://api.spiralcoin.io

# Exchange listing info
EXCHANGE_NAME=SpiralCoin
NETWORK=ethereum  # mainnet network
```

---

## Troubleshooting

### Gate Reports READY=NO

Check details in `build/exchange-readiness-gate.txt`:

```bash
cat build/exchange-readiness-gate.txt | tail -30
```

Or JSON format:
```bash
cat build/exchange-readiness-gate.json | jq
```

### SSH Authentication Fails During publish

1. Verify SSH key is available:
   ```bash
   ssh-add -l  # List loaded keys
   ```

2. Try SSH manually:
   ```bash
   ssh -v root@174.138.37.6 echo OK
   ```

3. If first-time connecting, accept host key:
   ```bash
   ssh-keyscan root@174.138.37.6 >> ~/.ssh/known_hosts
   ```

### Exchange Pack ZIP Doesn't Build

Run build step separately:
```bash
npm run exchange:pack:build
```

Check for errors in `build/spiralcoin_manifest.json`.

### Validations Fail

Run individual validation suites:

```bash
# Deployment checks (39 validations)
node scripts/validate-deployment.js

# E2E tests (44 tests)
node scripts/e2e-test.js

# Compose validation
npm test

# Production health check
npm run health:prod
```

---

## npm Script Reference

| Command | Purpose |
|---------|---------|
| `npm run exchange:pack:build` | Build ZIP archive |
| `npm run exchange:pack:validate` | Validate ZIP structure |
| `npm run exchange:pack:ready` | Build + validate |
| `npm run exchange:ready:gate` | Full readiness check (gate) |
| `npm run exchange:publish` | Publish to remote targets |
| `npm run exchange:publish:dry-run` | Preview publish (no upload) |
| `npm run exchange:publish:verbose` | Publish with verbose output |

---

## Timeline & Milestones

| Phase | Status | Command |
|-------|--------|---------|
| 1. Build Exchange Pack | ✅ Complete | `npm run exchange:pack:ready` |
| 2. Validate Locally | ✅ Complete | `npm run exchange:ready:gate` |
| 3. Resolve Blockers | 🔄 Waiting | Set SUPPLY_VAULT + SSH key |
| 4. Publish to Remote | ⏳ Blocked | `npm run exchange:publish` |
| 5. Exchanges List SpiralCoin | 📋 TBA | After submission + review |

---

## Repository References

- **Readiness Gate:** [scripts/exchange-readiness-gate.sh](../scripts/exchange-readiness-gate.sh)
- **Publish Script:** [scripts/publish-exchange-pack.sh](../scripts/publish-exchange-pack.sh)
- **Pack Builder:** [scripts/make-exchange-pack.sh](../scripts/make-exchange-pack.sh)
- **Pack Validator:** [scripts/validate-exchange-pack.sh](../scripts/validate-exchange-pack.sh)
- **Config:** [EXCHANGE_PUBLISH.targets.json](../EXCHANGE_PUBLISH.targets.json)
- **Readiness Report:** [EXCHANGE_READINESS_REPORT.md](../EXCHANGE_READINESS_REPORT.md)

---

**Last Updated:** March 20, 2026
**Latest Commit:** 45238b0 (Remote publish workflow added)
**Repo Status:** All automation complete; awaiting external inputs

