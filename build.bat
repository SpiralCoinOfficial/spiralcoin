@echo off
REM SpiralCoin Build Script for Windows MinGW

setlocal enabledelayedexpansion

echo [*] Building SpiralCoin with MinGW g++...

set "GCC_PATH=C:\msys64\mingw64\bin\g++.exe"
set "INCLUDE_DIR=include"
set "SRC_DIR=src"
set "BUILD_DIR=build"
set "OUTPUT=%BUILD_DIR%\spiralcoind.exe"

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

echo [*] Copying httplib.h to include directory...
if not exist "%INCLUDE_DIR%\httplib.h" (
    copy "%SRC_DIR%\httplib.h" "%INCLUDE_DIR%\httplib.h" >nul
)

echo [*] Compiling source files...
echo [*] Note: First compilation may take 5-15 minutes due to httplib.h header size
"%GCC_PATH%" ^
  -std=c++20 ^
  -Wall -Wextra ^
  -I "%INCLUDE_DIR%" ^
  -I "%SRC_DIR%" ^
  -D_WIN32_WINNT=0x0A00 ^
  -D HAVE_EVMONE=0 ^
  "%SRC_DIR%\main.cpp" ^
  "%SRC_DIR%\state_db_impl.cpp" ^
  "%SRC_DIR%\dqve_calculator.cpp" ^
  "%SRC_DIR%\evm_integration.cpp" ^
  -o "%OUTPUT%" ^
  -pthread ^
  -lws2_32 ^
  -lcrypt32

if %errorlevel% equ 0 (
    echo.
    echo [OK] Build successful!
    echo [OK] Output: %OUTPUT%
    if exist "%OUTPUT%" (
        for %%F in ("%OUTPUT%") do echo [OK] Size: %%~zF bytes
    )
    exit /b 0
) else (
    echo.
    echo [ERROR] Build failed with exit code %errorlevel%
    exit /b 1
)
