#Requires -RunAsAdministrator
$InstallDir = "C:\ProgramData\locker"

New-Item -ItemType Directory -Force $InstallDir | Out-Null
Copy-Item .\dist\locker.jar $InstallDir -Force
Copy-Item .\dist\locker.ps1 $InstallDir -Force
if (-not (Test-Path "$InstallDir\locker.dat")) {
    New-Item -ItemType File "$InstallDir\locker.dat" | Out-Null
}

$machinePath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($machinePath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$machinePath;$InstallDir", "Machine")
}

$pathExt = [Environment]::GetEnvironmentVariable("PATHEXT", "Machine")
if ($pathExt -notlike "*.PS1*") {
    [Environment]::SetEnvironmentVariable("PATHEXT", "$pathExt;.PS1", "Machine")
}
