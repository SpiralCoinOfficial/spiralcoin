#!/bin/bash
set -e

echo "[*] Building SpiralCoin..."
cd /c/Users/Trisha\ Dreyer/Documents/GitHub/spiralcoin.worktrees/copilot/implement-feature

# Ensure build directory exists
mkdir -p build

# Compile with proper flags for Windows
/mingw64/bin/g++ \
  -std=c++20 \
  -Wall \
  -I include \
  -D_WIN32_WINNT=0x0A00 \
  -D HAVE_EVMONE=0 \
  src/main.cpp \
  src/state_db_impl.cpp \
  src/dqve_calculator.cpp \
  src/evm_integration.cpp \
  -o build/spiralcoind.exe \
  -pthread \
  -lws2_32 \
  -lcrypt32 \
  -lssl \
  -lcrypto

echo "[✓] Build complete: build/spiralcoind.exe"
