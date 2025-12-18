param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ProgramArgs
)

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$root = Split-Path -Path $scriptDir -Parent

$exeCandidates = @()
$exeCandidates += (Join-Path -Path $root -ChildPath "build-ninja\spiralcoind.exe")
$exeCandidates += (Join-Path -Path $root -ChildPath "build\spiralcoind.exe")
$exeCandidates += (Join-Path -Path $root -ChildPath "build\Release\spiralcoind.exe")
$exeCandidates += (Join-Path -Path $root -ChildPath "bin\spiralcoind.exe")
$exeCandidates += (Join-Path -Path $root -ChildPath "spiralcoind.exe")

$exe = $null
foreach ($candidate in $exeCandidates) {
    if (Test-Path -LiteralPath $candidate) { $exe = $candidate; break }
}
if (-not $exe) {
    $found = Get-ChildItem -Path $root -Filter 'spiralcoind.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $exe = $found.FullName }
}
if (-not $exe) { Write-Error "spiralcoind executable not found."; exit 1 }

Write-Host "Starting detached: $exe $($ProgramArgs -join ' ')" -ForegroundColor Cyan
if ($ProgramArgs -and $ProgramArgs.Count -gt 0) {
    $proc = Start-Process -FilePath $exe -ArgumentList $ProgramArgs -NoNewWindow -PassThru
} else {
    $proc = Start-Process -FilePath $exe -NoNewWindow -PassThru
}
Write-Host "Started PID: $($proc.Id)" -ForegroundColor Green
