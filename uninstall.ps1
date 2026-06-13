param(
    [string]$InstallDir    = "$env:LOCALAPPDATA\locker",
    [switch]$SkipEnvUpdate
)

Remove-Item -Recurse -Force $InstallDir -ErrorAction SilentlyContinue

if (-not $SkipEnvUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = ($userPath -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}
