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

if (-not $SkipEnvUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallDir", "User")
    }

    $pathExt = [Environment]::GetEnvironmentVariable("PATHEXT", "User")
    if (-not $pathExt) { $pathExt = [Environment]::GetEnvironmentVariable("PATHEXT", "Machine") }
    if ($pathExt -notlike "*.PS1*") {
        [Environment]::SetEnvironmentVariable("PATHEXT", "$pathExt;.PS1", "User")
    }
}
