# Agent-Flywheel Cross-Platform Setup (Windows + Ubuntu/WSL2)

This guide helps you set up the cross-platform version of agent-flywheel on Windows using Ubuntu (WSL2).

**NOTE**: This is the cross-platform version with fixes for WSL compatibility. All scripts have been updated to work on both macOS and Linux.

---

## Quick Setup (Recommended) 🚀

**One-command installation** - the installer handles everything automatically:

```bash
# 1. Clone the repository
git clone <REPO_URL> agent-flywheel-cross-platform
cd agent-flywheel-cross-platform

# 2. Run the installer
./install.sh

# 3. Start your first session
./start
```

The installer will:
- ✅ Detect WSL environment automatically
- ✅ Check and prompt to install missing dependencies (tmux, jq, docker, etc.)
- ✅ Clone and configure MCP Agent Mail
- ✅ Set up Python paths for WSL
- ✅ Configure environment variables

**That's it!** Skip to the [Troubleshooting](#troubleshooting-wsl-specific-issues) section if you encounter any issues.

---

## Manual Setup (Advanced)

If you prefer manual control or the installer doesn't work for your setup:

### 1) Prereqs (Windows)
- Install **Docker Desktop** and enable **WSL2 integration**
- Install **Git for Windows** (optional if you only use Git inside WSL)

### 2) Prereqs (Ubuntu / WSL)
```bash
sudo apt update
sudo apt install -y tmux jq curl python3 python3-pip git docker.io
```

### 3) Get agent-flywheel-cross-platform
```bash
cd ~  # or any directory of your choice
git clone <REPO_URL> agent-flywheel-cross-platform
cd agent-flywheel-cross-platform
```

### 4) MCP Agent Mail server
```bash
git clone <MCP_AGENT_MAIL_REPO_URL> ~/mcp_agent_mail
cd ~/mcp_agent_mail
echo "HTTP_BEARER_TOKEN=<YOUR_TOKEN>" > .env
docker compose up -d
```

### 5) Set permissions and run
```bash
cd ~/agent-flywheel-cross-platform
chmod +x scripts/*.sh panes/*.sh
./start
```

---

## WSL-Specific Notes

- **tmux**: Runs inside WSL (not native Windows). Use Windows Terminal for the best experience.
- **tmux usage**: `Ctrl+b` then `d` to detach, `tmux ls` to list sessions
- **Docker**: Requires Docker Desktop with WSL2 integration enabled
- **Health check**: Run `./scripts/doctor.sh` to verify your setup

## Troubleshooting WSL-Specific Issues

**First step:** Run the health check to diagnose issues:
```bash
./scripts/doctor.sh
```

### Common Issues

**Python packages not found**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**Docker not accessible**
- Enable WSL2 integration in Docker Desktop settings
- Verify with: `docker ps`

**tmux colors wrong**
```bash
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

**Permission denied**
```bash
chmod +x scripts/*.sh panes/*.sh
```

For more help, see the main [README.md](README.md) troubleshooting section.
