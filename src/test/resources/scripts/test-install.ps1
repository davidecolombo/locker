param(
    [Parameter(Mandatory)][string]$ProjectDir
)

$ErrorActionPreference = "Stop"
$passCount = 0
$failCount = 0

function Write-Result([bool]$Passed, [string]$Name) {
    if ($Passed) {
        Write-Host "[PASS] $Name"
        $script:passCount++
    } else {
        Write-Host "[FAIL] $Name"
        $script:failCount++
    }
}

$TempInstallDir = Join-Path $env:TEMP "locker-install-test-$(Get-Random)"
$TempSourceDir  = Join-Path $env:TEMP "locker-source-$(Get-Random)"

try {
    # Stage sources (jar from target/, ps1 from src/main/resources/)
    New-Item -ItemType Directory $TempSourceDir | Out-Null
    Copy-Item "$ProjectDir\target\locker.jar"             (Join-Path $TempSourceDir "locker.jar")
    Copy-Item "$ProjectDir\src\main\resources\locker.ps1" (Join-Path $TempSourceDir "locker.ps1")

    # --- install ---
    & "$ProjectDir\install.ps1" -InstallDir $TempInstallDir -SourceDir $TempSourceDir -SkipEnvUpdate

    Write-Result (Test-Path "$TempInstallDir\locker.jar") "install: locker.jar copied"
    Write-Result (Test-Path "$TempInstallDir\locker.ps1") "install: locker.ps1 copied"
    Write-Result (Test-Path "$TempInstallDir\locker.dat") "install: locker.dat created"

    # idempotent re-install must not fail or duplicate locker.dat
    & "$ProjectDir\install.ps1" -InstallDir $TempInstallDir -SourceDir $TempSourceDir -SkipEnvUpdate
    Write-Result $true "install: idempotent re-run succeeds"

    # --- uninstall ---
    & "$ProjectDir\uninstall.ps1" -InstallDir $TempInstallDir -SkipEnvUpdate
    Write-Result (-not (Test-Path $TempInstallDir)) "uninstall: directory removed"

} finally {
    Remove-Item $TempInstallDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $TempSourceDir  -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "install/uninstall integration: $passCount passed, $failCount failed"
}

if ($failCount -gt 0) { exit 1 }
exit 0
