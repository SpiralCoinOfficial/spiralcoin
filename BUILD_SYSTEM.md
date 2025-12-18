# SpiralCoin Build System - Complete Guide

## Quick Start

### 🐳 Docker (Recommended - Works Everywhere)

```bash
docker build -f Dockerfile.dev -t spiralcoin:latest .
docker run -p 8545:8545 -v $(pwd)/data:/app/data spiralcoin:latest
```

### 🪟 Windows (Direct Build)

```batch
REM Option 1: Direct compilation (fastest)
build.bat

REM Option 2: CMake with compiler wrappers
cmake-build.bat
```

### 🐧 Linux/WSL2

```bash
bash build.sh
```

---

## Build Methods Details

### Method 1: Direct Build (Windows)

**File**: `build.bat`
**Time**: 5-15 minutes (depending on system)
**Requirements**: MinGW g++ installed
**Pros**: Fast, direct, no CMake complexity
**Cons**: Windows only

```batch
cd spiralcoin
build.bat
```

### Method 2: CMake with Wrappers (Windows)

**File**: `cmake-build.bat`
**Time**: 2-5 minutes
**Requirements**: CMake, MinGW
**Pros**: Uses CMake build system, parallelized
**Cons**: More complex setup

```batch
cd spiralcoin
cmake-build.bat
```

**How it works**:

- Creates compiler wrapper scripts (`gcc-wrapper.bat`, `g++-wrapper.bat`)
- Configures CMake with `COMPILER_FORCED` to bypass detection
- Uses Unix Makefiles generator with `mingw32-make`
- Compiles with 4-job parallelization

### Method 3: Docker (All Platforms)

**File**: `Dockerfile.dev`, `docker-compose.build.yml`
**Time**: 5-10 minutes (first build)
**Requirements**: Docker
**Pros**: Guaranteed consistency, no local dependencies, portable
**Cons**: Docker overhead (~500MB image)

```bash
# Single command
docker build -f Dockerfile.dev -t spiralcoin:latest .

# Or with compose
docker-compose -f docker-compose.build.yml up --build
```

### Method 4: Linux Shell Script

**File**: `build.sh`
**Time**: 3-10 minutes
**Requirements**: gcc, make, cmake, libssl-dev
**Pros**: Fast on Linux, standard tools
**Cons**: Linux/WSL only

```bash
bash build.sh
```

### Method 5: Manual CMake (All Platforms)

```bash
mkdir -p build
cd build
cmake -S .. -B . -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

---

## Build Artifacts

### Output Binary Locations

- **Windows**: `build/spiralcoind.exe`
- **Linux**: `build/spiralcoind`

### Size: ~3-5 MB (optimized Release build)

---

## Troubleshooting

### Windows CMake Issues

**Problem**: "The C compiler is not able to compile a simple test program"

**Solution**: Use `cmake-build.bat` instead - it includes compiler wrappers

```batch
cmake-build.bat
```

### Build Timeout

**Problem**: Compilation takes very long or seems to hang

**Solution**: Use Docker for faster, more reliable build

```bash
docker build -f Dockerfile.dev -t spiralcoin:latest .
```

### Missing Dependencies (Windows)

```batch
REM Install MSYS2
choco install msys2 -y

REM Or from: https://www.msys2.org/

REM In MSYS2 terminal:
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-make
```

### Missing Dependencies (Linux)

```bash
# Ubuntu/Debian
sudo apt-get install build-essential cmake g++ libssl-dev nlohmann-json3-dev

# Fedora
sudo dnf install gcc g++ cmake openssl-devel nlohmann-json-devel
```

---

## Running the Built Binary

### Start the SpiralCoin daemon

```bash
# Windows
build/spiralcoind.exe

# Linux
./build/spiralcoind
```

### Test RPC endpoint

```bash
curl -X POST http://localhost:8545/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
```

Expected response:

```json
{"result": 1}
```

---

## Docker Usage

### Build

```bash
docker build -f Dockerfile.dev -t spiralcoin:latest .
```

### Run

```bash
# Foreground (for testing)
docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest

# Background (production)
docker run -d --name spiralcoin -p 8545:8545 -v ./data:/app/data spiralcoin:latest

# With compose
docker-compose -f docker-compose.build.yml up -d
```

### View logs

```bash
docker logs -f spiralcoin
```

### Stop container

```bash
docker stop spiralcoin
docker rm spiralcoin
```

---

## Performance Comparison

| Method | First Build | Rebuild | Memory | Storage |
|--------|------------|---------|--------|---------|
| Direct (build.bat) | 10-15m | 2-5m | 500MB | 100MB |
| CMake (cmake-build.bat) | 5-10m | 1-2m | 800MB | 150MB |
| Docker | 8-12m | 1-2m | 1.2GB | 500MB |
| Linux (bash) | 5-10m | 1-3m | 400MB | 80MB |

---

## Build Configuration

### Debug Build

```bash
# CMake
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug

# Docker (modify Dockerfile.dev)
# Change: -DCMAKE_BUILD_TYPE=Release → Debug
```

### Release Build (Default)

```bash
# All methods use Release configuration
# Results in: ~3-5MB binary, optimized for performance
```

---

## CI/CD Integration

### GitHub Actions

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build with Docker
        run: docker build -f Dockerfile.dev -t spiralcoin:latest .
```

### GitLab CI

```yaml
build:
  image: docker:latest
  script:
    - docker build -f Dockerfile.dev -t spiralcoin:latest .
    - docker push registry.example.com/spiralcoin:latest
```

---

## Compiler Information

### Compiler Used

- **Windows**: MinGW g++ (x86_64-w64-mingw32)
- **Linux**: GCC/G++ (native)
- **Docker**: GCC from Ubuntu 24.04 base image

### Compiler Flags

```text
-std=c++20          # C++20 standard
-Wall -Wextra       # All warnings
-O3                 # Optimization level 3 (Release)
-pthread            # Threading support
-D_WIN32_WINNT=0x0A00  # Windows 10+ API level
```

---

## Security Notes

- ✅ Data stored in `data/` (git-ignored)
- ✅ Credentials in `.env` (git-ignored)
- ✅ No hardcoded secrets in source
- ✅ All wallets encrypted at runtime

---

## Next Steps

1. **Choose a build method** (Docker recommended for first-time)
2. **Run the build** using appropriate script
3. **Verify**: Check for `spiralcoind.exe` or `spiralcoind` in build/
4. **Test**: Run the binary and test RPC endpoint
5. **Deploy**: Use Docker for production deployment

---

For issues, refer to FINAL_STATUS.md or BUILD_GUIDE.md.
