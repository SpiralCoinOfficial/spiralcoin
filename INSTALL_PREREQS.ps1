# SpiralCoin - Install Prerequisites (Windows)
# Attempts to install Docker Desktop and MSYS2/MinGW via winget.

$ErrorActionPreference = 'Continue'

function Test-Command {
  param([string]$Name)
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  return $null -ne $cmd
}

function Install-WithWinget {
  param([string]$Id)
  if (-not (Test-Command 'winget')) { Write-Host "[ERROR] winget not found. Please update to the latest Windows." -ForegroundColor Red; return }
  try {
    Write-Host "[STEP] Installing $Id via winget" -ForegroundColor Cyan
    winget install --id $Id --silent --accept-source-agreements --accept-package-agreements
  } catch { Write-Host "[WARN] winget install failed for ${Id}: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Install Prerequisites" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan; Write-Host ""

# CMake
if (-not (Test-Command 'cmake')) {
  Install-WithWinget -Id 'Kitware.CMake'
} else {
  Write-Host "[INFO] CMake already installed" -ForegroundColor Yellow
}

# Docker Desktop
if (-not (Test-Command 'docker')) {
  Install-WithWinget -Id 'Docker.DockerDesktop'
} else {
  Write-Host "[INFO] Docker already installed" -ForegroundColor Yellow
}

# MSYS2 and MinGW toolchain
if (-not (Test-Command 'g++')) {
  Install-WithWinget -Id 'MSYS2.MSYS2'
  $msysBash = 'C:\msys64\usr\bin\bash.exe'
  if (Test-Path $msysBash) {
    Write-Host "[STEP] Installing MSYS2 mingw64 toolchain (gcc, make)" -ForegroundColor Cyan
    & $msysBash -lc "pacman -Syu --noconfirm" | Out-Host
    & $msysBash -lc "pacman -S --noconfirm mingw-w64-x86_64-gcc mingw-w64-x86_64-make" | Out-Host
    Write-Host "[INFO] Ensure C:\msys64\mingw64\bin is on PATH for current session" -ForegroundColor Yellow
    $mingwBin = 'C:\msys64\mingw64\bin'
    if (Test-Path $mingwBin) {
      if (-not ($Env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ieq $mingwBin })) {
        $Env:Path = $Env:Path + ";$mingwBin"
        Write-Host "[INFO] Added $mingwBin to PATH for this session" -ForegroundColor Yellow
      }
    }
  } else {
    Write-Host "[WARN] MSYS2 not found at C:\\msys64 after winget install. Please restart shell or verify installation." -ForegroundColor Yellow
  }
} else {
  Write-Host "[INFO] MinGW g++ already available" -ForegroundColor Yellow
}

Write-Host "[DONE] Install prerequisites step complete" -ForegroundColor Cyan
exit 0
