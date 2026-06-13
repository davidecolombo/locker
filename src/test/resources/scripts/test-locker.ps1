param(
    [Parameter(Mandatory)][string]$JarPath,
    [Parameter(Mandatory)][string]$ScriptPath
)

$ErrorActionPreference = "Stop"
$passCount = 0
$failCount = 0

$TempDir = Join-Path $env:TEMP "locker-test-$(Get-Random)"
New-Item -ItemType Directory $TempDir | Out-Null

function Write-Result([bool]$Passed, [string]$Name) {
    if ($Passed) {
        Write-Host "[PASS] $Name"
        $script:passCount++
    } else {
        Write-Host "[FAIL] $Name"
        $script:failCount++
    }
}

function Invoke-LockerScript([string]$Option, [string]$Key, [string]$InputText = "", [string]$File = "") {
    $fileArg = if ($File) { " -File `"$File`"" } else { "" }
    $psi = New-Object System.Diagnostics.ProcessStartInfo("powershell")
    $psi.Arguments            = "-NoProfile -ExecutionPolicy Bypass -File `"$Script`" -Option `"$Option`" -Key `"$Key`"$fileArg"
    $psi.RedirectStandardInput  = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    if ($InputText -ne "") {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputText)
        $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
    }
    $proc.StandardInput.Close()
    $ms = New-Object System.IO.MemoryStream
    $proc.StandardOutput.BaseStream.CopyTo($ms)
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) {
        $err = $proc.StandardError.ReadToEnd()
        throw "locker.ps1 '$Option' exited $($proc.ExitCode): $err"
    }
    return [System.Text.Encoding]::UTF8.GetString($ms.ToArray())
}

try {
    $Script     = Join-Path $TempDir "locker.ps1"
    $Key        = "integration-test-key"
    $PlainText  = "The quick brown fox jumps over the lazy dog"
    $AppendText = "Another secret line"

    Copy-Item $JarPath    (Join-Path $TempDir "locker.jar")
    Copy-Item $ScriptPath $Script
    New-Item -ItemType File (Join-Path $TempDir "locker.dat") | Out-Null

    # Test 1: encrypt -> decrypt (default file)
    Invoke-LockerScript "--encrypt" $Key $PlainText | Out-Null
    $decrypted = Invoke-LockerScript "--decrypt" $Key
    Write-Result ($decrypted -eq $PlainText) "encrypt -> decrypt (default file)"

    # Test 2: append -> decrypt (default file)
    Invoke-LockerScript "--append" $Key $AppendText | Out-Null
    $final = Invoke-LockerScript "--decrypt" $Key
    Write-Result ($final -eq "$PlainText`n$AppendText") "append -> decrypt (default file)"

    # Test 3: wrong key must be rejected
    $wrongKeyRejected = $false
    try { Invoke-LockerScript "--decrypt" "wrong-key" | Out-Null }
    catch { $wrongKeyRejected = $true }
    Write-Result $wrongKeyRejected "wrong key is rejected"

    # Test 4: encrypt -> decrypt with custom --file
    $customDat = Join-Path $TempDir "custom.dat"
    New-Item -ItemType File $customDat | Out-Null
    Invoke-LockerScript "--encrypt" $Key $PlainText -File $customDat | Out-Null
    $decryptedCustom = Invoke-LockerScript "--decrypt" $Key -File $customDat
    Write-Result ($decryptedCustom -eq $PlainText) "encrypt -> decrypt (custom file)"

    # Test 5: custom file is independent from default file
    $defaultDat = Join-Path $TempDir "locker.dat"
    Write-Result ((Get-Item $defaultDat).Length -ne (Get-Item $customDat).Length -or
                  [System.IO.File]::ReadAllBytes($defaultDat) -ne [System.IO.File]::ReadAllBytes($customDat)) `
        "custom file is independent from default file"

} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "locker.ps1 integration: $passCount passed, $failCount failed"
}

if ($failCount -gt 0) { exit 1 }
exit 0
