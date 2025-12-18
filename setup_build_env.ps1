param(
  [switch]$InstallCMake,
  [switch]$InstallMSYS2,
  [switch]$InstallMinGWDeps
)

$ErrorActionPreference = 'Stop'

function Ensure-CMake {
  try {
    $cmake = Get-Command cmake -ErrorAction Stop
    Write-Host "[OK] CMake found: $($cmake.Source)" -ForegroundColor Green
  } catch {
    Write-Host "[INFO] CMake not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id Kitware.CMake --source winget --silent
  }
}

function Ensure-MSYS2 {
  if (Test-Path "C:/msys64/usr/bin/bash.exe") {
    Write-Host "[OK] MSYS2 found at C:/msys64" -ForegroundColor Green
  } else {
    Write-Host "[INFO] MSYS2 not found. Installing via winget..." -ForegroundColor Yellow
    winget install --id MSYS2.MSYS2 --source winget --silent
  }
}

function Install-MinGW-Packages {
  $bash = "C:/msys64/usr/bin/bash.exe"
  if (-not (Test-Path $bash)) { throw "MSYS2 bash not found at $bash" }
  $cmd = @"
pacman -Sy --noconfirm --needed \
  mingw-w64-x86_64-gcc \
  mingw-w64-x86_64-nlohmann-json \
  mingw-w64-x86_64-openssl
"@
  Write-Host "[INFO] Installing MinGW packages (gcc, nlohmann_json, openssl)..." -ForegroundColor Yellow
  & $bash -lc $cmd
}

if ($InstallCMake) { Ensure-CMake }
if ($InstallMSYS2) { Ensure-MSYS2 }
if ($InstallMinGWDeps) { Install-MinGW-Packages }

Write-Host "[DONE] Build environment setup steps completed." -ForegroundColor Cyan