# Agent-Flywheel Cross-Platform Setup (Windows + Ubuntu/WSL2)

This guide helps you set up the cross-platform version of agent-flywheel on Windows using Ubuntu (WSL2).

**NOTE**: This is the cross-platform version with fixes for WSL compatibility. All scripts have been updated to work on both macOS and Linux.

## 1) Prereqs (Windows)
- Install **Docker Desktop** and enable **WSL2 integration**.
- Install **Git for Windows** (optional if you only use Git inside WSL).

## 2) Prereqs (Ubuntu / WSL)
```bash
sudo apt update
sudo apt install -y tmux jq curl python3 git
```
(Optional) if available in your distro:
```bash
sudo apt install -y fswatch
```

## 3) Get agent-flywheel-cross-platform
```bash
# Clone to any directory you prefer (no specific structure required)
cd ~  # or any directory of your choice
git clone <REPO_URL> agent-flywheel-cross-platform
cd agent-flywheel-cross-platform

# Option B: Copy from existing installation
# (If you already have it on macOS and are using shared folders)
cp -r /mnt/c/Users/<your-windows-user>/path/to/agent-flywheel-cross-platform ~/
```

## 4) MCP Agent Mail server
```bash
git clone <MCP_AGENT_MAIL_REPO_URL> ~/mcp_agent_mail
```
Create `~/mcp_agent_mail/.env` with:
```
HTTP_BEARER_TOKEN=<TOKEN>
```
Start the server:
```bash
cd ~/mcp_agent_mail && docker compose up -d
```

## 5) Claude Hooks
Copy the hooks into `~/.claude/hooks/`:
```bash
mkdir -p ~/.claude/hooks
# Copy the hook(s) from this repo or from the source you were given
cp /path/to/directory-restriction.py ~/.claude/hooks/
```
Configure the hook to allow your project directory (hooks can be configured for any location).

## 6) Permissions
```bash
cd /path/to/agent-flywheel-cross-platform
chmod +x scripts/*.sh
chmod +x panes/*.sh
```

## 7) Run
```bash
cd /path/to/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
```

**Important:** When prompted for the project path, choose the **project root** (not the `scripts/` folder).

**No more `.fixed.v4.8` needed!** This cross-platform version works out of the box on WSL.

## Notes
- If mail seems missing, make sure the Mail server is running (`docker ps`).
- If hooks block commands in a new project, confirm `directory-restriction.py` allows your project directory.
- tmux runs **inside WSL** (not native Windows). Use Windows Terminal for the best experience.
- For tmux usage: `Ctrl+b` then `d` to detach, `tmux ls` to list sessions.

## What's Fixed in This Cross-Platform Version

This version includes three critical fixes for WSL compatibility:

1. **Dynamic path detection** - No hardcoded `/Users/james` paths
   - Line 414 in `start-multi-agent-session.sh` now uses script-relative paths

2. **Cross-platform sed** - Uses `tr` instead of macOS-specific `sed -E`
   - Line 272 in `start-multi-agent-session.sh` now works on Linux

3. **Platform-aware Python paths** - Automatically detects macOS vs Linux
   - `setup-openai-key.sh` uses `~/.local/bin` on Linux
   - `add-aider-to-path.sh` uses `~/.local/bin` on Linux
   - Shell detection works with both bash and zsh

## Troubleshooting WSL-Specific Issues

### Python packages not found
```bash
# Ensure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Auto-registration fails (no agent names)
Ensure `python3` is installed and on PATH (required for name generation):
```bash
python3 --version
```

### Docker not accessible
```bash
# Check Docker Desktop WSL integration is enabled
docker ps
# If it fails, enable WSL integration in Docker Desktop settings
```

### tmux colors look wrong
```bash
# Add to ~/.bashrc
echo 'export TERM=xterm-256color' >> ~/.bashrc
source ~/.bashrc
```

### Permission denied on scripts
```bash
# Make sure all scripts are executable
cd /path/to/agent-flywheel-cross-platform
chmod +x scripts/*.sh
chmod +x panes/*.sh
```
