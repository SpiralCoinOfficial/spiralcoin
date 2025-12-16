#!/bin/bash
# Emergency Server Recovery Script
# Run this in DigitalOcean Droplet Console

echo "════════════════════════════════════════════════════════════"
echo "  SPIRALCOIN - EMERGENCY RECOVERY"
echo "════════════════════════════════════════════════════════════"
echo ""

# Step 1: Fix SSH Access
echo "Step 1: Restoring SSH access..."
systemctl status ssh | head -5
systemctl restart ssh
systemctl enable ssh
ufw allow 22/tcp
ufw reload
echo "✅ SSH service restarted and firewall configured"
echo ""

# Step 2: Verify SSH is listening
echo "Step 2: Verifying SSH is listening..."
netstat -tlnp | grep :22
echo ""

# Step 3: Fix Docker services
echo "Step 3: Restarting Docker services..."
cd /root/spiralcoin || cd /root/spiralcoin
docker compose ps
echo ""
echo "Restarting all containers..."
docker compose restart
sleep 5
docker compose ps
echo "✅ Docker services restarted"
echo ""

# Step 4: Deploy automation scripts
echo "Step 4: Deploying automation..."
bash <(curl -fsSL https://raw.githubusercontent.com/SpiralCoinOfficial/spiralcoin/main/scripts/setup-automation.sh)
echo ""

# Step 5: Verify everything
echo "Step 5: Final verification..."
echo ""
echo "Services status:"
docker compose ps
echo ""
echo "Cron jobs:"
crontab -l
echo ""
echo "SSH listening:"
netstat -tlnp | grep :22
echo ""

echo "════════════════════════════════════════════════════════════"
echo "  RECOVERY COMPLETE!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Test SSH from local machine:"
echo "  ssh root@174.138.37.6"
echo ""
echo "Test Web UI:"
echo "  curl http://174.138.37.6:3000"
echo ""
echo "Run status dashboard:"
echo "  /root/status.sh"
echo ""
