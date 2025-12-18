param(
    [string[]]$Containers = @('spiralcoin-backend','spiralcoin-daemon'),
    [int]$Lines = 200
)

$ErrorActionPreference = 'Stop'

# Call ssh per-container to avoid CRLF/script quoting issues
foreach ($c in $Containers) {
    Write-Host ("=== {0} ===" -f $c) -ForegroundColor Cyan
    $sshExe = 'ssh'
    $template = @'
if docker ps --format "{{.Names}}" | grep -qx "__NAME__"; then docker logs --tail __LINES__ "__NAME__"; else echo "container not found: __NAME__"; fi
'@
    $cmd = $template.Replace('__NAME__', $c).Replace('__LINES__', [string]$Lines)
    $remoteFull = "bash -lc '$cmd'"
    $sshArgs = @(
        '-o','BatchMode=yes',
        '-o','StrictHostKeyChecking=no',
        'root@174.138.37.6',
        $remoteFull
    )
    & $sshExe @sshArgs
    Write-Host ""
}
