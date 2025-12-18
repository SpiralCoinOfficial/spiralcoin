@echo off
REM Compiler wrapper for CMake to properly handle MinGW gcc on Windows

setlocal enabledelayedexpansion

REM Get the real gcc path
set "GCC_PATH=C:\msys64\mingw64\bin\gcc.exe"

REM Pass all arguments through to gcc
"%GCC_PATH%" %*

REM Exit with same code as gcc
exit /b %errorlevel%
