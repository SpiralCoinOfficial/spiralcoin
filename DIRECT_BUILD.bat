@echo off
REM SpiralCoin - Simplified Direct Build (Optimized for httplib.h)
REM This script compiles SpiralCoin with minimal dependencies

setlocal enabledelayedexpansion
cd /d c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature

cls
echo ═══════════════════════════════════════════════════════════════════════════
echo                 SpiralCoin - Optimized Direct Build
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo This script compiles SpiralCoin with optimizations for httplib.h
echo.

set "GCC=C:\msys64\mingw64\bin\g++.exe"
set "BUILD_DIR=build"
set "SRC_DIR=src"
set "INCLUDE_DIR=include"
set "OUTPUT=%BUILD_DIR%\spiralcoind.exe"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
echo [1/4] Setup complete
echo.

if not exist "%INCLUDE_DIR%\httplib.h" (
    copy "%SRC_DIR%\httplib.h" "%INCLUDE_DIR%\httplib.h" >nul
)
echo [2/4] Headers ready
echo.

echo [3/4] Compilation starting...
echo This may take 5-15 minutes on first build (httplib.h preprocessing)
echo Your system will be busy - this is NORMAL
echo.
echo DO NOT CLOSE THIS WINDOW - compilation is running
echo.
echo Starting in 5 seconds...
timeout /t 5 /nobreak
echo.
echo COMPILING...
echo.

REM Compile with minimal flags to reduce issues
"%GCC%" ^
  -std=c++20 ^
  -O2 ^
  -I"%INCLUDE_DIR%" ^
  -I"%SRC_DIR%" ^
  -D_WIN32_WINNT=0x0A00 ^
  "%SRC_DIR%\main.cpp" ^
  "%SRC_DIR%\state_db_impl.cpp" ^
  "%SRC_DIR%\dqve_calculator.cpp" ^
  "%SRC_DIR%\evm_integration.cpp" ^
  -o "%OUTPUT%" ^
  -lws2_32 ^
  -lcrypt32 ^
  -static-libgcc ^
  -static-libstdc++

echo.
if %errorlevel% equ 0 (
    echo [4/4] Build complete!
    echo.
    if exist "%OUTPUT%" (
        for %%F in ("%OUTPUT%") do set "SIZE=%%~zF"
        echo ═══════════════════════════════════════════════════════════════════════════
        echo                        ✅ BUILD SUCCESSFUL!
        echo ═══════════════════════════════════════════════════════════════════════════
        echo.
        echo Binary created: %OUTPUT%
        echo Size: !SIZE! bytes
        echo.
        echo Next: Run the daemon and test:
        echo   %OUTPUT%
        echo.
    ) else (
        echo ERROR: Binary not created
        exit /b 1
    )
) else (
    echo ═══════════════════════════════════════════════════════════════════════════
    echo                        ❌ BUILD FAILED
    echo ═══════════════════════════════════════════════════════════════════════════
    echo.
    echo Exit code: %errorlevel%
    echo.
    echo SOLUTION 1: Wait longer and try again
    echo   SpiralCoin compilation takes 5-15 minutes first time
    echo   Your CPU might be at 100%% - this is normal
    echo.
    echo SOLUTION 2: Use Docker (guaranteed to work):
    echo   .\DOCKER_BUILD.bat
    echo.
    echo SOLUTION 3: Run diagnostic to check system:
    echo   .\DIAGNOSTIC_BUILD_TEST.bat
    echo.
    exit /b 1
)
