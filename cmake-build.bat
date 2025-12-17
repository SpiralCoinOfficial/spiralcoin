@echo off
REM SpiralCoin CMake Build Script - Fallback with direct g++ compilation option
REM Falls back to build.bat if CMake fails

setlocal enabledelayedexpansion

echo [*] SpiralCoin CMake Build
echo [*] Recommended: Use build.bat for faster, more reliable compilation
echo.

if exist build rmdir /s /q build >nul 2>&1
mkdir build

echo [*] Copying httplib.h to include directory...
if not exist include\httplib.h copy src\httplib.h include\httplib.h >nul

echo [*] Configuring CMake...

cd build

set "SRC_DIR=.."

REM Try CMake configuration with forced compiler settings
"C:\Program Files\CMake\bin\cmake.exe" ^
    "%SRC_DIR%" ^
    -G "Unix Makefiles" ^
    -DCMAKE_CXX_COMPILER="C:\msys64\mingw64\bin\g++.exe" ^
    -DCMAKE_C_COMPILER="C:\msys64\mingw64\bin\gcc.exe" ^
    -DCMAKE_MAKE_PROGRAM="C:\msys64\mingw64\bin\mingw32-make.exe" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_C_COMPILER_FORCED=TRUE ^
    -DCMAKE_CXX_COMPILER_FORCED=TRUE

if %errorlevel% neq 0 (
    echo.
    echo [WARN] CMake configuration failed
    echo [*] Falling back to direct g++ compilation...
    cd ..
    call build.bat
    exit /b !errorlevel!
)

echo [*] Building with make (4 parallel jobs)...
"C:\msys64\mingw64\bin\mingw32-make.exe" -j 4

if %errorlevel% equ 0 (
    echo.
    echo [OK] Build successful!
    cd ..
    if exist build\spiralcoind.exe (
        for %%F in (build\spiralcoind.exe) do echo [OK] Binary size: %%~zF bytes
    )
    exit /b 0
) else (
    echo [ERROR] Build failed
    exit /b 1
)

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
