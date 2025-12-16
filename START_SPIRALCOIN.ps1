# =====================================================
# SpiralCoin Complete Startup Script (PowerShell)
# Starts both C++ daemon and Node.js backend
# =====================================================

Write-Host @"

╔════════════════════════════════════════════════════╗
║    SpiralCoin Daemon & Backend Startup (v1.0)    ║
╚════════════════════════════════════════════════════╝

"@

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Function to test API connectivity
function Test-API {
    param([string]$Url, [string]$Name)
    try {
        $response = Invoke-WebRequest $Url -TimeoutSec 2 -ErrorAction Stop
        Write-Host "✅ $Name responding (HTTP $($response.StatusCode))"
        return $true
    }
    catch {
        Write-Host "❌ $Name not responding"
        return $false
    }
}

# Start Node.js Backend
Write-Host "[1/2] Starting Node.js Backend on port 5000..."
Start-Process -FilePath 'node' -ArgumentList 'server.js' -WindowStyle Minimized
Start-Sleep -Seconds 3

# Test backend
if (Test-API "http://127.0.0.1:5000/health" "Backend Health") {
    $stats = Invoke-WebRequest http://127.0.0.1:5000/api/stats | ConvertFrom-Json
    Write-Host "       Uptime: $([math]::Round($stats.uptime,1)) seconds"
    Write-Host "       Node: $($stats.node)"
}

Write-Host ""
Write-Host "[2/2] C++ RPC Daemon Setup"
Write-Host "       Available: .\build\spiralcoind.exe"
Write-Host "       To start: .\build\spiralcoind.exe"
Write-Host "       Listens on port 8545 (JSON-RPC)"

Write-Host @"

╔════════════════════════════════════════════════════╗
║           Startup Complete - Ready!               ║
╚════════════════════════════════════════════════════╝

Available API Endpoints:
  • http://127.0.0.1:5000/health          Health check
  • http://127.0.0.1:5000/api/stats       Statistics
  • http://127.0.0.1:5000/api/blockchain  Blockchain ops
  • http://127.0.0.1:5000/api/wallet      Wallet mgmt
  • http://127.0.0.1:5000/api/market      Market data
  • http://127.0.0.1:5000/api/mining      Mining ops

Services Running:
  ✅ Node.js Backend (Port 5000)
  ⏹️  C++ Daemon (Port 8545) - Available on demand

Type 'Get-Process node' to view backend process
Type 'Stop-Process -Name node' to stop backend

"@

Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
