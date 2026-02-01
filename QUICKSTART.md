# Quick Start Guide

Get Agent Flywheel running in 5 minutes.

---

## Prerequisites

You need:
- **Mac** or **Windows** (with WSL) or **Linux**
- **Git** installed
- **Terminal** access

That's it! The installer handles everything else.

---

## Installation

### Mac / Linux

```bash
# 1. Clone the repository
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel-cross-platform

# 2. Run the installer
./install.sh

# 3. Start the visual manager
./start
```

### Windows

```cmd
REM 1. Clone the repository
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel-cross-platform

REM 2. Run the launcher (installs WSL if needed)
start.bat
```

The Windows launcher (`start.bat`) will:
- Check if WSL is installed
- Offer to install WSL if missing (automated!)
- Set up Ubuntu in WSL
- Run the installer automatically
- Launch the visual session manager

---

## First Time Setup

The installer will ask you a few questions:

### 1. Authentication Method

**Option A: ChatGPT OAuth** (Recommended - saves money!)
- Costs ~$200/month (ChatGPT subscription)
- Saves $400+/month vs API billing
- Choose this if you already have ChatGPT Plus

**Option B: API Key**
- Pay per token via Anthropic API
- More flexible for light usage
- Choose this if you don't have ChatGPT subscription

### 2. Dependencies

The installer will check for and install:
- **tmux** - Terminal multiplexer for managing agents
- **fzf** - Fuzzy finder for the visual interface
- **jq** - JSON processor for configuration
- **docker** - For MCP Agent Mail server
- **python3** - Required for some scripts

All dependencies are installed automatically!

### 3. MCP Agent Mail

The installer will:
- Clone the MCP Agent Mail repository
- Set up the configuration
- Start the Docker container
- Verify it's running on port 8765

This enables agents to communicate with each other.

---

## Creating Your First Session

After installation, the visual session manager appears automatically.

### Press **Ctrl+N** to create a new session

You'll go through 4 simple steps:

#### Step 1: Select Project Folder
- A file picker appears
- Navigate to your project
- Press Enter

#### Step 2: Name Your Session
- Type a name (e.g., "my-app")
- Or press Enter to use the folder name
- It will warn you if the name conflicts with an existing session

#### Step 3: Configure Agents
- **Claude agents** (default: 2) - Main coding agents
- **Codex agents** (default: 0) - Specialized for certain tasks
- Must have at least 1 agent total

**Tip:** Start with 2 Claude agents if you're not sure.

#### Step 4: Shared Task List (optional)
- **Yes** - All agents see and work on the same tasks (collaborative)
- **No** - Each agent has its own task list (independent)

**Tip:** Choose "Yes" for complex projects where agents need to coordinate.

#### Step 5: Confirm
- Review your settings
- Press **Y** to create
- Session starts immediately!

---

## Using Your Session

### Inside a Multi-Agent Session

Each agent runs in its own tmux pane. You'll see:

```
╭─────────────────╮ ╭─────────────────╮
│   claude-1      │ │   claude-2      │
│                 │ │                 │
│  [Agent output] │ │  [Agent output] │
╰─────────────────╯ ╰─────────────────╯
```

### Tmux Basics

- **Ctrl+b** then **arrow key** - Navigate between panes
- **Ctrl+b** then **d** - Detach (session keeps running)
- **Ctrl+b** then **[** - Scroll mode (q to exit)

### Detaching and Reattaching

**Detach:**
Press **Ctrl+b** then **d** to detach. The session continues in the background.

**Reattach:**
1. Run `./start` again
2. Select your session from the list
3. Press **Enter** → **A** (Attach)

---

## Managing Sessions

The visual session manager shows all your sessions:

```
╭────────────────────────────────────────╮
│  Agent Flywheel - Session Manager     │
╰────────────────────────────────────────╯

  🟢 my-app        Running    3 Claude, 1 Codex
  🔵 website       Attached   2 Claude
  💀 old-project   Killed     Jan 31
```

### Status Icons

- **🟢 Running** - Session is active but not attached
- **🔵 Attached** - You're currently in this session
- **💀 Killed** - Session was stopped but saved (can be resurrected)

### Actions

Select one or more sessions (use Tab for multiple), then press Enter:

- **A** - Attach to session
- **K** - Kill session (saves state for later)
- **R** - Resurrect killed session
- **D** - Delete permanently

---

## Common Commands

| Task | Command |
|------|---------|
| Start visual manager | `./start` |
| Create new session | `./start` → **Ctrl+N** |
| Attach to session | `./start` → Select → **Enter** → **A** |
| Detach from session | Inside session: **Ctrl+b** then **d** |
| Kill session (save) | `./start` → Select → **Enter** → **K** |
| Resurrect session | `./start` → Select 💀 → **Enter** → **R** |
| Delete permanently | `./start` → Select 💀 → **Enter** → **D** |
| Check system health | `./scripts/doctor.sh` |

---

## Troubleshooting

### Session Won't Start

Run the health check:
```bash
./scripts/doctor.sh
```

This checks:
- All dependencies installed
- Docker is running
- MCP Agent Mail is working
- Tmux configuration is correct

### MCP Agent Mail Not Working

```bash
# Check if container is running
docker ps | grep mcp-agent-mail

# Restart it if needed
cd ~/mcp_agent_mail
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Can't See Visual Manager

Make sure you have **fzf** installed:
```bash
# Mac
brew install fzf

# Ubuntu/Debian
sudo apt install fzf

# Or use installer again
./install.sh
```

### Permission Denied

Make sure scripts are executable:
```bash
chmod +x install.sh start scripts/*.sh
```

---

## Next Steps

Now that you're set up:

1. **Read the main README.md** - Full feature documentation
2. **Check out AGENT_MAIL.md** - Learn about agent communication
3. **Try file reservations** - `./scripts/reserve-files.sh --help`
4. **Explore the docs/** - Guides for advanced features

---

## Getting Help

- **Issues:** Report bugs at https://github.com/7D-Solutions/agent-flywheel-cross-platform/issues
- **Documentation:** See README.md and docs/ directory
- **Health Check:** Run `./scripts/doctor.sh` to diagnose problems

---

## Tips for Success

1. **Start small** - Begin with 2 Claude agents
2. **Use shared task lists** - For projects where agents need to coordinate
3. **Detach, don't kill** - Keep sessions running in background
4. **Check health regularly** - Run `./scripts/doctor.sh` if something seems off
5. **Learn tmux basics** - Makes multi-agent work much easier

---

## Credits

Based on [agent-flywheel](https://agent-flywheel.com) by Jeffrey Emanuel with cross-platform enhancements and visual session management.
