#!/bin/bash
# Enable SSH root login script for SpiralCoin server

echo "Enabling SSH root login..."

# Backup the original config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Enable root login
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

# If not present, add it
if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# Restart SSH service
systemctl restart sshd

echo "SSH root login enabled. You should now be able to login via: ssh root@174.138.37.6"
echo "Make sure root has a password set: sudo passwd root"
