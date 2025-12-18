#!/bin/bash
# SpiralCoin Build Script for Linux/WSL2/MSYS2

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

echo "[*] SpiralCoin Build"

# Copy httplib header
if [ ! -f "include/httplib.h" ]; then
    cp src/httplib.h include/httplib.h
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

echo "[OK] Build complete"
