#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
mkdir -p "$BUILD_DIR"

BASE_URL="${BASE_URL:-http://localhost:5000}"
NAME="${NAME:-SpiralCoin}"
SYMBOL="${SYMBOL:-SPRC}"
PRIMARY_WALLET="${PRIMARY_WALLET:-0x928072b3A3A42e7dFD577a91167DfAa08f0E653E}"
SUPPLY_VAULT="${SUPPLY_VAULT:-0xSPRC1111111111111111111111111111SupplyVault}"
SUPPLY_MIN="${SUPPLY_MIN:-22000000000000}"
ETH_CONTRACT_ADDRESS="${ETH_CONTRACT_ADDRESS:-}"
BSC_CONTRACT_ADDRESS="${BSC_CONTRACT_ADDRESS:-}"

MANIFEST_PATH="${BUILD_DIR}/exchange_manifest.json"
ZIP_PATH="${BUILD_DIR}/SpiralCoin-Exchange-Pack.zip"

python3 - "$MANIFEST_PATH" <<'PY'
import json
import os
import sys

manifest_path = sys.argv[1]

name = os.environ.get("NAME", "SpiralCoin")
symbol = os.environ.get("SYMBOL", "SPRC")
base_url = os.environ.get("BASE_URL", "http://localhost:5000")
primary_wallet = os.environ.get("PRIMARY_WALLET", "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E")
supply_vault = os.environ.get("SUPPLY_VAULT", "0xSPRC1111111111111111111111111111SupplyVault")
supply_min = int(os.environ.get("SUPPLY_MIN", "22000000000000"))
eth_addr = os.environ.get("ETH_CONTRACT_ADDRESS", "").strip()
bsc_addr = os.environ.get("BSC_CONTRACT_ADDRESS", "").strip()

manifest = {
    "name": name,
    "symbol": symbol,
    "decimals": 18,
    "website": "https://spiralcoin.net",
    "logoUrl": "/public/assets/SpiralCoin_logo.png",
    "baseUrl": base_url,
    "endpoints": {
        "health": "/health",
        "status": "/api/status",
        "rpcProxy": "/api/rpc",
        "marketPrice": "/api/market/price",
        "wallet": "/api/wallet",
        "info": "/api/info",
        "exchangeInfo": "/api/exchange/info",
    },
    "supply": {
        "primaryWallet": primary_wallet,
        "supplyVault": supply_vault,
        "expectedMin": supply_min,
    },
}

contracts = {}
if eth_addr:
    contracts["ethereum"] = {
        "chain": "ethereum",
        "chainId": "0x1",
        "address": eth_addr,
    }
if bsc_addr:
    contracts["bsc"] = {
        "chain": "bsc",
        "chainId": "0x38",
        "address": bsc_addr,
    }
if contracts:
    manifest["contracts"] = contracts

with open(manifest_path, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

FILES=(
  "README_EXCHANGE_API_SPEC.md"
  "README_EXCHANGE_LISTING.md"
  "README_LOCAL_STACK.md"
  ".env.example"
  "public/exchange.html"
  "public/status.html"
  "public/index.html"
  "public/script.js"
  "public/style.css"
  "public/assets/SpiralCoin_logo.png"
  "public/trading_platform.html"
  "trading_platform.html"
)

INCLUDE=()
for rel in "${FILES[@]}"; do
  abs="${ROOT_DIR}/${rel}"
  if [[ -f "$abs" ]]; then
    INCLUDE+=("$rel")
  fi
done

if [[ ${#INCLUDE[@]} -eq 0 ]]; then
  echo "ERROR: no source files found to include in exchange pack" >&2
  exit 1
fi

python3 - "$ROOT_DIR" "$ZIP_PATH" "$MANIFEST_PATH" "${INCLUDE[@]}" <<'PY'
import os
import sys
import zipfile

root = sys.argv[1]
zip_path = sys.argv[2]
manifest_path = sys.argv[3]
include_rel = sys.argv[4:]

if os.path.exists(zip_path):
    os.remove(zip_path)

with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    for rel in include_rel:
        abs_path = os.path.join(root, rel)
        if os.path.isfile(abs_path):
            zf.write(abs_path, arcname=rel)
    zf.write(manifest_path, arcname="exchange_manifest.json")

print(zip_path)
PY

echo "Exchange pack created: ${ZIP_PATH}"
echo "Included files:"
for rel in "${INCLUDE[@]}"; do
  echo " - ${ROOT_DIR}/${rel}"
done
echo " - ${MANIFEST_PATH} (as exchange_manifest.json)"
