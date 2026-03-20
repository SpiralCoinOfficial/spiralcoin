#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
TARGETS_FILE="${ROOT_DIR}/EXCHANGE_PUBLISH.targets.json"
REPORT_PATH="${BUILD_DIR}/exchange-readiness-gate.txt"
JSON_REPORT_PATH="${BUILD_DIR}/exchange-readiness-gate.json"
SSH_HELPER_PUBKEY_PATH="${BUILD_DIR}/ssh-authorized-key.pub"

mkdir -p "$BUILD_DIR"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
PASS_MSGS=()
FAIL_MSGS=()
WARN_MSGS=()

add_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  PASS_MSGS+=("$1")
}

add_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAIL_MSGS+=("$1")
}

add_warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  WARN_MSGS+=("$1")
}

trim_value() {
  local s="$1"
  s="${s#\"}"
  s="${s%\"}"
  s="${s#\'}"
  s="${s%\'}"
  # trim leading/trailing whitespace
  s="$(printf '%s' "$s" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
  printf '%s' "$s"
}

run_check() {
  local label="$1"
  shift
  if "$@"; then
    add_pass "$label"
  else
    add_fail "$label"
  fi
}

# 1) Local pack + validations
if npm run exchange:pack:ready >/tmp/exchange_pack_ready.out 2>&1; then
  add_pass "exchange:pack:ready"
else
  add_fail "exchange:pack:ready"
fi

if node validate-deployment.js >/tmp/exchange_validate_deployment.out 2>&1; then
  add_pass "validate-deployment.js"
else
  add_fail "validate-deployment.js"
fi

if node e2e-test.js >/tmp/exchange_e2e.out 2>&1; then
  add_pass "e2e-test.js"
else
  add_fail "e2e-test.js"
fi

if npm test >/tmp/exchange_npm_test.out 2>&1; then
  add_pass "npm test"
else
  add_fail "npm test"
fi

if bash scripts/prod_health_check.sh >/tmp/exchange_health.out 2>&1; then
  add_pass "prod_health_check.sh"
else
  add_fail "prod_health_check.sh"
fi

# 2) Supply vault hard requirement for submission quality
# Resolution order: env var -> .env -> .env.example
SUPPLY_VAULT="${SUPPLY_VAULT:-}"
if [[ -f "${ROOT_DIR}/.env" ]]; then
  if [[ -z "$SUPPLY_VAULT" ]]; then
    SUPPLY_VAULT="$(grep -E '^SUPPLY_VAULT=' "${ROOT_DIR}/.env" | tail -n1 | cut -d'=' -f2- || true)"
  fi
fi
if [[ -z "$SUPPLY_VAULT" ]]; then
  SUPPLY_VAULT="$(grep -E '^SUPPLY_VAULT=' "${ROOT_DIR}/.env.example" | tail -n1 | cut -d'=' -f2- || true)"
fi
SUPPLY_VAULT="$(trim_value "$SUPPLY_VAULT")"

if [[ -z "$SUPPLY_VAULT" ]]; then
  add_fail "SUPPLY_VAULT value is missing"
elif [[ "$SUPPLY_VAULT" == *"SupplyVault"* || "$SUPPLY_VAULT" == 0xSPRC* ]]; then
  add_fail "SUPPLY_VAULT appears placeholder-like: ${SUPPLY_VAULT}"
