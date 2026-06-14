param(
    [string]$InstallDir     = "$env:LOCALAPPDATA\locker",
    [string]$SourceDir      = ".\dist",
    [switch]$SkipEnvUpdate,
    [switch]$SkipJreDownload
)

New-Item -ItemType Directory -Force $InstallDir | Out-Null
Copy-Item "$SourceDir\locker.jar" $InstallDir -Force
# Install the script as locker-run.ps1, NOT locker.ps1. If a "locker.ps1" sat in a
# PATH directory, typing "locker" would make PowerShell run the .ps1 in-process,
# bypassing the cmd shim; piped stdin then arrives via the PowerShell object pipeline
# instead of OS stdin and is unreadable. A non-colliding name forces "locker" to
# resolve to locker.cmd (a real child process with proper stdin redirection).
Copy-Item "$SourceDir\locker.ps1" "$InstallDir\locker-run.ps1" -Force
# Remove a stale locker.ps1 from older installs so it cannot shadow the cmd shim.
if (Test-Path "$InstallDir\locker.ps1") {
    Remove-Item "$InstallDir\locker.ps1" -Force
}
if (-not (Test-Path "$InstallDir\locker.dat")) {
    New-Item -ItemType File "$InstallDir\locker.dat" | Out-Null
}

# cmd shim so "locker" works from any terminal without extension
$shim = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0locker-run.ps1`" %*"
[System.IO.File]::WriteAllText("$InstallDir\locker.cmd", $shim, [System.Text.Encoding]::ASCII)

# JRE — copy from source dir if already present, otherwise download from Adoptium
$JreDir = "$InstallDir\jre"
if (Test-Path "$SourceDir\jre\bin\java.exe") {
    Copy-Item "$SourceDir\jre" $JreDir -Recurse -Force
} elseif (-not $SkipJreDownload -and -not (Test-Path "$JreDir\bin\java.exe")) {
    Write-Host "Downloading Eclipse Temurin JRE 25..."
    $jreZip = "$env:TEMP\locker-jre-$(Get-Random).zip"
    $jreTemp = "$env:TEMP\locker-jre-$(Get-Random)"
    Invoke-WebRequest "https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jre/hotspot/normal/eclipse" `
        -OutFile $jreZip
    Expand-Archive $jreZip $jreTemp -Force
    $extracted = Get-ChildItem $jreTemp -Directory | Select-Object -First 1
    Move-Item $extracted.FullName $JreDir
    Remove-Item $jreZip, $jreTemp -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "JRE installed."
}

if (-not $SkipEnvUpdate) {
    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallDir", "User")
        Write-Host "PATH updated. Open a new terminal to use 'locker'."
    }
}
