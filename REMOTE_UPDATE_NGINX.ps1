# SpiralCoin - Remote Nginx Update to Proxy Backend
param(
  [string]$User = "root",
  [string]$RemoteHost = "174.138.37.6",
  [int]$Port = 22,
  [string]$SitePath = "/etc/nginx/sites-available/spiralcoin"
)

$ErrorActionPreference = 'Stop'

function Invoke-Remote($cmd){ ssh -p $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$User@$RemoteHost" $cmd }
function CopyFromRemote($remote,$local){
  $src = $User + "@" + $RemoteHost + ":" + $remote
  scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$src" "$local"
}
function CopyToRemote($local,$remote){
  $dst = $User + "@" + $RemoteHost + ":" + $remote
  scp -P $Port -o BatchMode=yes -o StrictHostKeyChecking=no "$local" "$dst"
}

$tmp = Join-Path $env:TEMP "spiralcoin.nginx.tmp"
$out = Join-Path $env:TEMP "spiralcoin.nginx.tmp2"

Write-Host "[STEP] Fetching nginx site config from $RemoteHost" -ForegroundColor Cyan
CopyFromRemote $SitePath $tmp

Write-Host "[STEP] Updating proxy to backend on 127.0.0.1:5000 and removing rewrite" -ForegroundColor Cyan
$content = Get-Content -Path $tmp -Raw
$content = $content -replace 'proxy_pass\s+http://127\.0\.0\.1:8081;', 'proxy_pass http://127.0.0.1:5000;'
# Remove path rewrite that broke /api/* routes
$content = ($content -split "`r?`n") | Where-Object { $_ -notmatch '^\s*rewrite\s+\^/api/\(.*\)\$\s+/\$1\s+break;' } | ForEach-Object { $_ }
Set-Content -Path $out -Value ($content -join [Environment]::NewLine)

Write-Host "[STEP] Uploading updated config and reloading nginx" -ForegroundColor Cyan
CopyToRemote $out $SitePath
Invoke-Remote "sudo nginx -t && sudo systemctl reload nginx && echo 'OK' || echo 'FAIL'"

Write-Host "[DONE] Nginx updated." -ForegroundColor Green
