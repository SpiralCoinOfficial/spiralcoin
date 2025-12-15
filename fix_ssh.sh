#!/bin/bash
# Quick SSH Fix for SpiralCoin Server
# Run this on your server to fix SSH authentication permanently

set -e

echo "=== SPIRALCOIN SSH FIX ==="
echo ""

# Backup original
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

# Fix SSH configuration
echo "Configuring SSH for port 22..."

# Ensure Port 22
grep -q "^Port 22" /etc/ssh/sshd_config || {
    sed -i '/^Port /d' /etc/ssh/sshd_config
    sed -i '1s/^/Port 22\n/' /etc/ssh/sshd_config
}

# Enable password authentication
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config || echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Enable root login
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config || echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Allow pubkey auth too
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
grep -q "^PubkeyAuthentication yes" /etc/ssh/sshd_config || echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config

# Verify configuration
echo "Validating SSH configuration..."
sshd -t || { echo "ERROR: Invalid SSH configuration!"; exit 1; }

# Restart SSH
echo "Restarting SSH service..."
systemctl restart ssh || systemctl restart sshd

# Set root password
echo "Setting root password..."
echo "root:0478cb10c91480bb5d5e838b0" | chpasswd

echo ""
echo "=== SSH FIX COMPLETE ==="
echo "✓ Port: 22 (standard)"
echo "✓ Password auth: ENABLED"
echo "✓ Root login: ENABLED"
echo ""
echo "Connect with:"
echo "  ssh -p 22 root@174.138.37.6"
echo "  ssh root@174.138.37.6"
echo ""
echo "Credentials:"
echo "  User: root"
echo "  Password: 0478cb10c91480bb5d5e838b0"
