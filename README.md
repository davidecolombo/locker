# Locker

Locker is a command-line tool for keeping sensitive notes safe on your Windows machine.
Anything you store in it is encrypted before it touches disk, using a passphrase you choose.
There is no account, no cloud sync, and no configuration file to manage.

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later (pre-installed on all supported Windows versions)

No Java installation required. The installer bundles its own runtime.

## Installation

Open a PowerShell window and run:

```powershell
irm https://raw.githubusercontent.com/davidecolombo/locker/main/setup.ps1 | iex
```

This downloads the latest release and sets everything up automatically.
Open a new terminal window when it finishes, then verify the install:

```
locker
```

## Usage

**Store a secret:**
```
echo "my api key: abc123" | locker --encrypt your-passphrase
```

**Read it back:**
```
locker --decrypt your-passphrase
```

**Add another line to what is already stored:**
```
echo "another secret" | locker --append your-passphrase
```

The data is saved in `%LOCALAPPDATA%\locker\locker.dat`.
If you use the wrong passphrase on decrypt, the command fails with an error and nothing is shown.

## Uninstall

```powershell
irm https://raw.githubusercontent.com/davidecolombo/locker/main/uninstall.ps1 | iex
```

This removes the install directory and cleans up the PATH entry.
Your encrypted data file is deleted along with everything else.
