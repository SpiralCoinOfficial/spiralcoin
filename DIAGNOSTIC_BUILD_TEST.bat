@echo off
REM SpiralCoin - Diagnostic Build Test
REM Tests compiler and dependencies individually

setlocal enabledelayedexpansion
cd /d c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature

cls
echo ═══════════════════════════════════════════════════════════════════════════
echo                 SpiralCoin - Build Diagnostic Test
echo ═══════════════════════════════════════════════════════════════════════════
echo.

set "GCC=C:\msys64\mingw64\bin\g++.exe"
set "BUILD_DIR=build"

echo [TEST 1] Verify g++ exists and works
echo ─────────────────────────────────────────────────────────────────────────
if exist "%GCC%" (
    echo ✅ g++ found: %GCC%
) else (
    echo ❌ g++ NOT FOUND at: %GCC%
    echo Install MinGW-w64 from MSYS2
    exit /b 1
)
echo.

echo [TEST 2] Check g++ version
"%GCC%" --version
echo.

echo [TEST 3] Create simple test program
echo ─────────────────────────────────────────────────────────────────────────
cat > "%BUILD_DIR%\test.cpp" << EOF
#include <iostream>
int main() {
    std::cout << "Hello from SpiralCoin!" << std::endl;
    return 0;
}
EOF
echo ✅ Test file created: %BUILD_DIR%\test.cpp
echo.

echo [TEST 4] Compile simple test program
"%GCC%" -o "%BUILD_DIR%\test.exe" "%BUILD_DIR%\test.cpp" 2>&1
if %errorlevel% equ 0 (
    echo ✅ Simple compilation successful!
    echo.
    echo [TEST 5] Run test program
    "%BUILD_DIR%\test.exe"
    echo.
) else (
    echo ❌ Simple compilation FAILED
    echo This means g++ is broken or misconfigured
    exit /b 1
)

echo [TEST 6] Test with C++20 standard
"%GCC%" -std=c++20 -o "%BUILD_DIR%\test20.exe" "%BUILD_DIR%\test.cpp" 2>&1
if %errorlevel% equ 0 (
    echo ✅ C++20 compilation successful!
) else (
    echo ❌ C++20 compilation failed
    exit /b 1
)
echo.

echo [TEST 7] Check for headers
echo ─────────────────────────────────────────────────────────────────────────
if exist include\dqve_calculator.h (
    echo ✅ include/dqve_calculator.h found
) else (
    echo ❌ include/dqve_calculator.h NOT found
    exit /b 1
)

if exist include\state_db.h (
    echo ✅ include/state_db.h found
) else (
    echo ❌ include/state_db.h NOT found
    exit /b 1
)

if exist include\state_db_impl.h (
    echo ✅ include/state_db_impl.h found
) else (
    echo ❌ include/state_db_impl.h NOT found
    exit /b 1
)
echo.

echo [TEST 8] Check for source files
echo ─────────────────────────────────────────────────────────────────────────
if exist src\main.cpp (
    echo ✅ src/main.cpp found
) else (
    echo ❌ src/main.cpp NOT found
    exit /b 1
)

if exist src\state_db_impl.cpp (
    echo ✅ src/state_db_impl.cpp found
) else (
    echo ❌ src/state_db_impl.cpp NOT found
    exit /b 1
)

if exist src\dqve_calculator.cpp (
    echo ✅ src/dqve_calculator.cpp found
) else (
    echo ❌ src/dqve_calculator.cpp NOT found
    exit /b 1
)

if exist src\evm_integration.cpp (
    echo ✅ src/evm_integration.cpp found
) else (
    echo ❌ src/evm_integration.cpp NOT found
    exit /b 1
)
echo.

echo [TEST 9] Try compiling main.cpp alone
echo ─────────────────────────────────────────────────────────────────────────
"%GCC%" -std=c++20 -Wall -I"include" -I"src" -D_WIN32_WINNT=0x0A00 ^
  -c "src\main.cpp" -o "%BUILD_DIR%\main.o" 2>&1 > "%BUILD_DIR%\compile_main.log"

if %errorlevel% equ 0 (
    echo ✅ main.cpp compiled successfully!
    echo ✅ Output: %BUILD_DIR%\main.o
) else (
    echo ❌ main.cpp compilation FAILED
    echo.
    echo --- Compiler output: ---
    type "%BUILD_DIR%\compile_main.log"
    echo --- End output ---
    exit /b 1
)
echo.

echo ═══════════════════════════════════════════════════════════════════════════
echo                      ALL DIAGNOSTICS PASSED ✅
echo ═══════════════════════════════════════════════════════════════════════════
echo.
echo Your compiler is working! Try the full build:
echo   .\DIRECT_BUILD.bat
echo.
echo Or use Docker (most reliable):
echo   .\DOCKER_BUILD.bat
echo.
