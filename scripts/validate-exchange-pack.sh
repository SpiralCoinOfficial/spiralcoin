#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZIP_PATH="${1:-${ROOT_DIR}/build/SpiralCoin-Exchange-Pack.zip}"

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: exchange pack zip not found: $ZIP_PATH" >&2
  exit 1
fi

python3 - "$ZIP_PATH" <<'PY'
import json
import re
import sys
import zipfile

zip_path = sys.argv[1]
required = {
    "README_EXCHANGE_API_SPEC.md",
    "README_EXCHANGE_LISTING.md",
    "public/exchange.html",
    "public/index.html",
    "public/assets/SpiralCoin_logo.png",
    "exchange_manifest.json",
}

with zipfile.ZipFile(zip_path, "r") as zf:
    names = set(zf.namelist())
    missing = sorted(required - names)
    if missing:
        print("ERROR: missing required files in exchange pack:")
        for m in missing:
            print(f" - {m}")
        sys.exit(1)

    manifest_raw = zf.read("exchange_manifest.json").decode("utf-8")
    manifest = json.loads(manifest_raw)

name = manifest.get("name")
symbol = manifest.get("symbol")
endpoints = manifest.get("endpoints", {})
supply = manifest.get("supply", {})

errors = []
warnings = []

if not name:
    errors.append("manifest.name is missing")
if not symbol:
    errors.append("manifest.symbol is missing")

for key in ("health", "status", "rpcProxy", "exchangeInfo"):
    if key not in endpoints:
        errors.append(f"manifest.endpoints.{key} is missing")

for key in ("primaryWallet", "supplyVault", "expectedMin"):
    if key not in supply:
        errors.append(f"manifest.supply.{key} is missing")

hex_addr = re.compile(r"^0x[a-fA-F0-9]{40}$")
primary = str(supply.get("primaryWallet", ""))
vault = str(supply.get("supplyVault", ""))

if not hex_addr.match(primary):
    warnings.append("manifest.supply.primaryWallet is not a canonical 0x40-hex address")
if not hex_addr.match(vault):
    warnings.append("manifest.supply.supplyVault is not a canonical 0x40-hex address")
if "0xSPRC" in vault or "SupplyVault" in vault:
    warnings.append("manifest.supply.supplyVault appears placeholder-like; set SUPPLY_VAULT for listing submissions")

if errors:
    print("ERROR: exchange pack validation failed")
    for e in errors:
        print(f" - {e}")
    sys.exit(1)

print("OK: exchange pack validation passed")
print(f"INFO: pack={zip_path}")
if warnings:
    print("WARNINGS:")
    for w in warnings:
        print(f" - {w}")
PY
