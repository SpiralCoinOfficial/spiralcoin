param(
    [string]$GxxPath = "C:/msys64/mingw64/bin/g++.exe"
)

Write-Host "=== SpiralCoin: Windows MinGW Build ==="
if (-not (Test-Path $GxxPath)) {
    Write-Error "g++ not found at: $GxxPath. Install MSYS2 and mingw-w64 toolchain, or pass -GxxPath to this script."
    Write-Host "Install MSYS2: https://www.msys2.org/"
    Write-Host "Then in MSYS2 terminal: pacman -Syu; pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb mingw-w64-x86_64-nlohmann-json"
    exit 1
}

$Workspace = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
Set-Location $Workspace

New-Item -ItemType Directory -Force -Path "$Workspace/build" | Out-Null

$includes = @("-I", "include")
$srcPattern = "src/*.cpp"
$out = "build/spiralcoind.exe"

$cmd = @(
    '"' + $GxxPath + '"',
    "-std=c++20",
    $includes,
    $srcPattern,
    "-o", $out,
    "-pthread",
    "-D", "HAVE_EVMONE=0"
) | ForEach-Object { $_ }

Write-Host "Building with: $GxxPath"
$proc = Start-Process -FilePath powershell -ArgumentList "-NoProfile","-NonInteractive","-Command", ($cmd -join ' ') -PassThru -Wait -WindowStyle Hidden
if ($proc.ExitCode -ne 0) {
    Write-Error "Build failed with exit code $($proc.ExitCode)"
    exit $proc.ExitCode
}

Write-Host "Build complete: $out"
