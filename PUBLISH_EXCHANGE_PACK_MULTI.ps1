param(
    [string]$TargetsFile = "EXCHANGE_PUBLISH.targets.json",
    [string]$ZipPathOverride = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Initialize logging ASAP
$logDir = Join-Path $root "build"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logPath = Join-Path $logDir "publish_log.txt"
"[Start] $(Get-Date -Format o) Publish run" | Out-File -FilePath $logPath -Encoding UTF8
function Write-Log($msg) { $msg | Out-File -FilePath $logPath -Append -Encoding UTF8 }

Write-Log "Script root: $root"
Write-Log "TargetsFile param: $TargetsFile"

if (-not [System.IO.Path]::IsPathRooted($TargetsFile)) {
    $TargetsFile = Join-Path $root $TargetsFile
}
Write-Log "TargetsFile resolved: $TargetsFile"

if (-not (Test-Path $TargetsFile)) {
    Write-Log "ERROR: Targets file not found: $TargetsFile"
    throw "Targets file not found: $TargetsFile"
}

$cfg = Get-Content -Raw -Path $TargetsFile | ConvertFrom-Json

$zipPath = if ($ZipPathOverride) { $ZipPathOverride } else {
    if (-not [System.IO.Path]::IsPathRooted($cfg.zipPath)) { Join-Path $root $cfg.zipPath } else { $cfg.zipPath }
}
Write-Log "zipPath resolved: $zipPath"

if (-not (Test-Path $zipPath)) {
    Write-Log "ERROR: Zip not found: $zipPath"
    throw "Zip not found at: $zipPath. Run MAKE_EXCHANGE_PACK.ps1 first."
}

$scp = Get-Command scp -ErrorAction SilentlyContinue
$ssh = Get-Command ssh -ErrorAction SilentlyContinue
if (-not $scp -or -not $ssh) {
    Write-Log "ERROR: ssh/scp not found in PATH"
    throw "ssh/scp not found. Install Windows OpenSSH Client: Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"
}

$localHash = (Get-FileHash -Algorithm SHA256 -Path $zipPath).Hash.ToLower()
Write-Host "Local SHA256: $localHash" -ForegroundColor Yellow
Write-Log "Local zip: $zipPath"
Write-Log "Local SHA256: $localHash"

$results = @()
foreach ($t in $cfg.targets) {
    $remote = $t.remote
    $remoteDir = $t.remoteDir
    $name = $t.name
    $zipName = $t.zipName

    Write-Host "[${name}] Creating remote dir: ${remote}:${remoteDir}" -ForegroundColor Cyan
    try {
        ssh -o BatchMode=yes -o StrictHostKeyChecking=no $remote "mkdir -p '$remoteDir'" | Out-Null
        $destName = if ($zipName) { $zipName } else { [System.IO.Path]::GetFileName($zipPath) }
        Write-Host "[${name}] Uploading: $zipPath as $destName" -ForegroundColor Cyan
        # Build remote target separately to avoid PowerShell parsing $var: with colon
        $remoteTarget = "${remote}:$remoteDir/$destName"
        # Use non-interactive options to avoid prompts during CI/tasks; quote local path for spaces
        $scpCmd = "scp -o BatchMode=yes -o StrictHostKeyChecking=no `"$zipPath`" `"$remoteTarget`""
        Write-Host "[${name}] scp command: $scpCmd" -ForegroundColor DarkGray
        Write-Log "[${name}] scp command: $scpCmd"
        $scpOut = & scp -o BatchMode=yes -o StrictHostKeyChecking=no "$zipPath" "$remoteTarget" 2>&1
        $scpCode = $LASTEXITCODE
        Write-Log "[${name}] scp exit: $scpCode"
        if ($scpOut) { Write-Log "[${name}] scp output: $scpOut" }
        if ($scpCode -ne 0) {
            Write-Host "[${name}] scp failed (exit $scpCode): $scpOut" -ForegroundColor Red
        }
        # Basic existence check
        $ls = ssh -o BatchMode=yes -o StrictHostKeyChecking=no $remote "ls -l '$remoteDir/$destName'" 2>$null
        if ($ls) { Write-Log "[${name}] ls output: $ls" }
        $existsOk = ($LASTEXITCODE -eq 0 -and $ls)
        $remoteHash = $null
        $hashOk = $false
        if ($existsOk) {
            # Compute remote SHA256; if sha256sum missing, skip with warning
            try {
                $sumOut = ssh -o BatchMode=yes -o StrictHostKeyChecking=no $remote "sha256sum '$remoteDir/$destName'" 2>$null
                if ($sumOut) { Write-Log "[${name}] sha256sum output: $sumOut" }
                if ($sumOut) {
                    $remoteHash = ($sumOut -split "\s+")[0].ToLower()
                    $hashOk = ($remoteHash -eq $localHash)
                }
            }
            catch {
                Write-Host "[${name}] sha256sum not available on remote; skipping checksum verify." -ForegroundColor Yellow
                Write-Log "[${name}] sha256sum not available"
            }
        }
        if ($existsOk -and ($hashOk -or $remoteHash -eq $null)) {
            $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "success"; file = $destName; localSha256 = $localHash; remoteSha256 = $remoteHash }
            if ($hashOk) {
                Write-Host "[${name}] Upload verified with checksum." -ForegroundColor Green
                Write-Log "[${name}] verified with checksum"
            }
            else {
                Write-Host "[${name}] Upload verified (existence only)." -ForegroundColor Green
                Write-Log "[${name}] verified existence only"
            }
        }
        else {
            $msg = if (-not $existsOk) { "Remote file not found after upload" } else { "Checksum mismatch: local=$localHash remote=$remoteHash" }
            $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "error"; message = $msg; file = $destName; localSha256 = $localHash; remoteSha256 = $remoteHash }
            Write-Host "[${name}] Verification failed: $msg" -ForegroundColor Red
            Write-Log "[${name}] verification failed: $msg"
        }
    }
    catch {
        $results += @{ name = $name; remote = $remote; remoteDir = $remoteDir; status = "error"; message = $_.Exception.Message; localSha256 = $localHash; remoteSha256 = $null }
        Write-Host "[${name}] Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "[${name}] error: $($_.Exception.Message)"
    }
}

Write-Host "\nPublish Summary:" -ForegroundColor Yellow
foreach ($r in $results) {
    $hashInfo = if ($r.remoteSha256) { " sha256(local=${r.localSha256}, remote=${r.remoteSha256})" } else { " sha256(local=${r.localSha256}, remote=NA)" }
    Write-Host (" - {0}: {1} ({2}:{3}/{4}){5}" -f $r.name, $r.status, $r.remote, $r.remoteDir, ($r.file), $hashInfo)
    Write-Log ("summary: {0}: {1} ({2}:{3}/{4}){5}" -f $r.name, $r.status, $r.remote, $r.remoteDir, ($r.file), $hashInfo)
}

# Exit with non-zero if any failed
if ($results | Where-Object { $_.status -ne 'success' }) { exit 1 } else { exit 0 }
