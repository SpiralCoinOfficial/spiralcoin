param()
$ErrorActionPreference = "Stop"

function Is-Admin {
  $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
  $wp = New-Object Security.Principal.WindowsPrincipal($wi)
  return $wp.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (Is-Admin)) {
  Write-Host "[INFO] Elevating to Administrator..." -ForegroundColor Yellow
  $args = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
  Start-Process -Verb RunAs powershell.exe -ArgumentList $args -Wait
  Write-Host "[INFO] Elevated run finished." -ForegroundColor Yellow
  exit 0
}

$path = "C:\Program Files\CMake\share\cmake-4.2\Modules\CMakeTestCCompiler.cmake"
if (-not (Test-Path $path)) { throw "CMakeTestCCompiler.cmake not found at $path" }
$backup = "$path.bak"

Copy-Item $path $backup -Force
Write-Host "[STEP] Backed up to: $backup" -ForegroundColor Cyan

$content = Get-Content $path -Raw
# Replace the stray line with the correct message() start
$fixed = [Regex]::Replace(
  $content,
  '^[\s]*l for me[\s]*$',
  '    message(FATAL_ERROR "The C compiler`n  \"${CMAKE_C_COMPILER}\"`n"',
  [System.Text.RegularExpressions.RegexOptions]::Multiline
)

if ($fixed -eq $content) {
  Write-Host "[WARN] No stray line found; leaving file unchanged." -ForegroundColor Yellow
} else {
  Set-Content -Path $path -Value $fixed -Encoding UTF8
  Write-Host "[DONE] Patched CMakeTestCCompiler.cmake" -ForegroundColor Green
}

# Validate
$hasMsg = Select-String -Path $path -Pattern 'message\(FATAL_ERROR' -Quiet
$hasStray = Select-String -Path $path -Pattern '^[\s]*l for me[\s]*$' -Quiet
if ($hasMsg -and -not $hasStray) {
  Write-Host "[OK] Validation passed: message(FATAL_ERROR) present and stray text removed." -ForegroundColor Green
} else {
  Write-Host "[WARN] Validation inconclusive. Please open file to verify manually." -ForegroundColor Yellow
}
