#!/bin/bash
# SpiralCoin auto-start + wallet setup script

# --- Configuration ---
SPIRALCOIND="/root/spiralcoin/build/spiralcoind"
SPIRALCOIN_CLI="/usr/local/bin/spiralcoind-cli"
WALLET_NAME="main"
RPC_WAIT_INTERVAL=2
WALLET_ADDRESS="YOUR_WALLET_ADDRESS_HERE"  # <-- replace with your actual address

# --- Step 1: Kill any existing SpiralCoin instances ---
sudo killall spiralcoind 2>/dev/null

# --- Step 2: Start SpiralCoin daemon in background ---
nohup $SPIRALCOIND -daemon > ~/spiralcoin_daemon.log 2>&1 &

echo "[*] SpiralCoin daemon starting in background..."
sleep 3

# --- Step 3: Wait until RPC is ready ---
echo "[*] Waiting for RPC server to be ready..."
while ! $SPIRALCOIN_CLI getblockcount >/dev/null 2>&1; do
    sleep $RPC_WAIT_INTERVAL
done
echo "[*] RPC ready!"

# --- Step 4: Create wallet if it doesn't exist ---
$SPIRALCOIN_CLI createwallet "$WALLET_NAME" >/dev/null 2>&1 || echo "[*] Wallet '$WALLET_NAME' already exists."

# --- Step 5: Set or show your pre-defined wallet address ---
echo "[*] Using wallet address: $WALLET_ADDRESS"

# --- Step 6: Generate a new address if you want an additional one ---
NEW_ADDRESS=$($SPIRALCOIN_CLI getnewaddress)
echo "[*] New generated address: $NEW_ADDRESS"

# --- Step 7: Show wallet balance ---
BALANCE=$($SPIRALCOIN_CLI getbalance)
echo "[*] Wallet balance: $BALANCE"

echo "[*] SpiralCoin setup complete. Daemon is running in background."
