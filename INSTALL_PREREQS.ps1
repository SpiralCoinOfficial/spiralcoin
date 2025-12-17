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
  } catch { Write-Host "[WARN] winget install failed for $Id: $($_.Exception.Message)" -ForegroundColor Yellow }
}

Write-Host ""; Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SpiralCoin - Install Prerequisites" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════" -ForegroundColor Cyan; Write-Host ""

# Docker Desktop
if (-not (Test-Command 'docker')) {
  Install-WithWinget -Id 'Docker.DockerDesktop'
} else {
  Write-Host "[INFO] Docker already installed" -ForegroundColor Yellow
}

# MSYS2 and MinGW
if (-not (Test-Command 'g++')) {
  Install-WithWinget -Id 'MSYS2.MSYS2'
  Write-Host "[INFO] After installing MSYS2, open MSYS2 and run: pacman -S --noconfirm mingw-w64-x86_64-gcc" -ForegroundColor Yellow
  Write-Host "[INFO] Then add C:\msys64\mingw64\bin to your PATH" -ForegroundColor Yellow
} else {
  Write-Host "[INFO] MinGW g++ already available" -ForegroundColor Yellow
}

Write-Host "[DONE] Install prerequisites step complete" -ForegroundColor Cyan
exit 0
