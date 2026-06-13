param(
    [Parameter(Position=0)][string]$Option,
    [Parameter(Position=1)][string]$Key
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$JavaJar   = Join-Path $ScriptDir "locker.jar"
$DataFile  = Join-Path $ScriptDir "locker.dat"
$JavaClass = "io.github.davidecolombo.locker.Locker"
$JavaExe   = if (Test-Path "$ScriptDir\jre\bin\java.exe") { "$ScriptDir\jre\bin\java.exe" } else { "java" }

function Invoke-Locker([byte[]]$InputBytes, [string[]]$ExtraArgs) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo($JavaExe)
    $psi.Arguments          = "-cp `"$JavaJar`" $JavaClass --key `"$Key`" $($ExtraArgs -join ' ')"
    $psi.RedirectStandardInput  = $true
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute        = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $proc.StandardInput.BaseStream.Write($InputBytes, 0, $InputBytes.Length)
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
    default {
        Write-Host @"
Usage: locker [OPTION] [KEY]
  -e, --encrypt   Write-Output "secret" | locker -e your_key
  -a, --append    Write-Output "more"   | locker -a your_key
  -d, --decrypt   locker -d your_key
"@
    }
}
