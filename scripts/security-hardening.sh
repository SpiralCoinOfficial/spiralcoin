#!/bin/bash
# SpiralCoin - System Security Hardening
# Runs once to lock down the system
# Run this manually: bash /root/security-hardening.sh

echo "======================================"
echo "  SpiralCoin Security Hardening"
echo "======================================"

# 1. Disable root password login
echo "[1/6] Disabling root password login..."
sed -i 's/^PermitRootLogin yes/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sed -i 's/^#PermitRootLogin/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd

# 2. Set up automatic security updates
echo "[2/6] Enabling automatic security updates..."
apt-get install -y unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo 'APT::Periodic::AutocleanInterval "7";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo 'APT::Periodic::Unattended-Upgrade "1";' >> /etc/apt/apt.conf.d/50unattended-upgrades

# 3. Configure log rotation
echo "[3/6] Configuring log rotation..."
cat > /etc/logrotate.d/spiralcoin << 'EOF'
/var/log/spiralcoin-*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF

# 4. Harden SSH
echo "[4/6] Hardening SSH configuration..."
sed -i 's/^#PasswordAuthentication/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#LoginGraceTime.*/LoginGraceTime 30/' /etc/ssh/sshd_config
systemctl restart sshd

# 5. Enable firewall logging
echo "[5/6] Enabling firewall logging..."
ufw logging on
ufw logging high

# 6. Set up fail2ban
echo "[6/6] Installing fail2ban..."
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban

echo ""
echo "======================================"
echo "  Security Hardening Complete!"
echo "======================================"
echo ""
echo "Changes made:"
echo "  ✓ Root password login disabled"
echo "  ✓ Automatic security updates enabled"
echo "  ✓ Log rotation configured"
echo "  ✓ SSH hardened"
echo "  ✓ Firewall logging enabled"
echo "  ✓ Fail2ban installed"
echo ""
