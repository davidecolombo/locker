#Requires -RunAsAdministrator
$InstallDir = "C:\ProgramData\locker"

Remove-Item -Recurse -Force $InstallDir -ErrorAction SilentlyContinue

$machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = ($machinePath -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
[Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
