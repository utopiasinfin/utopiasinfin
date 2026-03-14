# Home Lab Manager (Bash)

An interactive, menu-driven Bash script for monitoring and managing a Debian/Fedora home lab server from the terminal.

## 🚀 What it does

This script is designed as a learning and utility tool:
- Displays system information (kernel, OS, uptime, CPU, memory, disk)
- Provides process monitoring (top processes by CPU/memory)
- Shows network interfaces, open ports, and routing
- Checks service status for common server services
- Performs read-only security diagnostics (open ports, shell users, firewall)
- Includes quick user-level actions (disk usage, USB devices, logs, process search)
- Supports CLI options for non-interactive use (`--sysinfo`, `--monitor`, etc.)

## 🛡️ Security policy

This script is intentionally non-privileged:
- No `sudo` usage
- Read-only system inspection
- Menu + CLI options to keep actions safe

## 📁 Files

- `homelab_vscode.sh` — main script
- `README.md` — project documentation

## ▶️ How to run

```bash
bash homelab_vscode.sh
```

Or run one command directly:

```bash
bash homelab_vscode.sh --sysinfo
bash homelab_vscode.sh --monitor
bash homelab_vscode.sh --network
bash homelab_vscode.sh --services
bash homelab_vscode.sh --security
```

## 🧠 Learn-by-doing goals

This project was built to learn:
- Bash scripting structure and functions
- Terminal UI formatting (colors, tables, separators)
- System commands (`uname`, `ip`, `ss`, `systemctl`, `ps`, etc.)
- Secure script design (no editing, no sudo)

## 📦 Requirements

- Linux system (Debian/Fedora compatible)
- Bash shell
- Basic system tools available (`ps`, `ip`, `ss`, `systemctl`)

## 🔧 Optional improvement ideas

- Add an explicit guard to refuse root execution
- Add a `--version` and `--config` option
- Add logging to a `logs/` folder (optional and non-privileged)

## 📦 Publish to GitHub

1. Create a new repository at https://github.com/new.
2. Clone into your local folder:
   ```bash
git clone https://github.com/<your-user>/homelab-manager.git
cd homelab-manager
   ```
3. Copy script and README into repository:
   ```bash
cp /home/utopiasinfinfedora/scripte/homelab_vscode.sh .
cp /home/utopiasinfinfedora/scripte/README.md .
chmod +x homelab_vscode.sh
   ```
4. Commit and push:
   ```bash
git add homelab_vscode.sh README.md
git commit -m "Add Home Lab Manager Bash script"
git push origin main
   ```
5. (Optional) Add a short description and topics in GitHub repo settings.

## ✨ Quick GitHub description

> Interactive Bash Home Lab Manager for Debian/Fedora systems. Read-only server diagnostics and monitoring with a simple terminal menu. Great for learning Bash and system tools.
