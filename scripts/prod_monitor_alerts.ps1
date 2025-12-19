param(
  [string]$Domain = "www.spiralcoin.net",
  [string]$HealthchecksUrl = $env:HEALTHCHECKS_URL
)

$ErrorActionPreference = 'Continue'
Write-Host "=== SpiralCoin: Monitoring Ping ===" -ForegroundColor Cyan
Write-Host "Domain: $Domain"

function Test-Url([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
    return @{ ok=$true; status=$r.StatusCode; body=$r.Content }
  } catch {
    return @{ ok=$false; error=$_.Exception.Message }
  }
}

$healthUrl = "https://$Domain/health"
$resp = Test-Url $healthUrl
if ($resp.ok) {
  Write-Host "Health OK: $($resp.status)" -ForegroundColor Green
  if ($HealthchecksUrl) {
    try { Invoke-WebRequest -Uri $HealthchecksUrl -UseBasicParsing -TimeoutSec 5 | Out-Null } catch {}
  }
} else {
  Write-Host "Health FAILED: $($resp.error)" -ForegroundColor Red
}