elif [[ ! "$SUPPLY_VAULT" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  add_fail "SUPPLY_VAULT is not a valid EVM address: ${SUPPLY_VAULT}"
else
  add_pass "SUPPLY_VAULT is non-placeholder and format-valid"
fi

# 3) Remote publish authentication requirement
if [[ -f "$TARGETS_FILE" ]]; then
  SSH_KEY_PATH="${SPIRALCOIN_SSH_KEY_PATH:-}"
  if [[ -z "$SSH_KEY_PATH" && -f "${HOME}/.ssh/id_ed25519" ]]; then
    SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
  fi

  SSH_OPTS=(-o BatchMode=yes -o StrictHostKeyChecking=no)
  if [[ -n "$SSH_KEY_PATH" ]]; then
    if [[ -f "$SSH_KEY_PATH" ]]; then
      SSH_OPTS=(-i "$SSH_KEY_PATH" -o IdentitiesOnly=yes "${SSH_OPTS[@]}")
      if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
        cp "${SSH_KEY_PATH}.pub" "$SSH_HELPER_PUBKEY_PATH"
        add_warn "SSH helper public key exported: ${SSH_HELPER_PUBKEY_PATH}"
      fi
    else
      add_fail "Configured SPIRALCOIN_SSH_KEY_PATH not found: ${SSH_KEY_PATH}"
      SSH_KEY_PATH=""
    fi
  fi

  mapfile -t TARGETS < <(python3 - "$TARGETS_FILE" <<'PY'
import json
import sys
p = sys.argv[1]
with open(p, 'r', encoding='utf-8') as f:
    data = json.load(f)
for t in data.get('targets', []):
    r = t.get('remote')
    if r:
        print(r)
PY
)

  if [[ ${#TARGETS[@]} -eq 0 ]]; then
    add_warn "No targets in EXCHANGE_PUBLISH.targets.json"
  fi

  for remote in "${TARGETS[@]}"; do
    if ssh "${SSH_OPTS[@]}" "$remote" 'echo ok' >/tmp/exchange_ssh_check.out 2>&1; then
      add_pass "SSH auth to ${remote}"
    else
      if [[ -n "$SSH_KEY_PATH" ]]; then
        add_fail "SSH auth to ${remote} (using key ${SSH_KEY_PATH})"
      else
        add_fail "SSH auth to ${remote}"
      fi
    fi
  done

  if [[ -f "$SSH_HELPER_PUBKEY_PATH" ]]; then
    add_warn "To authorize this host key on remote: cat ${SSH_HELPER_PUBKEY_PATH} >> /root/.ssh/authorized_keys"
  fi
  if [[ $FAIL_COUNT -gt 0 ]]; then
    add_warn "If password auth is available, set SPIRALCOIN_SSH_PASSWORD and run: npm run exchange:ssh:bootstrap"
  fi
else
  add_fail "Missing EXCHANGE_PUBLISH.targets.json"
fi

READY="NO"
if [[ $FAIL_COUNT -eq 0 ]]; then
  READY="YES"
fi

{
  echo "Exchange Readiness Gate"
  echo "Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "READY_FOR_EXCHANGE_LISTING=${READY}"
  echo ""
  echo "Passes (${PASS_COUNT}):"
  for m in "${PASS_MSGS[@]}"; do echo " - ${m}"; done
  echo ""
  echo "Warnings (${WARN_COUNT}):"
  for m in "${WARN_MSGS[@]}"; do echo " - ${m}"; done
  echo ""
  echo "Failures (${FAIL_COUNT}):"
  for m in "${FAIL_MSGS[@]}"; do echo " - ${m}"; done
} > "$REPORT_PATH"

python3 - "$JSON_REPORT_PATH" "$READY" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT" <<'PY'
import json
import sys
path, ready, passes, warns, fails = sys.argv[1:]
obj = {
    "readyForExchangeListing": ready == "YES",
    "summary": {
        "passes": int(passes),
        "warnings": int(warns),
        "failures": int(fails),
    },
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(obj, f, indent=2)
    f.write("\n")
PY

echo "Gate report: ${REPORT_PATH}"
echo "Gate json:   ${JSON_REPORT_PATH}"
if [[ "$READY" == "YES" ]]; then
  echo "READY_FOR_EXCHANGE_LISTING=YES"
  exit 0
else
  echo "READY_FOR_EXCHANGE_LISTING=NO"
  exit 1
fi
