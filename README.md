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

**Windows** -- open a PowerShell window and run:

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

**Use a custom file instead of the default:**
```
echo "another secret" | locker --encrypt your-passphrase --file /path/to/notes.dat
locker --decrypt your-passphrase --file /path/to/notes.dat
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
