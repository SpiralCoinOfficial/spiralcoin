#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGETS_FILE="${ROOT_DIR}/EXCHANGE_PUBLISH.targets.json"
BUILD_DIR="${ROOT_DIR}/build"
HELPER_PUBKEY_PATH="${BUILD_DIR}/ssh-authorized-key.pub"

mkdir -p "$BUILD_DIR"

info() { printf 'ℹ %s\n' "$*"; }
success() { printf '✅ %s\n' "$*"; }
warn() { printf '⚠ %s\n' "$*"; }
error() { printf '❌ %s\n' "$*" >&2; }

[[ -f "$TARGETS_FILE" ]] || { error "Missing $TARGETS_FILE"; exit 1; }
command -v python3 >/dev/null 2>&1 || { error "python3 required"; exit 1; }
command -v ssh >/dev/null 2>&1 || { error "ssh required"; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { error "ssh-keygen required"; exit 1; }
command -v sshpass >/dev/null 2>&1 || { error "sshpass required (install and rerun)"; exit 1; }

KEY_PATH="${SPIRALCOIN_SSH_KEY_PATH:-}"
if [[ -z "$KEY_PATH" ]]; then
  KEY_PATH="${HOME}/.ssh/id_ed25519"
fi

mkdir -p "$(dirname "$KEY_PATH")"
chmod 700 "$(dirname "$KEY_PATH")"

if [[ ! -f "$KEY_PATH" ]]; then
  info "Generating SSH key: $KEY_PATH"
  ssh-keygen -t ed25519 -N '' -f "$KEY_PATH" -C 'spiralcoin-exchange' >/dev/null
fi

[[ -f "${KEY_PATH}.pub" ]] || { error "Missing public key: ${KEY_PATH}.pub"; exit 1; }
cp "${KEY_PATH}.pub" "$HELPER_PUBKEY_PATH"
success "Public key exported: $HELPER_PUBKEY_PATH"

PASSWORD="${SPIRALCOIN_SSH_PASSWORD:-}"
if [[ -z "$PASSWORD" ]]; then
  warn "SPIRALCOIN_SSH_PASSWORD is not set."
  warn "Manual remote install command: cat ${HELPER_PUBKEY_PATH} >> /root/.ssh/authorized_keys"
  exit 1
fi

mapfile -t TARGETS < <(python3 - "$TARGETS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
for t in data.get('targets', []):
    remote = (t.get('remote') or '').strip()
    if remote:
        print(remote)
PY
)

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  error "No remote targets found in $TARGETS_FILE"
  exit 1
fi

PUB64="$(base64 -w0 "${KEY_PATH}.pub")"
SUCCESS_COUNT=0

for remote in "${TARGETS[@]}"; do
  info "Installing SSH key on $remote"
  sshpass -p "$PASSWORD" ssh \
    -o PubkeyAuthentication=no \
    -o PreferredAuthentications=password \
    -o StrictHostKeyChecking=accept-new \
    "$remote" \
    "set -e; mkdir -p ~/.ssh; chmod 700 ~/.ssh; touch ~/.ssh/authorized_keys; PUB=\$(printf '%s' '$PUB64' | base64 -d); grep -qxF \"\$PUB\" ~/.ssh/authorized_keys || printf '%s\\n' \"\$PUB\" >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys"

  ssh -i "$KEY_PATH" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no "$remote" 'echo SSH_KEY_AUTH_OK' >/dev/null
  success "Key auth verified for $remote"
  SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
done

success "SSH bootstrap complete for ${SUCCESS_COUNT} target(s)"
