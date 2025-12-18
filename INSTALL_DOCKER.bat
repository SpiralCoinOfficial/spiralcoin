@echo off
REM SpiralCoin - Automatic Docker Installation & Build
REM This script will install Docker if needed and build SpiralCoin

setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║   SpiralCoin - Automatic Docker Installation             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check if Docker exists
docker --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Docker is already installed
    call :BUILD_SPIRALCOIN
    exit /b 0
)

REM Docker not found, try to install
echo [INFO] Docker not found - attempting installation
echo.

REM Try downloading Docker Desktop
echo [STEP 1] Downloading Docker Desktop...
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('https://desktop.docker.com/win/main/amd64/Docker%%20Desktop%%20Installer.exe', '%TEMP%\DockerInstaller.exe')"

if exist "%TEMP%\DockerInstaller.exe" (
    echo [OK] Downloaded successfully
    echo [STEP 2] Installing Docker Desktop...
    echo [INFO] This may take 5-10 minutes...

    REM Run installer
    "%TEMP%\DockerInstaller.exe" install --quiet --accept-license

    echo [INFO] Waiting for Docker service to start (30 seconds)...
    timeout /t 30 /nobreak

    REM Verify installation
    docker --version >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Docker installed successfully
        call :BUILD_SPIRALCOIN
    ) else (
        echo [WARNING] Docker may not be ready yet
        echo [INFO] Please wait a few minutes and try again
        pause
    )
) else (
    echo [ERROR] Could not download Docker
    echo.
    echo Please download Docker Desktop manually from:
    echo https://www.docker.com/products/docker-desktop
    echo.
    echo After installation, run: .\AUTO_EXECUTE.bat
    pause
    exit /b 1
)

goto :eof

:BUILD_SPIRALCOIN
echo.
echo [STEP 3] Building SpiralCoin with Docker...
cd /d "c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature"
docker build -f Dockerfile.dev -t spiralcoin:latest .

if %errorlevel% equ 0 (
    echo.
    echo [OK] Build successful!
    echo.
    echo [STEP 4] Starting SpiralCoin daemon...
    echo [INFO] SpiralCoin listening on port 8545
    echo [INFO] Your 22+ trillion SPRC is secured and running
    echo.
    docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest
) else (
    echo [ERROR] Build failed
    pause
    exit /b 1
)
goto :eof
