#!/usr/bin/env bash
# SpiralCoin Production Deployment - Simple Bash Version
# Run this directly on the server or via SSH

set -e

echo "=== SpiralCoin Production Deployment ==="
echo ""

# Step 1: Install Docker
echo "[*] Installing Docker..."
curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
echo "✓ Docker installed"

# Step 2: Clone repository
echo "[*] Cloning repository..."
cd /root
rm -rf spiralcoin
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
echo "✓ Repository cloned"

# Step 3: Start services
echo "[*] Building and starting services..."
docker compose up -d --build
echo "✓ Services deployed"

# Step 4: Wait for services to start
echo "[*] Waiting for services to initialize..."
sleep 10

# Step 5: Check service status
echo ""
echo "=== Service Status ==="
docker compose ps
echo ""

# Step 6: Verify RPC is responding
echo "[*] Testing RPC daemon..."
if timeout 5 curl -s http://localhost:8545 > /dev/null 2>&1; then
    echo "✓ RPC is responding"
else
    echo "⚠ RPC not responding yet (may still be starting)"
fi

echo ""
echo "=== Deployment Complete ==="
echo "Services running on:"
echo "  RPC:       http://localhost:8545"
echo "  Backend:   http://localhost:5000"
echo "  MarketFeed: http://localhost:4000"
echo "  Web UI:    http://localhost:3000"
echo ""
echo "Check logs: docker compose logs -f"
