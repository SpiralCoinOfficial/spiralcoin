#!/bin/bash
# SpiralCoin - COMPLETE PRODUCTION RECOVERY & DEPLOYMENT
# Run this ONCE in DigitalOcean console to fix everything and deploy SpiralCoin
# This script handles: SSH setup, firewall, Docker, services, health checks

set -eux

echo "======================================"
echo "  SpiralCoin Complete Recovery"
echo "======================================"

# ========== STEP 1: SYSTEM UPDATES & PACKAGES ==========
echo "[1/8] System updates and dependencies..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  openssh-server openssh-client curl wget git \
  ufw build-essential net-tools

# ========== STEP 2: SSH SETUP (Dual Port) ==========
echo "[2/8] Fixing SSH (ports 22, 2222)..."
mkdir -p /root/ssh_backup
cp /etc/ssh/sshd_config /root/ssh_backup/sshd_config.bak.$(date +%s) || true

cat > /etc/ssh/sshd_config << 'SSHEOF'
Port 22
Port 2222
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
Protocol 2
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
UsePAM yes
ChallengeResponseAuthentication no
LoginGraceTime 120
StrictModes yes
MaxAuthTries 6
MaxSessions 10
AcceptEnv LANG LC_*
X11Forwarding yes
PrintMotd no
Subsystem sftp /usr/lib/openssh/sftp-server
SSHEOF

sshd -t || { echo "ERROR: SSH config invalid!"; exit 1; }
systemctl enable ssh || true
systemctl enable sshd || true
systemctl restart ssh || systemctl restart sshd
echo "[✓] SSH configured and restarted"

# ========== STEP 3: FIREWALL ==========
echo "[3/8] Opening firewall..."
ufw allow 22/tcp || true
ufw allow 2222/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 8545/tcp || true
ufw allow 5000/tcp || true
ufw allow 4000/tcp || true
ufw allow 3000/tcp || true
ufw --force enable || true
echo "[✓] Firewall configured"

# ========== STEP 4: VERIFY SSH LISTENING ==========
echo "[4/8] Verifying SSH is listening..."
sleep 2
ss -tlnp | grep -E ':22|:2222' || { echo "ERROR: SSH not listening!"; journalctl -u ssh -n 50; exit 1; }
echo "[✓] SSH listening on ports 22 and 2222"

# ========== STEP 5: DOCKER INSTALL ==========
echo "[5/8] Installing Docker..."
curl -fsSL https://get.docker.com | sh > /dev/null 2>&1 || true
systemctl enable docker
systemctl restart docker
docker --version
echo "[✓] Docker installed"

# ========== STEP 6: CLONE/UPDATE SPIRALCOIN ==========
echo "[6/8] Cloning SpiralCoin repository..."
cd /root
rm -rf spiralcoin 2>/dev/null || true
git clone https://github.com/SpiralCoinOfficial/spiralcoin.git
cd spiralcoin
echo "[✓] Repository cloned"

# ========== STEP 7: DEPLOY SERVICES ==========
echo "[7/8] Deploying Docker services..."
docker compose down 2>/dev/null || true
docker compose up -d --build
sleep 15
echo "[✓] Services deployed"

# ========== STEP 8: HEALTH CHECK ==========
echo "[8/8] Running health checks..."
echo ""
echo "=== Docker Status ==="
docker compose ps

echo ""
echo "=== Service Health Checks ==="
check_service() {
  local url="$1"
  local name="$2"
  if timeout 3 curl -fsS "$url" >/dev/null 2>&1; then
    echo "  OK  $name ($url)"
  else
    echo "  ? $name ($url) - not responding yet"
  fi
}

check_service "http://localhost:8545" "RPC Daemon (8545)"
check_service "http://localhost:5000/health" "Backend API (5000)"
check_service "http://localhost:4000/api/feed" "MarketFeed (4000)"
check_service "http://localhost:3000" "Web UI (3000)"

echo ""
echo "======================================"
echo "  RECOVERY COMPLETE!"
echo "======================================"
echo ""
echo "Services available:"
echo "  SSH:        22 (or 2222)"
echo "  Web UI:     http://$(hostname -I | awk '{print $1}'):3000"
echo "  RPC:        http://$(hostname -I | awk '{print $1}'):8545"
echo "  Backend:    http://$(hostname -I | awk '{print $1}'):5000"
echo "  MarketFeed: http://$(hostname -I | awk '{print $1}'):4000"
echo ""
echo "Logs: cd /root/spiralcoin && docker compose logs -f"
echo "Status: docker compose ps"
echo ""
