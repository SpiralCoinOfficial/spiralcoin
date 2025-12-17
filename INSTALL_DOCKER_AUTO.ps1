# SpiralCoin - Automatic Docker Installation & Build
# Run as Administrator for full functionality

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SpiralCoin - Automatic Docker Installation & Build      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "[ERROR] This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "[INFO] Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "[STEP 1/4] Checking Docker installation..." -ForegroundColor Cyan
$dockerExists = $false
try {
    $output = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Docker is already installed: $output" -ForegroundColor Green
        $dockerExists = $true
    }
}
catch {
    Write-Host "[INFO] Docker not found, will attempt installation" -ForegroundColor Yellow
}

if (-not $dockerExists) {
    Write-Host ""
    Write-Host "[STEP 2/4] Downloading Docker Desktop installer..." -ForegroundColor Cyan

    $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $installerPath = "$env:TEMP\DockerDesktopInstaller.exe"

    try {
        # Download with progress
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing

        if (Test-Path $installerPath) {
            $fileSize = (Get-Item $installerPath).Length / 1MB
            Write-Host "[OK] Downloaded: $($fileSize.ToString('F2')) MB" -ForegroundColor Green
        }
        else {
            throw "Download failed"
        }
    }
    catch {
        Write-Host "[ERROR] Failed to download Docker Desktop" -ForegroundColor Red
        Write-Host "[INFO] Manual download: $downloadUrl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "After manual download and installation, run:" -ForegroundColor Yellow
        Write-Host "  .\AUTO_EXECUTE.bat" -ForegroundColor Cyan
        Write-Host ""
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    Write-Host ""
    Write-Host "[STEP 3/4] Installing Docker Desktop..." -ForegroundColor Cyan
    Write-Host "[INFO] This may take 5-10 minutes..." -ForegroundColor Yellow
    Write-Host "[INFO] DO NOT close this window during installation" -ForegroundColor Yellow
    Write-Host ""

    try {
        # Run installer with silent flags
        $process = Start-Process -FilePath $installerPath -ArgumentList "install --quiet" -PassThru -Wait -NoNewWindow

        # Wait for Docker service to start
        Write-Host "[INFO] Waiting for Docker service to start..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30

        # Verify installation
        $dockerExists = $false
        for ($i = 1; $i -le 10; $i++) {
            try {
                $output = docker --version 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "[OK] Docker installed successfully: $output" -ForegroundColor Green
                    $dockerExists = $true
                    break
                }
            }
            catch {
                Write-Host "[INFO] Waiting for Docker daemon... ($i/10)" -ForegroundColor Yellow
                Start-Sleep -Seconds 5
            }
        }

        if (-not $dockerExists) {
            Write-Host "[WARNING] Docker may not be fully ready yet" -ForegroundColor Yellow
            Write-Host "[INFO] Please wait a few minutes and run AutoExecute" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "[ERROR] Installation failed: $_" -ForegroundColor Red
        Write-Host "[INFO] Please install Docker Desktop manually from:" -ForegroundColor Yellow
        Write-Host "https://www.docker.com/products/docker-desktop" -ForegroundColor Cyan
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }

    # Cleanup installer
    Remove-Item -Path $installerPath -Force -ErrorAction SilentlyContinue
}

# Now build SpiralCoin with Docker
Write-Host ""
Write-Host "[STEP 4/4] Building SpiralCoin with Docker..." -ForegroundColor Cyan
Write-Host ""

try {
    # Change to project directory
    cd "c:\Users\Trisha Dreyer\Documents\GitHub\spiralcoin.worktrees\copilot\implement-feature"

    # Build Docker image
    Write-Host "[BUILD] Building Docker image..." -ForegroundColor Cyan
    docker build -f Dockerfile.dev -t spiralcoin:latest .

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Docker image built successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "[RUN] Starting SpiralCoin daemon..." -ForegroundColor Cyan
        Write-Host "[INFO] SpiralCoin will be available at: http://localhost:8545" -ForegroundColor Yellow
        Write-Host "[INFO] To test the RPC endpoint, run in another terminal:" -ForegroundColor Cyan
        Write-Host "  curl -X POST http://localhost:8545/rpc -H Content-Type: application/json -d {jsonrpc:2.0,id:1,method:getblockcount,params:[]}" -ForegroundColor Cyan
        Write-Host ""

        # Run container
        docker run -p 8545:8545 -v ./data:/app/data spiralcoin:latest
    }
    else {
        Write-Host "[ERROR] Docker build failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "[ERROR] Build failed" -ForegroundColor Red
    exit 1
}
