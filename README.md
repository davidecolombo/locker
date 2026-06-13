# Locker

Locker is a command-line tool for keeping sensitive notes safe on your machine.
Anything you store in it is encrypted before it touches disk, using a passphrase you choose.
There is no account, no cloud sync, and no configuration file to manage.

## Requirements

| Platform | Requirements |
|----------|-------------|
| Windows 10 or later | PowerShell 5.1 or later (pre-installed) |
| Linux x64 / ARM (including Raspberry Pi) | curl, bash |

No Java installation required. The installer bundles its own runtime.

## Installation

**Windows** - open a PowerShell window and run:

```powershell
irm https://raw.githubusercontent.com/davidecolombo/locker/main/setup.ps1 | iex
```

Open a new terminal window when it finishes.

**Linux**:

```bash
curl -sL https://raw.githubusercontent.com/davidecolombo/locker/main/setup.sh | bash
```

Both installers download the latest release and set everything up automatically, including a bundled Java runtime. Verify the install by running:

```
locker
```

## Usage

**Store a secret:**
```
echo "my api key: abc123" | locker --encrypt
```
Locker prompts for a passphrase (input is hidden).

**Read it back:**
```
locker --decrypt
```

**Add another line to what is already stored:**
```
echo "another secret" | locker --append
```

**Use a custom file instead of the default:**
```
echo "another secret" | locker --encrypt --file /path/to/notes.dat
locker --decrypt --file /path/to/notes.dat
```

If you use the wrong passphrase on decrypt, the command fails with an error and nothing is shown.

The default data file is `%LOCALAPPDATA%\locker\locker.dat` on Windows and `/opt/locker/locker.dat` on Linux.

## Uninstall

**Windows:**
```powershell
irm https://raw.githubusercontent.com/davidecolombo/locker/main/uninstall.ps1 | iex
```

**Linux:**
```bash
curl -sL https://raw.githubusercontent.com/davidecolombo/locker/main/uninstall.sh | bash
```

This removes the install directory and cleans up the PATH entry.
Your encrypted data file is deleted along with everything else.

## Security

Locker is designed to be minimal. Minimal code means minimal attack surface.

The entire encryption logic is a single Java class with no framework dependencies beyond the JDK's own cryptography provider. There is no network stack, no database, no web interface, and no background process. The tool runs, does its job, and exits.

**What it protects against:** anyone who obtains your `locker.dat` file (through theft, backup access, or disk recovery) cannot read its contents without your passphrase. Brute-forcing the passphrase is expensive by design (310,000 PBKDF2 iterations per attempt).

**Cryptographic choices:**
- Cipher: AES-256-GCM (authenticated encryption - tampering with the file causes decryption to fail)
- Key derivation: PBKDF2/HMAC-SHA-256, 310,000 iterations, 16-byte random salt per write
- IV: 16 random bytes, unique per write
- Authentication tag: 128 bits

The passphrase is always entered interactively with no echo; it is never passed as a command-line argument and never appears in the system process list.
