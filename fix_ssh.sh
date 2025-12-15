#!/bin/bash
# Quick SSH Fix for SpiralCoin Server
# Run this on your server to fix SSH authentication permanently

set -euo pipefail

echo "=== SPIRALCOIN SSH FIX ==="
echo ""

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "ERROR: This script must be run as root."
  exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"

# Backup original
if [[ -f "$SSHD_CONFIG" ]]; then
  cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%s)"
else
  echo "ERROR: $SSHD_CONFIG not found."
  exit 1
fi

# Fix SSH configuration
echo "Configuring SSH for port 22..."

# Ensure Ports 22 and 2222 (dual listeners)
sed -i '/^[[:space:]]*#\?[[:space:]]*Port\b/d' "$SSHD_CONFIG"
{ printf '%s\n' "Port 22" "Port 2222"; } >> "$SSHD_CONFIG"

# Enable password authentication
sed -i 's/^[[:space:]]*#\?[[:space:]]*PasswordAuthentication[[:space:]].*/PasswordAuthentication yes/' "$SSHD_CONFIG"
grep -q '^PasswordAuthentication yes$' "$SSHD_CONFIG" || echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"

# Enable root login
sed -i 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin[[:space:]].*/PermitRootLogin yes/' "$SSHD_CONFIG"
grep -q '^PermitRootLogin yes$' "$SSHD_CONFIG" || echo "PermitRootLogin yes" >> "$SSHD_CONFIG"

# Allow pubkey auth too
sed -i 's/^[[:space:]]*#\?[[:space:]]*PubkeyAuthentication[[:space:]].*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
grep -q '^PubkeyAuthentication yes$' "$SSHD_CONFIG" || echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"

# Verify configuration
echo "Validating SSH configuration..."
if command -v sshd >/dev/null 2>&1; then
  sshd -t
elif [[ -x /usr/sbin/sshd ]]; then
  /usr/sbin/sshd -t
else
  echo "WARNING: sshd binary not found; skipping validation."
fi

# Restart SSH
echo "Restarting SSH service..."
if command -v systemctl >/dev/null 2>&1; then
  systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
  systemctl is-active --quiet sshd || systemctl is-active --quiet ssh || { echo "ERROR: SSH service failed to restart."; exit 1; }
else
  service sshd restart 2>/dev/null || service ssh restart 2>/dev/null || { echo "ERROR: Could not restart SSH service."; exit 1; }
fi

# Optionally set root password from env var
if [[ -n "${ROOT_PASSWORD:-}" ]]; then
  echo "Setting root password from ROOT_PASSWORD env var..."
  echo "root:${ROOT_PASSWORD}" | chpasswd
else
  echo "Root password unchanged (set ROOT_PASSWORD env var to update)."
fi

echo ""
echo "=== SSH FIX COMPLETE ==="
echo "✓ Ports: 22 and 2222"
echo "✓ Password auth: ENABLED"
echo "✓ Root login: ENABLED"
echo "✓ Pubkey auth: ENABLED"
