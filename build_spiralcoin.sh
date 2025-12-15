#!/usr/bin/env bash
set -euo pipefail
SRC_DIR="/root/spiralcoin"
echo "======================================="
echo "   SpiralCoin Direct Build Installer    "
echo "======================================="
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential libssl-dev libboost-all-dev git nlohmann-json3-dev
mkdir -p "$SRC_DIR/build"
cd "$SRC_DIR/build"
echo "[*] Compiling SpiralCoin..."
g++ -std=c++17 -I"$SRC_DIR/include" "$SRC_DIR/src/"*.cpp -o spiralcoind -pthread -D HAVE_EVMONE=0
echo "[*] Build complete! Run: ./spiralcoind"
