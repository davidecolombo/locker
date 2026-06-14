param(
    [string]$Option = "",
    [string]$Key    = "",
    [string]$File   = ""
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$JavaJar   = Join-Path $ScriptDir "locker.jar"
$DataFile  = if ($File) { $File } else { Join-Path $ScriptDir "locker.dat" }
$JavaClass = "io.github.davidecolombo.locker.Locker"
$JavaExe   = if (Test-Path "$ScriptDir\jre\bin\java.exe") { "$ScriptDir\jre\bin\java.exe" } else { "java" }

if ($Option -notin @("-e", "--encrypt", "-d", "--decrypt", "-a", "--append")) {
    Write-Host @"
Usage: locker [OPTION] [-Key PASSPHRASE] [-File PATH]
  -e, --encrypt   Write-Output "secret" | locker -e
  -a, --append    Write-Output "more"   | locker -a
  -d, --decrypt   locker -d
  -File           path to the data file (default: locker.dat next to the script)
  If -Key is omitted, the passphrase is prompted interactively with no echo.
"@
    exit 0
}

if (-not $Key) {
    Write-Host -NoNewline "Passphrase: "
    $Key = ""
    while ($true) {
        $info = [Console]::ReadKey($true)
        if ($info.Key -eq [ConsoleKey]::Enter) { break }
        if ($info.Key -eq [ConsoleKey]::Backspace) {
            if ($Key.Length -gt 0) { $Key = $Key.Substring(0, $Key.Length - 1) }
        } elseif ($info.KeyChar -ne [char]0) {
            $Key += $info.KeyChar
        }
    }
    Write-Host ""
}

if ([string]::IsNullOrEmpty($Key)) {
    [Console]::Error.WriteLine("Error: passphrase cannot be empty.")
    exit 1
}

function Invoke-Locker([byte[]]$InputBytes, [string[]]$ExtraArgs) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo($JavaExe)
    $psi.Arguments              = ("-cp `"$JavaJar`" $JavaClass " + ($ExtraArgs -join ' ')).TrimEnd()
    $psi.RedirectStandardInput  = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute        = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $passphraseBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
    $payload = $passphraseBytes + [byte[]]@(10) + $InputBytes
    $proc.StandardInput.BaseStream.Write($payload, 0, $payload.Length)
    $proc.StandardInput.Close()
    $ms = New-Object System.IO.MemoryStream
    $proc.StandardOutput.BaseStream.CopyTo($ms)
    $proc.WaitForExit()
    if ($proc.ExitCode -ne 0) { exit $proc.ExitCode }
    return $ms.ToArray()
}

switch ($Option) {
    { $_ -in @("-e", "--encrypt") } {
        $inputBytes = [System.Text.Encoding]::UTF8.GetBytes([Console]::In.ReadToEnd())
        [System.IO.File]::WriteAllBytes($DataFile, (Invoke-Locker $inputBytes @()))
    }
    { $_ -in @("-d", "--decrypt") } {
        $result = Invoke-Locker ([System.IO.File]::ReadAllBytes($DataFile)) @("--decrypt")
        [Console]::Out.Write([System.Text.Encoding]::UTF8.GetString($result))
    }
    { $_ -in @("-a", "--append") } {
        $existing = [System.Text.Encoding]::UTF8.GetString(
            (Invoke-Locker ([System.IO.File]::ReadAllBytes($DataFile)) @("--decrypt")))
        $combined = [System.Text.Encoding]::UTF8.GetBytes($existing + "`n" + [Console]::In.ReadToEnd())
        [System.IO.File]::WriteAllBytes($DataFile, (Invoke-Locker $combined @()))
    }
}
