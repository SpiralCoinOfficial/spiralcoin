@echo off
REM SpiralCoin - Master Build Script
REM Automatically chooses the best build method for your system

setlocal enabledelayedexpansion
cd /d c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature

cls
echo ═══════════════════════════════════════════════════════════════════════════
echo                  SpiralCoin - Build Method Selection
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo Choose your preferred build method:
echo.
echo [1] Direct MinGW Compilation (Fastest, Windows-native)
echo     Command: DIRECT_BUILD.bat
echo     Time: 10-15 minutes
echo     Pros: No Docker needed, native binary
echo     Cons: Takes longer first time (httplib.h preprocessing)
echo.
echo [2] Docker Build (Most Reliable, Guaranteed to work)
echo     Command: DOCKER_BUILD.bat
echo     Time: 8-12 minutes (first build), 1-2 minutes (cached)
echo     Pros: Guaranteed consistency, pre-tested environment
echo     Cons: Requires Docker installation
echo.
echo [3] Linux/WSL2 Build (Fast on Linux)
echo     Command: bash build.sh
echo     Time: 5-10 minutes
echo     Pros: Very fast, native Linux tools
echo     Cons: Requires WSL2 or Linux environment
echo.
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo RECOMMENDATION:
echo.
echo For Windows users without Docker: Use Option [1]
echo     .\DIRECT_BUILD.bat
echo.
echo For maximum reliability: Use Option [2]
echo     .\DOCKER_BUILD.bat (requires Docker)
echo.
echo Enter your choice (1-3) or press Ctrl+C to cancel:
echo.

set /p choice="Your choice: "

if "%choice%"=="1" (
    echo.
    echo Starting Direct MinGW Compilation...
    echo.
    call DIRECT_BUILD.bat
) else if "%choice%"=="2" (
    echo.
    echo Starting Docker Build...
    echo.
    call DOCKER_BUILD.bat
) else if "%choice%"=="3" (
    echo.
    echo Starting Linux/WSL2 Build...
    echo.
    bash build.sh
) else (
    echo.
    echo Invalid choice. Exiting.
    exit /b 1
)
