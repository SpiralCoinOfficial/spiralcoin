# Stops any running SpiralCoin daemon processes on Windows
$names = @('spiralcoind', 'spiralcoind.exe')
$stopped = $false
foreach ($n in $names) {
    $procs = Get-Process -Name $n -ErrorAction SilentlyContinue
    foreach ($p in $procs) {
        Write-Host "Stopping process $($p.Id) ($($p.ProcessName))" -ForegroundColor Yellow
        try {
            Stop-Process -Id $p.Id -Force -ErrorAction Stop
            $stopped = $true
        } catch {
            Write-Warning "Failed to stop process $($p.Id): $($_.Exception.Message)"
        }
    }
}
if (-not $stopped) { Write-Host "No spiralcoind processes found." -ForegroundColor Green }
