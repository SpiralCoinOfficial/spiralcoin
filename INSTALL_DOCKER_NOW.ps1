# SpiralCoin - Install Docker Desktop Automatically

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     SpiralCoin - Docker Desktop Installation              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is already installed
Write-Host "[CHECK] Detecting Docker installation..." -ForegroundColor Yellow
$dockerExists = $false
try {
    $dockerVersion = docker --version 2>$null
    if ($?) {
        Write-Host "[OK] Docker is already installed: $dockerVersion" -ForegroundColor Green
        $dockerExists = $true
    }
}
catch {
    Write-Host "[INFO] Docker not found" -ForegroundColor Yellow
}

if ($dockerExists) {
    Write-Host ""
    Write-Host "[INFO] Docker is ready! Starting SpiralCoin build..." -ForegroundColor Green
    Write-Host ""

    # Change to project directory
    cd "c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature"

    # Run Docker build
    Write-Host "[BUILD] Building SpiralCoin Docker image..." -ForegroundColor Cyan
    docker build -f Dockerfile.dev -t spiralcoin:latest .

    Write-Host ""
    Write-Host "[RUN] Starting SpiralCoin daemon..." -ForegroundColor Cyan
    docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest

    Write-Host ""
    Write-Host "✅ SpiralCoin is running on port 8545!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "[ACTION REQUIRED] Docker needs to be installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download Docker Desktop from:" -ForegroundColor Yellow
    Write-Host "https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Steps:" -ForegroundColor Yellow
    Write-Host "1. Download Docker Desktop for Windows" -ForegroundColor White
    Write-Host "2. Run the installer" -ForegroundColor White
    Write-Host "3. Restart your computer when prompted" -ForegroundColor White
    Write-Host "4. Run this script again" -ForegroundColor White
    Write-Host ""
    Write-Host "Once Docker is installed, SpiralCoin will build automatically." -ForegroundColor Green
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
