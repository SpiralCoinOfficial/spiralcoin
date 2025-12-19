# Run local install, start backend, run smoke/QA tests, and stop backend
Param()

$ErrorActionPreference = 'Stop'

# Resolve repo root (this script is in scripts/)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
Push-Location $RepoRoot

Write-Host "=== SpiralCoin Local QA Runner ===" -ForegroundColor Cyan

# 1) Show versions
try {
  $nodeVer = node -v
  $npmVer = npm -v
  Write-Host "Node: $nodeVer   npm: $npmVer"
} catch {
  Write-Error "Node.js and npm are required. Install Node >= 18.17 and npm >= 9."
  exit 1
}

# 2) Install dependencies (deterministic)
Write-Host "\n== npm ci ==" -ForegroundColor Yellow
npm ci

# 3) Start backend in a job
$jobName = 'SpiralServer'
try {
  if (Get-Job -Name $jobName -ErrorAction SilentlyContinue) {
    Stop-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null
    Remove-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null
  }
} catch {}

Write-Host "\n== Starting backend ==" -ForegroundColor Yellow
$env:PORT = '5000'
$startBlock = {
  Param($Path)
  Push-Location $Path
  # Use the PORT from environment, server has fallback logic
  node server.js
}
$job = Start-Job -Name $jobName -ScriptBlock $startBlock -ArgumentList $RepoRoot
Start-Sleep -Seconds 2

# 4) Wait for health on any of the common ports
function Test-Health {
  Param([int]$Port)
  try {
    $resp = Invoke-RestMethod -UseBasicParsing "http://127.0.0.1:$Port/health" -TimeoutSec 2
    if ($resp -and $resp.status -eq 'healthy') { return $true }
  } catch {}
  return $false
}

$ports = 5000..5005
$healthyPort = $null
$deadline = (Get-Date).AddSeconds(30)
while (-not $healthyPort -and (Get-Date) -lt $deadline) {
  foreach ($p in $ports) {
    if (Test-Health -Port $p) { $healthyPort = $p; break }
  }
  if (-not $healthyPort) { Start-Sleep -Milliseconds 500 }
}

if (-not $healthyPort) {
  Write-Error "Backend did not become healthy within timeout."
  Stop-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null
  Remove-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null
  exit 2
}

Write-Host "Healthy on port $healthyPort" -ForegroundColor Green

# 5) Run smoke and QA tests
$fail = $false

function Run-NodeScript {
  Param([string]$ScriptPath)
  Write-Host "\n== node $ScriptPath ==" -ForegroundColor Yellow
  try {
    node $ScriptPath
    if ($LASTEXITCODE -ne 0) { $global:fail = $true }
  } catch {
    Write-Error $_
    $global:fail = $true
  }
}

Run-NodeScript "scripts/smoke_test.js"
Run-NodeScript "scripts/qa_routes_test.js"
Run-NodeScript "scripts/qa_auth_test.js"
Run-NodeScript "scripts/qa_auth_refresh_test.js"

# 6) Stop backend
Write-Host "\n== Stopping backend ==" -ForegroundColor Yellow
try { Stop-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null } catch {}
try { Remove-Job -Name $jobName -ErrorAction SilentlyContinue | Out-Null } catch {}

if ($fail) {
  Write-Error "One or more QA tests failed. See output above."
  exit 3
}

Write-Host "\n=== All local QA checks passed ===" -ForegroundColor Green
exit 0
