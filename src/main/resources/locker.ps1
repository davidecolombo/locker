$Option = ""
$Key    = ""
$File   = ""
$i = 0
while ($i -lt $args.Count) {
    $arg = $args[$i]
    if     ($arg -in @("-e", "--encrypt", "-a", "--append", "-d", "--decrypt")) { $Option = $arg }
    elseif ($arg -in @("-Option", "-option"))                                   { $i++; $Option = $args[$i] }
    elseif ($arg -in @("-Key",    "-key",    "-k", "--key"))                    { $i++; $Key    = $args[$i] }
    elseif ($arg -in @("-File",   "-file",   "-f", "--file"))                   { $i++; $File   = $args[$i] }
    $i++
}

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

function Read-Passphrase([string]$PromptText) {
    # Read from CONIN$ (the console keyboard buffer) directly, NOT from stdin.
    # When data is piped (e.g. "secret" | locker -e), stdin carries the plaintext,
    # so the passphrase must come from the console itself -- the Windows equivalent
    # of reading from /dev/tty on Linux. ENABLE_ECHO_INPUT is cleared so the
    # passphrase is not displayed while typing.
    if (-not ('LockerNative.Con' -as [type])) {
        Add-Type -Namespace LockerNative -Name Con -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
public static extern System.IntPtr CreateFileW(string lpFileName, uint dwDesiredAccess, uint dwShareMode, System.IntPtr lpSecurityAttributes, uint dwCreationDisposition, uint dwFlagsAndAttributes, System.IntPtr hTemplateFile);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(System.IntPtr hConsoleHandle, out uint lpMode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(System.IntPtr hConsoleHandle, uint dwMode);
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
public static extern bool ReadConsoleW(System.IntPtr hConsoleInput, System.Text.StringBuilder lpBuffer, uint nNumberOfCharsToRead, out uint lpNumberOfCharsRead, System.IntPtr lpReserved);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool CloseHandle(System.IntPtr hObject);
'@
    }

    $GENERIC_RW    = [uint32]0xC0000000L  # GENERIC_READ | GENERIC_WRITE (L suffix: avoid Int32 overflow)
    $SHARE_RW      = [uint32]3
    $OPEN_EXISTING = [uint32]3
    $ECHO_OFF_MASK = [uint32]0xFFFFFFFBL  # ~ENABLE_ECHO_INPUT (0x0004)

    $h = [LockerNative.Con]::CreateFileW("CONIN$", $GENERIC_RW, $SHARE_RW, [System.IntPtr]::Zero, $OPEN_EXISTING, [uint32]0, [System.IntPtr]::Zero)
    if ($h -eq [System.IntPtr]::Zero -or $h -eq ([System.IntPtr](-1))) {
        # No console attached (non-interactive): fall back to stdin.
        return (Read-Host -Prompt $PromptText)
    }

    $mode = [uint32]0
    [void][LockerNative.Con]::GetConsoleMode($h, [ref]$mode)
    [void][LockerNative.Con]::SetConsoleMode($h, [uint32]($mode -band $ECHO_OFF_MASK))
    [Console]::Error.Write($PromptText + ": ")
    $sb = New-Object System.Text.StringBuilder 256
    $read = [uint32]0
    [void][LockerNative.Con]::ReadConsoleW($h, $sb, [uint32]256, [ref]$read, [System.IntPtr]::Zero)
    [void][LockerNative.Con]::SetConsoleMode($h, $mode)
    [void][LockerNative.Con]::CloseHandle($h)
    [Console]::Error.Write("`r`n")
    return $sb.ToString(0, [int]$read).TrimEnd("`r", "`n")
}

function Read-Stdin {
    $ms = New-Object System.IO.MemoryStream
    [Console]::OpenStandardInput().CopyTo($ms)
    return $ms.ToArray()
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

# Read piped stdin BEFORE prompting for the passphrase. Interactive console input
# (CONIN$) must not be performed first: doing so leaves the piped stdin unread and
# the read then blocks forever. Drain the pipe while it is still the active stdin.
$InputBytes = $null
if ($Option -in @("-e", "--encrypt", "-a", "--append")) {
    $InputBytes = Read-Stdin
}

if (-not $Key) {
    $Key = Read-Passphrase "Passphrase"
}

if ([string]::IsNullOrEmpty($Key)) {
    [Console]::Error.WriteLine("Error: passphrase cannot be empty.")
    exit 1
}

switch ($Option) {
    { $_ -in @("-e", "--encrypt") } {
        [System.IO.File]::WriteAllBytes($DataFile, (Invoke-Locker $InputBytes @()))
    }
    { $_ -in @("-d", "--decrypt") } {
        $result = Invoke-Locker ([System.IO.File]::ReadAllBytes($DataFile)) @("--decrypt")
        [Console]::Out.Write([System.Text.Encoding]::UTF8.GetString($result))
    }
    { $_ -in @("-a", "--append") } {
        $existing = [System.Text.Encoding]::UTF8.GetString(
            (Invoke-Locker ([System.IO.File]::ReadAllBytes($DataFile)) @("--decrypt")))
        $appended = [System.Text.Encoding]::UTF8.GetString($InputBytes)
        # Trim trailing newlines from the stored content before adding the single
        # separator, otherwise piped input (which carries its own trailing newline)
        # produces a blank line between entries.
        $combined = [System.Text.Encoding]::UTF8.GetBytes($existing.TrimEnd("`r", "`n") + "`n" + $appended)
        [System.IO.File]::WriteAllBytes($DataFile, (Invoke-Locker $combined @()))
    }
}
