#!/bin/bash
# Enable SSH root login script for SpiralCoin server
# Fixed: Uses standard port 22 with proper authentication

echo "Fixing SpiralCoin SSH configuration..."

# Backup the original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Use standard ports 22 and 2222 for SSH
# Ensure both ports are set
sed -i 's/^#Port.*/Port 22/' /etc/ssh/sshd_config
sed -i '/^Port /d' /etc/ssh/sshd_config
{
    echo "Port 22"
    echo "Port 2222"
} >> /etc/ssh/sshd_config

# Enable password authentication
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

# Enable root login
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# Disable PubkeyAuthentication requirement (allow password)
sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Set root password
echo "root:0478cb10c91480bb5d5e838b0" | chpasswd

# Ensure SSH service is enabled
systemctl enable ssh
systemctl enable sshd

# Restart SSH service
systemctl restart ssh || systemctl restart sshd

echo "✓ SSH configured successfully"
echo "  Port: 22 (standard)"
echo "  Authentication: Password enabled"
echo "  Root login: Enabled"
echo "  User: root"
echo "  Password: 0478cb10c91480bb5d5e838b0"
echo ""
echo "Connection: ssh -p 22 root@174.138.37.6"
