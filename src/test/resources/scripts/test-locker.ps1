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

function Invoke-LockerScript([string]$Option, [string]$Key, [string]$InputText = "") {
    $psi = New-Object System.Diagnostics.ProcessStartInfo("powershell")
    $psi.Arguments            = "-NoProfile -ExecutionPolicy Bypass -File `"$Script`" -Option `"$Option`" -Key `"$Key`""
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

    # Test 1: encrypt -> decrypt
    Invoke-LockerScript "--encrypt" $Key $PlainText | Out-Null
    $decrypted = Invoke-LockerScript "--decrypt" $Key
    Write-Result ($decrypted -eq $PlainText) "encrypt -> decrypt"

    # Test 2: append -> decrypt
    Invoke-LockerScript "--append" $Key $AppendText | Out-Null
    $final = Invoke-LockerScript "--decrypt" $Key
    Write-Result ($final -eq "$PlainText`n$AppendText") "append -> decrypt"

    # Test 3: wrong key must be rejected
    $wrongKeyRejected = $false
    try { Invoke-LockerScript "--decrypt" "wrong-key" | Out-Null }
    catch { $wrongKeyRejected = $true }
    Write-Result $wrongKeyRejected "wrong key is rejected"

} finally {
    Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ""
    Write-Host "locker.ps1 integration: $passCount passed, $failCount failed"
}

if ($failCount -gt 0) { exit 1 }
exit 0
