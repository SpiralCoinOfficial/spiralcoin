# SpiralCoin - Remote Code Sync and Compose Up
param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22,
  [string]$RemoteRoot = "/root/spiralcoin",
  [switch]$Full
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

function Invoke-Remote($cmd){ ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" $cmd }
function Copy-Remote($src,$dst){ scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no $src $dst }
function Copy-RemoteFile([string]$src,[string]$dst){ & scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$src" "$dst" }
function Copy-RemoteDir([string]$src,[string]$dst){ & scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no -r "$src" "$dst" }

# Backup existing
$stamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
Invoke-Remote "test -d $RemoteRoot && cp -a $RemoteRoot ${RemoteRoot}.bak-$stamp || true"
Invoke-Remote "mkdir -p $RemoteRoot"

# Ensure directory tree
Invoke-Remote "mkdir -p $RemoteRoot/public $RemoteRoot/marketfeed $RemoteRoot/routes"
Invoke-Remote "rm -rf $RemoteRoot/include $RemoteRoot/src || true"
Invoke-Remote "mkdir -p $RemoteRoot/include $RemoteRoot/src"

# Copy core files
${remoteSpec} = ("{0}@{1}:{2}/" -f $User,$RemoteHost,$RemoteRoot)
# Copy core files
$fileList = @(
  (Join-Path $root 'compose.yaml'),
  (Join-Path $root 'docker-compose.prod.full.yaml'),
  (Join-Path $root 'nginx.conf'),
  (Join-Path $root 'package.json'),
  (Join-Path $root 'server.js')
)
$dockerfiles = Get-ChildItem -Path (Join-Path $root 'Dockerfile*') -File -ErrorAction SilentlyContinue
if ($dockerfiles) { $fileList += $dockerfiles.FullName }
foreach ($f in $fileList) { Copy-RemoteFile $f $remoteSpec }

# Copy directories recursively
foreach ($d in @('public','marketfeed','routes','include','src')) {
  $p = Join-Path $root $d
  if (Test-Path $p) { Copy-RemoteDir $p $remoteSpec }
}

# Compose up
$composeFile = if ($Full) { 'docker-compose.prod.full.yaml' } else { 'compose.yaml' }
Invoke-Remote "cd $RemoteRoot; docker compose -f $composeFile up -d --build"

# Show status
Invoke-Remote "cd $RemoteRoot; docker compose -f $composeFile ps"
