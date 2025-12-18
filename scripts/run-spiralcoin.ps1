param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ProgramArgs
)

# Determine workspace root robustly
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$root = Split-Path -Path $scriptDir -Parent

# Candidate executable locations
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

# Fallback: search recursively for the executable
if (-not $exe) {
    $found = Get-ChildItem -Path $root -Filter 'spiralcoind.exe' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($found) { $exe = $found.FullName }
}

if (-not $exe) {
    Write-Error "spiralcoind executable not found. Checked:`n$($exeCandidates -join "`n")."
    exit 1
}

Write-Host "Running: $exe $($ProgramArgs -join ' ')" -ForegroundColor Cyan
& $exe @ProgramArgs
