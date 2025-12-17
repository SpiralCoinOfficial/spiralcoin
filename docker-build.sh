#!/bin/bash
# Docker build script for SpiralCoin
set -e

echo "[*] Building SpiralCoin with Docker..."

# Build the Docker image
docker build -f Dockerfile.dev -t spiralcoin:latest .

echo "[✓] Docker build complete"
echo "[*] To run: docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest"
