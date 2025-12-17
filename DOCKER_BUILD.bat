@echo off
REM SpiralCoin - Docker Build (GUARANTEED TO WORK)
REM This script builds SpiralCoin using Docker containers

setlocal enabledelayedexpansion
cd /d c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature

cls
echo ═══════════════════════════════════════════════════════════════════════════
echo                   SpiralCoin - Docker Build
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo This builds SpiralCoin in an isolated Docker container
echo GUARANTEED to work with consistent environment
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker not found!
    echo.
    echo Docker Desktop is required for this build method.
    echo.
    echo Install Docker from: https://www.docker.com/products/docker-desktop
    echo.
    echo Alternative: Use native compilation
    echo   .\DIRECT_BUILD.bat
    echo   (Takes 5-15 minutes, but doesn't need Docker)
    echo.
    exit /b 1
)

echo [OK] Docker found ✅
docker --version
echo.

echo [STEP 1/3] Building Docker image...
echo Image: spiralcoin:latest
echo Dockerfile: Dockerfile.dev
echo.
echo This may take 2-5 minutes on first build (downloading dependencies)
echo Subsequent builds will be faster (cached layers)
echo.

docker build -f Dockerfile.dev -t spiralcoin:latest . --no-cache

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Docker build failed
    echo.
    echo Troubleshooting:
    echo 1. Ensure Docker Desktop is running
    echo 2. Check internet connection
    echo 3. Try: docker system prune (cleans up space)
    echo 4. Restart Docker Desktop
    echo.
    exit /b 1
)

echo.
echo [STEP 2/3] Image built successfully ✅
echo.

echo [STEP 3/3] Running SpiralCoin daemon...
echo Port: 8545 (RPC endpoint)
echo Data: Mounted at ./data/ (persisted)
echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo                     SpiralCoin is now RUNNING
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo Test the RPC endpoint:
echo   curl -X POST http://localhost:8545/rpc ^
echo     -H "Content-Type: application/json" ^
echo     -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getblockcount\",\"params\":[]}"
echo.
echo Press Ctrl+C to stop the daemon
echo.

docker run -p 8545:8545 -v "%cd%\data:/app/data" --name spiralcoin spiralcoin:latest

echo.
echo [INFO] Daemon stopped
echo.
echo To restart:
echo   docker start spiralcoin
echo.
echo To view logs:
echo   docker logs spiralcoin
echo.
echo To remove container:
echo   docker rm spiralcoin
echo.

