# SpiralCoin Build Guide

## Quick Build Methods

### Option 1: Docker (Recommended - Most Reliable)
```bash
# Build Docker image
docker build -f Dockerfile.dev -t spiralcoin:latest .

# Run container
docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest
```

Or using docker-compose:
```bash
docker-compose -f docker-compose.build.yml up --build
```

### Option 2: Windows Native Build (MinGW)
```batch
# Run the batch script
build.bat

# Or manually with CMake + MinGW Makefiles
cmake -S . -B build -G "Unix Makefiles" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++
cd build
make
```

### Option 3: Linux/WSL2 Build
```bash
# Install dependencies (Ubuntu/Debian)
sudo apt-get install -y build-essential cmake g++ libssl-dev nlohmann-json3-dev

# Build
mkdir build && cd build
cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# Run
./spiralcoind
```

### Option 4: Using the shell script
```bash
bash build.sh
```

## Build Output

- **Executable**: `build/spiralcoind.exe` (Windows) or `build/spiralcoind` (Linux)
- **RPC Server**: Listens on `http://localhost:8545`
- **Data Files**: Stored in `data/` directory (git-ignored for security)

## Security Features

✓ Wallet addresses secured in `data/wallets.json` (git-ignored)
✓ Blockchain state in `data/blockchain.json` (git-ignored)
✓ Environment variables in `.env` (git-ignored)

## Troubleshooting

### Windows CMake Issues
- Ensure MinGW is installed: https://www.msys2.org/
- Use the batch script `build.bat` for simplicity
- Docker is the most reliable option on Windows

### Missing Dependencies
```bash
# Ubuntu/Debian
sudo apt-get install build-essential cmake libssl-dev nlohmann-json3-dev

# MSYS2/MinGW
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-openssl mingw-w64-x86_64-nlohmann-json
```

## Docker Build Tips

- First build may take 5-10 minutes due to base image and dependencies
- Subsequent builds are faster (cached layers)
- Use `--no-cache` flag to force full rebuild: `docker build --no-cache -f Dockerfile.dev -t spiralcoin:latest .`

## Testing the Build

```bash
# After building, test RPC endpoint
curl -X POST http://localhost:8545/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
```

Expected response:
```json
{"result": 1}
```

## Continuous Integration

For CI/CD pipelines, use the Docker option as it provides:
- Consistent build environment
- No environmental dependencies
- Easy deployment to registries
- Portable across platforms
