$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetsFile = Join-Path $root "EXCHANGE_PUBLISH.targets.json"

Write-Host "Prepublish checks starting..." -ForegroundColor Cyan

if (-not (Test-Path $targetsFile)) {
    Write-Host "Targets file missing: $targetsFile" -ForegroundColor Red
    exit 1
}

$cfg = Get-Content -Raw -Path $targetsFile | ConvertFrom-Json
$zipPath = if (-not [System.IO.Path]::IsPathRooted($cfg.zipPath)) { Join-Path $root $cfg.zipPath } else { $cfg.zipPath }

if (Test-Path $zipPath) {
    $info = Get-Item $zipPath
    Write-Host ("Zip found: {0} ({1} bytes)" -f $info.FullName, $info.Length) -ForegroundColor Green
} else {
    Write-Host "Zip missing: $zipPath. Run MAKE_EXCHANGE_PACK.ps1 first." -ForegroundColor Red
    exit 1
}

$scp = Get-Command scp -ErrorAction SilentlyContinue
$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if ($scp) { Write-Host "scp available: $($scp.Source)" -ForegroundColor Green } else { Write-Host "scp not found. Install OpenSSH Client." -ForegroundColor Yellow }
if ($ssh) { Write-Host "ssh available: $($ssh.Source)" -ForegroundColor Green } else { Write-Host "ssh not found. Install OpenSSH Client." -ForegroundColor Yellow }

if (-not $scp -or -not $ssh) { exit 1 }

# Test connectivity to first target
if ($cfg.targets.Count -gt 0) {
    $t = $cfg.targets[0]
    $remote = $t.remote
    try {
        Write-Host "Testing SSH to $remote..." -ForegroundColor Cyan
        $out = ssh $remote "echo ok" 2>$null
        if ($LASTEXITCODE -eq 0 -and $out -match "ok") {
            Write-Host "SSH connectivity OK to $remote" -ForegroundColor Green
        } else {
            Write-Host "SSH connectivity failed to $remote. Ensure keys/credentials are configured." -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "SSH test error: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Prepublish checks passed." -ForegroundColor Green
exit 0
