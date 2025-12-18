param(
    [string]$BaseUrl = "http://localhost:5000"
)

$ErrorActionPreference = "Stop"

# Resolve workspace root relative to this script
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $root "build"

# Ensure build directory exists
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Build an exchange manifest for convenience
$manifest = @{
    name      = "SpiralCoin"
    symbol    = "SPRC"
    decimals  = 18
    website   = "https://spiralcoin.net"
    logoUrl   = "/public/assets/SpiralCoin_logo.png"
    baseUrl   = $BaseUrl
    contracts = @{
        ethereum = @{
            chain    = "ethereum"
            chainId  = "0x1" # mainnet (placeholder)
            address  = ""    # TODO: fill after deployment
        }
        bsc = @{
            chain    = "bsc"
            chainId  = "0x38" # BSC mainnet (placeholder)
            address  = ""     # TODO: fill after deployment
        }
    }
    endpoints = @{
        health       = "/health"
        status       = "/api/status"
        rpcProxy     = "/api/rpc"
        marketPrice  = "/api/market/price"
        wallet       = "/api/wallet"
        info         = "/api/info"
        exchangeInfo = "/api/exchange/info"
    }
}

$manifestPath = Join-Path $buildDir "exchange_manifest.json"
$manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

# Files to include in the pack (include only if present)
$files = @(
    "README_EXCHANGE_API_SPEC.md",
    "README_EXCHANGE_LISTING.md",
    "README_LOCAL_STACK.md",
    ".env.example",
    (Join-Path "public" "exchange.html"),
    (Join-Path "public" "status.html"),
    (Join-Path "public" "index.html"),
    (Join-Path "public" "script.js"),
    (Join-Path "public" "style.css"),
    (Join-Path "public" "assets/SpiralCoin_logo.png"),
    "trading_platform.html",
    $manifestPath
)

$existingFiles = New-Object System.Collections.Generic.List[string]
foreach ($f in $files) {
    $p = $f
    if (-not [System.IO.Path]::IsPathRooted($p)) {
        $p = Join-Path $root $p
    }
    if (Test-Path $p) {
        $existingFiles.Add($p) | Out-Null
    }
}

if ($existingFiles.Count -eq 0) {
    Write-Host "No files found to include in exchange pack." -ForegroundColor Yellow
    exit 1
}

# Create zip
$zipPath = Join-Path $buildDir "SpiralCoin-Exchange-Pack.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $existingFiles -DestinationPath $zipPath

Write-Host "Exchange pack created:" $zipPath -ForegroundColor Green
Write-Host "Included files:" -ForegroundColor Cyan
$existingFiles | ForEach-Object { Write-Host " - $_" }
