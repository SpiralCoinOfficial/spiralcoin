# Install Docker Desktop on Windows

## Quick Install (Recommended)

### Option 1: Using Chocolatey (Easiest)
```powershell
# Run PowerShell as Administrator
choco install docker-desktop -y
```

### Option 2: Direct Download
1. Download: https://www.docker.com/products/docker-desktop
2. Run installer
3. Follow setup wizard
4. Restart computer when prompted

### Option 3: Windows Subsystem for Linux 2 (WSL2)
```powershell
# Run PowerShell as Administrator
wsl --install
wsl --install -d Ubuntu-24.04
# Then install Docker Desktop as normal
```

---

## Verify Installation

```powershell
docker --version
docker run hello-world
```

Expected output:
```
Docker version 27.x.x, build xxxxxx
Hello from Docker!
```

---

## Build & Run SpiralCoin with Docker

Once installed:

```bash
cd spiralcoin
docker build -f Dockerfile.dev -t spiralcoin:latest .
docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest
```

Test endpoint:
```bash
curl -X POST http://localhost:8545/rpc \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getblockcount","params":[]}'
```

---

## Troubleshooting

### "Docker daemon not running"
- Click Docker Desktop icon in system tray
- Wait for whale icon to be visible

### "Could not translate GUID"
- Update Windows to latest version
- Restart computer
- Try docker-desktop install again

### WSL2 not available
- Update Windows 10/11 to latest version
- Run: `wsl --update`

---

## Alternative: Use build.bat Instead

If Docker install is problematic, use native build:
```batch
build.bat
```

This takes 5-15 minutes but works without Docker.
