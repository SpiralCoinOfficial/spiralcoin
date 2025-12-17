@echo off
REM SpiralCoin CMake Build Script
REM Simplified version that works reliably on Windows

setlocal enabledelayedexpansion

echo [*] SpiralCoin CMake Build
echo [*] Cleaning previous build...

if exist build rmdir /s /q build >nul 2>&1
mkdir build

echo [*] Configuring CMake...

cd build

set "SRC_DIR=.."

REM Run CMake configuration
"C:\Program Files\CMake\bin\cmake.exe" ^
    "%SRC_DIR%" ^
    -G "Unix Makefiles" ^
    -DCMAKE_CXX_COMPILER="C:\msys64\mingw64\bin\g++.exe" ^
    -DCMAKE_C_COMPILER="C:\msys64\mingw64\bin\gcc.exe" ^
    -DCMAKE_MAKE_PROGRAM="C:\msys64\mingw64\bin\mingw32-make.exe" ^
    -DCMAKE_BUILD_TYPE=Release

if %errorlevel% neq 0 (
    echo [ERROR] CMake configuration failed
    cd ..
    exit /b 1
)

echo [*] Building...
"C:\msys64\mingw64\bin\mingw32-make.exe" -j 4

if %errorlevel% equ 0 (
    echo.
    echo [OK] Build successful!
    dir spiralcoind.exe 2>nul && echo [OK] Binary: spiralcoind.exe
) else (
    echo [ERROR] Build failed
    exit /b 1
)

cd ..
endlocal
