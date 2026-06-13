param(
    [string]$InstallDir    = "$env:LOCALAPPDATA\locker",
    [string]$SourceDir     = ".\dist",
    [switch]$SkipEnvUpdate
)

New-Item -ItemType Directory -Force $InstallDir | Out-Null
Copy-Item "$SourceDir\locker.jar" $InstallDir -Force
Copy-Item "$SourceDir\locker.ps1" $InstallDir -Force
if (-not (Test-Path "$InstallDir\locker.dat")) {
    New-Item -ItemType File "$InstallDir\locker.dat" | Out-Null
}

# cmd shim so "locker" works from any terminal without extension
$shim = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0locker.ps1`" %*"
[System.IO.File]::WriteAllText("$InstallDir\locker.cmd", $shim, [System.Text.Encoding]::ASCII)

if (-not $SkipEnvUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallDir", "User")
        Write-Host "PATH updated. Open a new terminal to use 'locker'."
    }
}
