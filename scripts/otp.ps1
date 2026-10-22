# Shows development OTP codes as the API generates them (OTP_PROVIDER=console only).
# Usage, from anywhere:  powershell -ExecutionPolicy Bypass -File scripts\otp.ps1
#   -Since 30m   also show codes from the last 30 minutes (default 10m)
param([string]$Since = '10m')

$compose = Join-Path $PSScriptRoot '..\docker-compose.yml'
Write-Host "Watching for OTP codes (codes expire 5 minutes after they are sent). Ctrl+C to stop." -ForegroundColor Cyan

$last = ''
docker compose -f $compose logs -f --no-log-prefix --since $Since api 2>&1 | ForEach-Object {
    $line = "$_"
    if ($line -match '^(\S+ \S+?)(?:,\d+)? .*\[DEV OTP\] phone=(\S+) code=(\d{6})') {
        $entry = "$($Matches[1])  $($Matches[2])  ->  $($Matches[3])"
        # The logger prints each code twice; show it once.
        if ($entry -ne $last) {
            Write-Host $entry -ForegroundColor Green
            $last = $entry
        }
    }
}
