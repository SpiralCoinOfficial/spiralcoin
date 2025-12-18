param(
    [string]$TargetsFile = "EXCHANGE_PUBLISH.targets.json"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not [System.IO.Path]::IsPathRooted($TargetsFile)) {
    $TargetsFile = Join-Path $root $TargetsFile
}

if (-not (Test-Path $TargetsFile)) {
    throw "Targets file not found: $TargetsFile"
}

$cfg = Get-Content -Raw -Path $TargetsFile | ConvertFrom-Json

$ssh = Get-Command ssh -ErrorAction SilentlyContinue
$scp = Get-Command scp -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) {
    throw "ssh/scp not found. Install Windows OpenSSH Client: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
}

$downloadsDir = Join-Path $root "build/downloads"
if (-not (Test-Path $downloadsDir)) { New-Item -ItemType Directory -Path $downloadsDir | Out-Null }

foreach ($t in $cfg.targets) {
    $remote = $t.remote
    $remoteDir = $t.remoteDir
    $name = $t.name
    $zipName = if ($t.zipName) { $t.zipName } else { [System.IO.Path]::GetFileName($cfg.zipPath) }
    $remoteTarget = "${remote}:$remoteDir/$zipName"
    Write-Host ("Fetching from {0}: {1}" -f $name, $remoteTarget) -ForegroundColor Cyan
    try {
        scp -o BatchMode=yes -o StrictHostKeyChecking=no "$remoteTarget" (Join-Path $downloadsDir "$name-$zipName")
        Write-Host "Saved to: $(Join-Path $downloadsDir "$name-$zipName")" -ForegroundColor Green
    }
    catch {
        Write-Host "Fetch failed for ${name}: $($_.Exception.Message)" -ForegroundColor Red
    }
}
