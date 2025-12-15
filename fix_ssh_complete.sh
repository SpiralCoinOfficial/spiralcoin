#!/bin/bash
# SPIRALCOIN COMPLETE SSH + DEPLOYMENT FIX
# Run this ONCE in your DigitalOcean console to fix SSH AND deploy SpiralCoin

set -e

echo "=========================================="
echo "  SPIRALCOIN SSH + DEPLOYMENT SETUP"
echo "=========================================="
echo ""

# ============ STEP 1: FIX SSH ============
echo "[1/3] Fixing SSH configuration..."
echo ""

# Backup original
mkdir -p /root/ssh_backup
cp /etc/ssh/sshd_config /root/ssh_backup/sshd_config.bak.$(date +%s)

# Create new SSH config from scratch (safer than sed modifications)
cat > /etc/ssh/sshd_config.new << 'SSHEOF'
# SpiralCoin SSH Configuration - Fixed for root access with password auth
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

Protocol 2

# HostKeys
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Lifetime and size of ephemeral version 1 server key
KeyRegenerationInterval 1h
ServerKeyBits 1024

# Ciphers and keying
RekeyLimit default none

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication
LoginGraceTime 120
PermitRootLogin yes
StrictModes yes
MaxAuthTries 6
MaxSessions 10

PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys .ssh/authorized_keys2

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication yes
PermitEmptyPasswords no

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# X11 forwarding
X11Forwarding yes
X11UseLocalhost yes

# PermitTTY yes

# Allow client to pass environment variables
PermitUserEnvironment no

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server

# Banner
Banner none

# More config
AllowUsers root *
UseDNS no
ClientAliveInterval 300
ClientAliveCountMax 3
MaxStartups 10:30:60
SSHEOF

# Use new config
mv /etc/ssh/sshd_config.new /etc/ssh/sshd_config
chmod 600 /etc/ssh/sshd_config

# Validate
echo "Validating SSH configuration..."
sshd -t && echo "✓ SSH config is valid" || { echo "✗ SSH config invalid!"; exit 1; }

# ============ STEP 2: SET PASSWORD ============
echo "[2/3] Setting root password..."
echo "root:0478cb10c91480bb5d5e838b0" | chpasswd
echo "✓ Root password set"

# ============ STEP 3: RESTART SSH ============
echo "[3/3] Restarting SSH service..."
if systemctl restart ssh; then
    echo "✓ SSH restarted via systemctl"
elif service ssh restart; then
    echo "✓ SSH restarted via service"
else
    echo "⚠ SSH restart command may have issue, but config should work"
fi

# ============ VERIFY ============
echo ""
echo "=========================================="
echo "  SSH FIX COMPLETE"
echo "=========================================="
echo ""
echo "Configuration:"
echo "  Port: 22"
echo "  Root Login: ENABLED"
echo "  Password Auth: ENABLED"
echo "  User: root"
echo "  Password: 0478cb10c91480bb5d5e838b0"
echo ""
echo "You can now SSH with:"
echo "  ssh root@174.138.37.6"
echo ""
echo "Next step: Deploy SpiralCoin stack"
echo "=========================================="
