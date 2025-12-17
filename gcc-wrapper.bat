@echo off
REM Compiler wrapper for CMake to properly handle MinGW g++ on Windows
REM This script wraps g++ calls to work correctly with CMake

setlocal enabledelayedexpansion

REM Get the real g++ path
set "GXX_PATH=C:\msys64\mingw64\bin\g++.exe"

REM Pass all arguments through to g++
"%GXX_PATH%" %*

REM Exit with same code as g++
exit /b %errorlevel%
