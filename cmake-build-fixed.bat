@echo off
REM SpiralCoin CMake Build Script - FIXED for MinGW
REM This script properly configures CMake with MinGW toolchain

setlocal enabledelayedexpansion

echo [*] SpiralCoin CMake Build (MinGW) - FIXED
echo [*] Cleaning old build...

if exist build rmdir /s /q build >nul 2>&1
mkdir build

echo [*] Copying httplib.h to include directory...
if not exist include\httplib.h copy src\httplib.h include\httplib.h >nul

cd build

set "SRC_DIR=.."
set "CMAKE_EXE=C:\Program Files\CMake\bin\cmake.exe"
set "MAKE_PROGRAM=C:\msys64\mingw64\bin\mingw32-make.exe"
set "CC_COMPILER=C:\msys64\mingw64\bin\gcc.exe"
set "CXX_COMPILER=C:\msys64\mingw64\bin\g++.exe"

echo [*] CMake Configuration...
echo [*] Using: Unix Makefiles generator
echo [*] CC: %CC_COMPILER%
echo [*] CXX: %CXX_COMPILER%
echo [*] Make: %MAKE_PROGRAM%
echo.

"%CMAKE_EXE%" ^
    -G "Unix Makefiles" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_C_COMPILER="%CC_COMPILER%" ^
    -DCMAKE_CXX_COMPILER="%CXX_COMPILER%" ^
    -DCMAKE_MAKE_PROGRAM="%MAKE_PROGRAM%" ^
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
    "%SRC_DIR%"

if %errorlevel% neq 0 (
    echo [!] CMake configuration FAILED
    cd ..
    echo [*] Falling back to direct build.bat...
    call build.bat
    exit /b %errorlevel%
)

echo.
echo [*] Building with mingw32-make (4 parallel jobs)...
"%MAKE_PROGRAM%" -j 4

if %errorlevel% equ 0 (
    echo [+] Build SUCCESSFUL!
    echo [+] Output: build\spiralcoind.exe
    cd ..
    exit /b 0
) else (
    echo [!] Build FAILED
    cd ..
    exit /b 1
)
