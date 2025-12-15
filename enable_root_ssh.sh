#!/bin/bash
# Enable SSH root login script for SpiralCoin server
# Secure SSH configuration with standard settings

set -e

echo "[*] Configuring SSH security..."

# Backup the original config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s)

# Create temporary config file
TMP_CONFIG="/tmp/sshd_config.new"
sudo cp /etc/ssh/sshd_config "$TMP_CONFIG"

# Configure SSH port (use standard port 22 for security)
sudo sed -i 's/^#Port .*/Port 22/' "$TMP_CONFIG"
sudo sed -i 's/^Port [0-9]*/Port 22/' "$TMP_CONFIG"
if ! grep -q "^Port 22" "$TMP_CONFIG"; then
    echo "Port 22" | sudo tee -a "$TMP_CONFIG" > /dev/null
fi

# Enable password authentication for root
sudo sed -i 's/^#PermitRootLogin .*/PermitRootLogin yes/' "$TMP_CONFIG"
sudo sed -i 's/^PermitRootLogin no/PermitRootLogin yes/' "$TMP_CONFIG"
if ! grep -q "^PermitRootLogin" "$TMP_CONFIG"; then
    echo "PermitRootLogin yes" | sudo tee -a "$TMP_CONFIG" > /dev/null
fi

# Enable password authentication
sudo sed -i 's/^#PasswordAuthentication .*/PasswordAuthentication yes/' "$TMP_CONFIG"
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' "$TMP_CONFIG"
if ! grep -q "^PasswordAuthentication" "$TMP_CONFIG"; then
    echo "PasswordAuthentication yes" | sudo tee -a "$TMP_CONFIG" > /dev/null
fi

# Restrict SSH to local network by default (security best practice)
if ! grep -q "^ListenAddress" "$TMP_CONFIG"; then
    echo "ListenAddress 0.0.0.0" | sudo tee -a "$TMP_CONFIG" > /dev/null
fi

# Set secure SSH protocol
if ! grep -q "^Protocol" "$TMP_CONFIG"; then
    echo "Protocol 2" | sudo tee -a "$TMP_CONFIG" > /dev/null
fi

# Apply the new configuration
sudo cp "$TMP_CONFIG" /etc/ssh/sshd_config
sudo rm "$TMP_CONFIG"

# Validate configuration before restart
echo "[*] Validating SSH configuration..."
if sudo sshd -t; then
    echo "[+] SSH configuration is valid"
else
    echo "[-] SSH configuration has errors. Restoring backup..."
    sudo cp /etc/ssh/sshd_config.bak.* /etc/ssh/sshd_config
    exit 1
fi

# Restart SSH service
echo "[*] Restarting SSH service..."
sudo systemctl restart sshd
sudo systemctl enable sshd

# Set root password if provided
if [ -n "${ROOT_PASSWORD:-}" ]; then
    echo "root:${ROOT_PASSWORD}" | sudo chpasswd
    echo "[+] Root password has been set"
else
    echo "[!] ROOT_PASSWORD environment variable not set"
    echo "[!] Set password with: echo 'root:PASSWORD' | sudo chpasswd"
fi

echo "[+] SSH configuration complete"
echo "[*] SSH Port: 22 (standard)"
echo "[*] Root Login: Enabled"
echo "[*] Password Auth: Enabled"
echo ""
echo "[SECURITY WARNING]"
echo "- Change root password immediately after first login"
echo "- Consider using SSH keys instead of password authentication"
echo "- Restrict SSH access via firewall to trusted IPs"
echo "- Change SSH port if server is exposed to internet"
