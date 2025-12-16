@echo off
REM =====================================================
REM SpiralCoin Complete Startup Script
REM Starts both C++ daemon and Node.js backend
REM =====================================================

cd /d "%~dp0"

echo.
echo ====================================================
echo   SpiralCoin Daemon & Backend Startup
echo ====================================================
echo.

REM Start Node.js Backend on Port 5000
echo [1/2] Starting Node.js Backend on port 5000...
start "SpiralCoin Backend" /MIN node server.js
timeout /t 2 /nobreak

REM Check if backend is running
powershell -Command "try { $r = Invoke-WebRequest http://127.0.0.1:5000/health -TimeoutSec 2; Write-Host '    ✅ Backend responding on port 5000' } catch { Write-Host '    ❌ Backend failed to start' }"

REM Optional: Start C++ Daemon on Port 8545
echo [2/2] C++ RPC Daemon (Optional)
echo    Note: spiralcoind.exe available in build\spiralcoind.exe
echo    Run: .\build\spiralcoind.exe
echo.

echo.
echo ====================================================
echo   Startup Complete
echo ====================================================
echo.
echo Available API Endpoints:
echo   • http://127.0.0.1:5000/health          - Health check
echo   • http://127.0.0.1:5000/api/stats       - Statistics
echo   • http://127.0.0.1:5000/api/blockchain  - Blockchain
echo   • http://127.0.0.1:5000/api/wallet      - Wallet
echo   • http://127.0.0.1:5000/api/market      - Market data
echo   • http://127.0.0.1:5000/api/mining      - Mining ops
echo.
echo Press Ctrl+C to stop backend
echo.

pause
