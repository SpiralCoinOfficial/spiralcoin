#!/bin/bash
# SpiralCoin auto-start + wallet setup script

# --- Configuration ---
SPIRALCOIND="${SPIRALCOIND:-/root/spiralcoin/build/spiralcoind}"
SPIRALCOIN_CLI="${SPIRALCOIN_CLI:-/usr/local/bin/spiralcoind-cli}"
WALLET_NAME="main"
RPC_WAIT_INTERVAL=2
RPC_PORT="${RPC_PORT:-8545}"
API_PORT="${API_PORT:-5000}"
WALLET_ADDRESS="0x928072b3A3A42e7dFD577a91167DfAa08f0E653E"

# --- Step 1: Kill any existing SpiralCoin instances ---
killall spiralcoind 2>/dev/null || true

# --- Step 2: Start SpiralCoin daemon in background ---
echo "[*] Starting SpiralCoin daemon..."
nohup $SPIRALCOIND -daemon > ~/spiralcoin_daemon.log 2>&1 &
DAEMON_PID=$!
echo "[*] SpiralCoin daemon PID: $DAEMON_PID"

sleep 3

# --- Step 3: Wait until RPC is ready ---
echo "[*] Waiting for RPC server to be ready on port $RPC_PORT..."
TIMEOUT=30
ELAPSED=0
while ! $SPIRALCOIN_CLI getblockcount >/dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "[-] RPC server did not start within $TIMEOUT seconds"
        exit 1
    fi
    sleep $RPC_WAIT_INTERVAL
    ELAPSED=$((ELAPSED + RPC_WAIT_INTERVAL))
done
echo "[+] RPC ready on port $RPC_PORT!"

# --- Step 4: Create wallet if it doesn't exist ---
echo "[*] Setting up wallet..."
$SPIRALCOIN_CLI createwallet "$WALLET_NAME" >/dev/null 2>&1 || echo "[*] Wallet '$WALLET_NAME' already exists."

# --- Step 5: Set or show your pre-defined wallet address ---
echo "[*] Using wallet address: $WALLET_ADDRESS"

# --- Step 6: Generate a new address if you want an additional one ---
NEW_ADDRESS=$($SPIRALCOIN_CLI getnewaddress 2>/dev/null || echo "N/A")
echo "[*] New generated address: $NEW_ADDRESS"

# --- Step 7: Show wallet balance ---
BALANCE=$($SPIRALCOIN_CLI getbalance 2>/dev/null || echo "0")
echo "[*] Wallet balance: $BALANCE SPC"

# --- Step 8: Display service ports ---
echo ""
echo "[+] SpiralCoin services:"
echo "    - Blockchain RPC: http://127.0.0.1:$RPC_PORT"
echo "    - API Server: http://127.0.0.1:$API_PORT"
echo "    - Daemon PID: $DAEMON_PID"
echo "[*] SpiralCoin setup complete. Daemon is running in background."
