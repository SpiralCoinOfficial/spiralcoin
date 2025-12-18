param(
    [string]$TargetsFile = "EXCHANGE_PUBLISH.targets.json",
    [string]$ZipPathOverride = ""
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

$zipPath = if ($ZipPathOverride) { $ZipPathOverride } else {
    if (-not [System.IO.Path]::IsPathRooted($cfg.zipPath)) { Join-Path $root $cfg.zipPath } else { $cfg.zipPath }
}

if (-not (Test-Path $zipPath)) {
    throw "Local zip not found at: $zipPath. Run MAKE_EXCHANGE_PACK.ps1 first."
}

$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $ssh) {
    throw "ssh not found. Install Windows OpenSSH Client: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
}

$localHash = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()
Write-Host "Local SHA256: $localHash" -ForegroundColor Yellow

$results = @()
foreach ($t in $cfg.targets) {
    $remote = $t.remote
    $remoteDir = $t.remoteDir
    $name = $t.name
    $zipName = if ($t.zipName) { $t.zipName } else { [System.IO.Path]::GetFileName($zipPath) }

    try {
        $ls = ssh -o BatchMode=yes -o StrictHostKeyChecking=no $remote "ls -l '$remoteDir/$zipName'" 2>$null
        $existsOk = ($LASTEXITCODE -eq 0 -and $ls)
        $remoteHash = $null
        $hashOk = $false
        if ($existsOk) {
            try {
                $sumOut = ssh -o BatchMode=yes -o StrictHostKeyChecking=no $remote "sha256sum '$remoteDir/$zipName'" 2>$null
                if ($sumOut) {
                    $remoteHash = ($sumOut -split "\s+")[0].ToLower()
                    $hashOk = ($remoteHash -eq $localHash)
                }
            }
            catch {
                Write-Host "[${name}] sha256sum not available on remote; skipping checksum verify." -ForegroundColor Yellow
            }
        }
        if ($existsOk -and ($hashOk -or $remoteHash -eq $null)) {
            $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "success"; file = $zipName; localSha256 = $localHash; remoteSha256 = $remoteHash }
            Write-Host "[${name}] Verified (existence$(if ($hashOk) { ' + checksum' } else { ''}))." -ForegroundColor Green
        }
        else {
            $msg = if (-not $existsOk) { "Remote file missing" } else { "Checksum mismatch: local=$localHash remote=$remoteHash" }
            $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "error"; message = $msg; file = $zipName; localSha256 = $localHash; remoteSha256 = $remoteHash }
            Write-Host "[${name}] Verification failed: $msg" -ForegroundColor Red
        }
    }
    catch {
        $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "error"; message = $_.Exception.Message; file = $zipName }
        Write-Host "[${name}] Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "\nVerify Summary:" -ForegroundColor Yellow
foreach ($r in $results) {
    $hashInfo = if ($r.remoteSha256) { " sha256(local=${r.localSha256}, remote=${r.remoteSha256})" } else { " sha256(local=${r.localSha256}, remote=NA)" }
    Write-Host (" - {0}: {1} ({2}:{3}/{4}){5}" -f $r.name, $r.status, $r.remote, $r.remoteDir, ($r.file), $hashInfo)
}

if ($results | Where-Object { $_.status -ne 'success' }) { exit 1 } else { exit 0 }
