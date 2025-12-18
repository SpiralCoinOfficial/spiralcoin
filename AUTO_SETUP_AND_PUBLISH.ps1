param(
    [string]$TargetsFile = "EXCHANGE_PUBLISH.targets.json",
    [string]$SSHUser = "",
    [string]$SSHHost = "",
    [int]$Port = 22,
    [securestring]$Password,
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Logging
$buildDir = Join-Path $root "build"
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }
$logPath = Join-Path $buildDir "auto_setup_log.txt"
"[Start] $(Get-Date -Format o) Auto setup+publish" | Out-File -FilePath $logPath -Encoding UTF8
function Log($m) { $m | Out-File -FilePath $logPath -Append -Encoding UTF8 }

Log "Root: $root"

# Resolve targets
if (-not [System.IO.Path]::IsPathRooted($TargetsFile)) { $TargetsFile = Join-Path $root $TargetsFile }
if (-not (Test-Path $TargetsFile)) { throw "Targets file not found: $TargetsFile" }
$cfg = Get-Content -Raw -Path $TargetsFile | ConvertFrom-Json
Log "Targets file: $TargetsFile"

# Derive user@host from first target if not provided
if (-not $SSHUser -or -not $SSHHost) {
    $spec = $cfg.targets[0].remote # e.g., user@host
    if ($spec -match "^(?<u>[^@]+)@(?<h>.+)$") {
        if (-not $SSHUser) { $SSHUser = $Matches['u'] }
        if (-not $SSHHost) { $SSHHost = $Matches['h'] }
    } else {
        throw "Invalid remote spec in targets: $spec"
    }
}
$remoteSpec = "$SSHUser@$SSHHost"
Log "Remote: ${remoteSpec}:$Port"

# Ensure OpenSSH client
$ssh = Get-Command ssh -ErrorAction SilentlyContinue
$scp = Get-Command scp -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) {
    Log "OpenSSH not found; attempting install"
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 | Out-Null
    } catch { Log "OpenSSH install attempt failed: $($_.Exception.Message)" }
    $ssh = Get-Command ssh -ErrorAction SilentlyContinue
    $scp = Get-Command scp -ErrorAction SilentlyContinue
    if (-not $ssh -or -not $scp) { throw "ssh/scp not available" }
}

# Ensure a public key exists; prefer ed25519; generate if missing
$ed = Join-Path $HOME ".ssh/id_ed25519.pub"
$rsa = Join-Path $HOME ".ssh/id_rsa.pub"
$pub = $null
if (Test-Path $ed) { $pub = $ed } elseif (Test-Path $rsa) { $pub = $rsa } else {
    Log "No public key found; generating ed25519"
    $keyDir = Join-Path $HOME ".ssh"
    if (-not (Test-Path $keyDir)) { New-Item -ItemType Directory -Path $keyDir | Out-Null }
    & ssh-keygen -t ed25519 -N "" -C "$env:USERNAME@$env:COMPUTERNAME" -f (Join-Path $keyDir "id_ed25519") | Out-Null
    $pub = Join-Path $keyDir "id_ed25519.pub"
}
if (-not (Test-Path $pub)) { throw "Public key not found: $pub" }
Log "Public key: $pub"

# Test passwordless
$__prevErrPref = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$test = & $ssh.Source -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no $remoteSpec "echo ok" 2>&1
$ErrorActionPreference = $__prevErrPref
if ($LASTEXITCODE -eq 0 -and $test -match "ok") {
    Log "Passwordless SSH OK"
} else {
    Log "Passwordless SSH not working; will try Posh-SSH with password"
    # Try to use Posh-SSH
    if (-not $Password) {
        $envPwd = [Environment]::GetEnvironmentVariable("SPIRALCOIN_SSH_PASSWORD", "Process")
        if (-not $envPwd) { $envPwd = [Environment]::GetEnvironmentVariable("SPIRALCOIN_SSH_PASSWORD", "User") }
        if ($envPwd) {
            $Password = ConvertTo-SecureString $envPwd -AsPlainText -Force
        } elseif (-not $NonInteractive) {
            $Password = Read-Host "Enter SSH password for $remoteSpec" -AsSecureString
        } else {
            throw "Passwordless SSH not configured and no password available (set SPIRALCOIN_SSH_PASSWORD or provide -Password)."
        }
    }
    $module = Get-Module -ListAvailable -Name Posh-SSH
    if (-not $module) {
        Log "Installing Posh-SSH"
        try {
            $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
            if ($repo -and $repo.InstallationPolicy -ne 'Trusted') { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted }
            Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber | Out-Null
        } catch { throw "Failed to install Posh-SSH: $($_.Exception.Message)" }
    }
    Import-Module Posh-SSH -ErrorAction Stop

    $cred = New-Object System.Management.Automation.PSCredential ($SSHUser, $Password)
    Log "Creating SSH session via Posh-SSH"
    $session = $null
    try {
        $session = New-SSHSession -ComputerName $SSHHost -Port $Port -Credential $cred -AcceptKey -KeepAliveInterval 15 -OperationTimeout 120
        if (-not $session) { throw "New-SSHSession returned null" }
        $pubContent = Get-Content -Path $pub -Raw
        $pubB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pubContent))
        $cmd = "umask 077; mkdir -p ~/.ssh; echo '$pubB64' | base64 -d >> ~/.ssh/authorized_keys; chmod 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys"
        Log "Appending key via base64 pipeline"
        $r = Invoke-SSHCommand -SSHSession $session -Command $cmd -TimeOut 120
        if ($r.ExitStatus -ne 0) { throw "Remote command failed: $($r.Error) $($r.Output)" }
    }
    finally {
        if ($session) { Remove-SSHSession -SSHSession $session | Out-Null }
    }

    # Re-test passwordless
    $__prevErrPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $test2 = & $ssh.Source -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no $remoteSpec "echo ok" 2>&1
    $ErrorActionPreference = $__prevErrPref
    if (-not ($LASTEXITCODE -eq 0 -and $test2 -match "ok")) {
        throw "Passwordless SSH still not available after key upload. Check server sshd_config (PermitRootLogin yes, PubkeyAuthentication yes) and ~/.ssh permissions."
    }
    Log "Passwordless SSH OK after key install"
}

# Run publish
Log "Running publish script"
& (Join-Path $root "PUBLISH_EXCHANGE_PACK_MULTI.ps1")
$pubExit = $LASTEXITCODE
Log "Publish exit code: $pubExit"
if ($pubExit -ne 0) { Write-Host "[WARN] Publish returned non-zero ($pubExit). See build/publish_log.txt" -ForegroundColor Yellow }

# Verify and list
Log "Running verify remotely"
& (Join-Path $root "VERIFY_REMOTE_PACK.ps1")
$verExit = $LASTEXITCODE
Log "Verify exit code: $verExit"

Write-Host "Auto setup & publish complete. (publish=$pubExit, verify=$verExit)" -ForegroundColor Green
Log "[End] $(Get-Date -Format o)"
exit $pubExit
