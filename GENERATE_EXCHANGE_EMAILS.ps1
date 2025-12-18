param(
  [string]$FromName = "Matthew Ian Dreyer",
  [string]$FromEmail = "mattdreyer356@gmail.com",
  [string]$Location = "Cincinnati, Ohio",
  [string]$SnapshotsDir = "snapshots",
  [string]$EmailsDir = "emails"
)

$ErrorActionPreference = 'Continue'

if (-not (Test-Path $SnapshotsDir)) { Write-Host "[ERR] Snapshots directory not found: $SnapshotsDir" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $EmailsDir)) { New-Item -ItemType Directory -Path $EmailsDir | Out-Null }

function Read-Base64 {
  param([string]$Path)
  try { return [Convert]::ToBase64String([IO.File]::ReadAllBytes($Path)) } catch { return $null }
}

function Build-MimeEmail {
  param(
    [string]$To,
    [string]$Subject,
    [string]$BodyText,
    [string[]]$AttachmentPaths,
    [string]$OutPath
  )
  $boundary = "----=_Part_" + [Guid]::NewGuid().ToString("N")
  $header = @(
    "To: $To",
    "From: $FromName <$FromEmail>",
    "Subject: $Subject",
    "MIME-Version: 1.0",
    "Content-Type: multipart/mixed; boundary=`"$boundary`""
  ) -join "`r`n"

  $parts = @()
  $parts += @(
    "--$boundary",
    "Content-Type: text/plain; charset=`"utf-8`"",
    "Content-Transfer-Encoding: 7bit",
    "",
    $BodyText
  ) -join "`r`n"

  foreach ($p in $AttachmentPaths) {
    if (-not (Test-Path $p)) { continue }
    $name = [IO.Path]::GetFileName($p)
    $b64 = Read-Base64 $p
    if (-not $b64) { continue }
    $parts += @(
      "--$boundary",
      "Content-Type: application/json; name=`"$name`"",
      "Content-Transfer-Encoding: base64",
      "Content-Disposition: attachment; filename=`"$name`"",
      "",
      $b64
    ) -join "`r`n"
  }

  $footer = "--$boundary--"
  $eml = $header + "`r`n`r`n" + ($parts -join "`r`n`r`n") + "`r`n" + $footer + "`r`n"
  # Write as UTF-8 to preserve characters safely across clients
  Set-Content -Path $OutPath -Value $eml -Encoding UTF8
  Write-Host "[OK] Wrote $OutPath" -ForegroundColor Green
}

# Common attachments
$common = @(
  (Join-Path $SnapshotsDir 'health.json')
  (Join-Path $SnapshotsDir 'status.json')
  (Join-Path $SnapshotsDir 'exchange_info.json')
  (Join-Path $SnapshotsDir 'market_price.json')
  (Join-Path $SnapshotsDir 'verify_supply.json')
  (Join-Path $SnapshotsDir 'rpc_blockcount.json')
  (Join-Path $SnapshotsDir 'trade_markets.json')
  (Join-Path $SnapshotsDir 'trade_orders.json')
) | Where-Object { Test-Path $_ }

# Email bodies
$contact = @"
Contacts:
- $FromName - Founder, Developer, Owner - $Location - $FromEmail
- Technical: support@spiralcoin.net
- Listing: listing@spiralcoin.net
"@

$bodyBinance = @"
Hello Binance Listings Team,

We would like to submit SpiralCoin (SPRC) for listing consideration.

- Asset: SpiralCoin (SPRC)
- Website: https://spiralcoin.net
- Public RPC: https://spiralcoin.net/api/rpc
- Status / Chain Info: https://spiralcoin.net/api/status and https://spiralcoin.net/api/exchange/info
- Supply Proof: https://spiralcoin.net/api/wallet/verify-supply (>= 22,000,000,000,000 SPRC)
- Market Data: /api/market/price and /api/market/stream (SSE)
- Submission Pack: Attached or available at https://spiralcoin.net/EXCHANGE_SUBMISSION_PACK.md

We are prepared to complete any technical integration steps or compliance requirements.

$contact

Thank you for your consideration.

Best regards,
$FromName
Founder, Developer, Owner - SpiralCoin (SPRC)
Email: $FromEmail
"@

$bodyCoinbase = @"
Hello Coinbase Team,

We're seeking listing for SpiralCoin (SPRC). Technical and endpoint details are available here:
- Exchange Submission Pack: https://spiralcoin.net/EXCHANGE_SUBMISSION_PACK.md
- Health: https://spiralcoin.net/health
- Status: https://spiralcoin.net/api/status
- RPC Proxy: https://spiralcoin.net/api/rpc
- Supply Verification: https://spiralcoin.net/api/wallet/verify-supply

Please let us know the next steps and any due diligence or documentation needed.

Regards,
$FromName
Founder, Developer, Owner - SpiralCoin (SPRC)
Email: $FromEmail
"@

$bodyKraken = @"
Hello Kraken Listings,

We'd like to request a listing review for SpiralCoin (SPRC). Details:
- Website: https://spiralcoin.net
- Exchange Info Page: https://spiralcoin.net/exchange
- Aggregate Info: https://spiralcoin.net/api/exchange/info
- Market Stream (SSE): https://spiralcoin.net/api/market/stream
- Submission Pack: https://spiralcoin.net/EXCHANGE_SUBMISSION_PACK.md

We are ready to provide additional documentation or complete any technical validation.

Sincerely,
$FromName
Founder, Developer, Owner - SpiralCoin (SPRC)
Email: $FromEmail
"@

$bodyKuCoin = @"
Dear KuCoin Team,

We'd like to apply for listing SpiralCoin (SPRC). Key technical links:
- Public RPC: https://spiralcoin.net/api/rpc
- Status: https://spiralcoin.net/api/status
- Supply Proof: https://spiralcoin.net/api/wallet/verify-supply
- Submission Pack: https://spiralcoin.net/EXCHANGE_SUBMISSION_PACK.md

Please share your required forms for evaluation.

Best,
$FromName
Founder, Developer, Owner - SpiralCoin (SPRC)
Email: $FromEmail
"@

# Generate .eml files
Build-MimeEmail -To "listings@binance.com" -Subject "Listing Request - SpiralCoin (SPRC)" -BodyText $bodyBinance -AttachmentPaths $common -OutPath (Join-Path $EmailsDir 'SpiralCoin_to_Binance.eml')
Build-MimeEmail -To "listings@coinbase.com" -Subject "SpiralCoin (SPRC) - Asset Listing Inquiry" -BodyText $bodyCoinbase -AttachmentPaths $common -OutPath (Join-Path $EmailsDir 'SpiralCoin_to_Coinbase.eml')
Build-MimeEmail -To "listings@kraken.com" -Subject "SpiralCoin (SPRC) - Market Listing Request" -BodyText $bodyKraken -AttachmentPaths $common -OutPath (Join-Path $EmailsDir 'SpiralCoin_to_Kraken.eml')
Build-MimeEmail -To "listings@kucoin.com" -Subject "SpiralCoin (SPRC) Listing Application" -BodyText $bodyKuCoin -AttachmentPaths $common -OutPath (Join-Path $EmailsDir 'SpiralCoin_to_KuCoin.eml')

Write-Host "All emails written to $EmailsDir. You can open these in your mail client and send." -ForegroundColor Cyan
