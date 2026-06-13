$ErrorActionPreference = "Stop"

$InstallDir = "$env:LOCALAPPDATA\locker"
$TempDir    = "$env:TEMP\locker-install-$(Get-Random)"

try {
    Write-Host "Fetching latest locker release..."
    $release  = Invoke-RestMethod "https://api.github.com/repos/davidecolombo/locker/releases/latest"
    $jarAsset = $release.assets | Where-Object { $_.name -eq "locker.jar"  } | Select-Object -First 1
    $ps1Asset = $release.assets | Where-Object { $_.name -eq "locker.ps1"  } | Select-Object -First 1

    if (-not $jarAsset) { throw "Release asset locker.jar not found. Publish a GitHub release first." }
    if (-not $ps1Asset) { throw "Release asset locker.ps1 not found. Publish a GitHub release first." }

    New-Item -ItemType Directory $TempDir | Out-Null

    Write-Host "Downloading locker $($release.tag_name)..."
    Invoke-WebRequest $jarAsset.browser_download_url -OutFile "$TempDir\locker.jar"
    Invoke-WebRequest $ps1Asset.browser_download_url -OutFile "$TempDir\locker.ps1"

    Write-Host "Downloading Eclipse Temurin JRE 25..."
    $jreZip  = "$TempDir\jre.zip"
    $jreTemp = "$TempDir\jre-extracted"
    Invoke-WebRequest "https://api.adoptium.net/v3/binary/latest/25/ga/windows/x64/jre/hotspot/normal/eclipse" `
        -OutFile $jreZip
    Expand-Archive $jreZip $jreTemp -Force
    $extracted = Get-ChildItem $jreTemp -Directory | Select-Object -First 1
    Move-Item $extracted.FullName "$TempDir\jre"

    Write-Host "Installing to $InstallDir..."
    New-Item -ItemType Directory -Force $InstallDir | Out-Null
    Copy-Item "$TempDir\locker.jar" $InstallDir -Force
    Copy-Item "$TempDir\locker.ps1" $InstallDir -Force
    Copy-Item "$TempDir\jre"        $InstallDir -Recurse -Force
    if (-not (Test-Path "$InstallDir\locker.dat")) {
        New-Item -ItemType File "$InstallDir\locker.dat" | Out-Null
    }

    $shim = "@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"%~dp0locker.ps1`" %*"
    [System.IO.File]::WriteAllText("$InstallDir\locker.cmd", $shim, [System.Text.Encoding]::ASCII)

    $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($userPath -notlike "*$InstallDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$userPath;$InstallDir", "User")
    }

    Write-Host ""
    Write-Host "locker $($release.tag_name) installed. Open a new terminal and run: locker --decrypt your-key"

} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
}
