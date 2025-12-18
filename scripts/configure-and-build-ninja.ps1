param()
$ErrorActionPreference = "Stop"

# Ensure paths
$cmakeBin = "C:\Program Files\CMake\bin"
$mingwBin = "C:\msys64\mingw64\bin"
if (Test-Path $cmakeBin) { $Env:Path += ";$cmakeBin" }
if (Test-Path $mingwBin) { $Env:Path += ";$mingwBin" }

# Find ninja.exe explicitly (winget path)
$ninjaCandidates = @(
  "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Ninja-build.Ninja_Microsoft.Winget.Source_8wekyb3d8bbwe\ninja.exe",
  "$env:LOCALAPPDATA\Programs\ninja\ninja.exe",
  "C:\Program Files\ninja\ninja.exe",
  "C:\Program Files (x86)\ninja\ninja.exe"
)
$ninjaExe = $null
foreach ($p in $ninjaCandidates) { if (Test-Path $p) { $ninjaExe = $p; break } }
if (-not $ninjaExe) {
  $cmd = Get-Command ninja -ErrorAction SilentlyContinue
  if ($cmd) { $ninjaExe = $cmd.Source }
}
if (-not $ninjaExe) { throw "ninja.exe not found. Restart terminal or install Ninja (winget install Ninja-build.Ninja)." }
Write-Host "[INFO] Using ninja: $ninjaExe" -ForegroundColor Yellow

# Fresh build dir
$buildDir = "build-ninja"
if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Configure
& cmake -S . -B $buildDir -G "Ninja" -DCMAKE_MAKE_PROGRAM="$ninjaExe" -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_FLAGS="-O1" -DCMAKE_CXX_FLAGS="-O1"

# Build
& cmake --build $buildDir -- -j1

# Verify output
$out = Join-Path $buildDir "spiralcoind.exe"
if (Test-Path $out) {
  Write-Host "[DONE] Build succeeded: $out" -ForegroundColor Green
} else {
  Write-Host "[WARN] Build completed but binary not found at $out" -ForegroundColor Yellow
}
