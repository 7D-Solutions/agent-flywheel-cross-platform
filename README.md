# Agent Flywheel

> Run multiple AI agents working together on your projects

![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-blue)

---

## Quick Start

### Mac / Linux

```bash
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel-cross-platform
./install.sh
./start
```

### Windows

```cmd
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel-cross-platform
start.bat
```

The Windows launcher auto-installs WSL if needed.

---

## Visual Interface

Run `./start` to launch the session manager:

```
╭────────────────────────────────────────────╮
│     Agent Flywheel - Session Manager      │
╰────────────────────────────────────────────╯

  🟢 my-app        Running    3 Claude, 1 Codex
  🔵 website       Attached   4 Claude
  💀 old-project   Killed     Jan 30
```

**Controls:**
- `Ctrl+N` - Create new session
- `Enter` - Actions menu
- `Tab` - Multi-select
- `Esc` - Quit

**Actions:**
- **Attach** - Connect to running session
- **Kill** - Stop session (saves state)
- **Resurrect** - Restore killed session
- **Delete** - Remove permanently

---

## Creating Sessions

Press `Ctrl+N` for 4-step guided setup:

1. **Project Folder** - Select with file picker
2. **Session Name** - Auto-uses folder name or custom
3. **Agent Count** - Claude agents (default: 2), Codex agents (default: 0)
4. **Shared Tasks** - Enable for agent collaboration (optional)

---

## Inside Sessions

Sessions use tmux with multiple panes:

- `Ctrl+b` then `arrow` - Switch panes
- `Ctrl+b` then `d` - Detach (keeps running)
- `Ctrl+b` then `z` - Zoom pane
- `Ctrl+b` then `[` - Scroll mode (q to exit)

---

## Authentication

Two options during install:

**ChatGPT OAuth** (Recommended)
- Uses ChatGPT Plus/Pro subscription
- ~$200/month vs $600/month API costs

**API Key**
- Direct API billing
- Better for light usage

---

## Troubleshooting

```bash
./scripts/doctor.sh
```

This checks:
- Dependencies (tmux, jq, docker, python3)
- Docker status
- MCP Agent Mail server
- Python environment
- Active sessions

**Common Fixes:**

```bash
# Permission errors
chmod +x start install.sh scripts/*.sh

# Missing dependencies
./install.sh

# Visual interface not showing
brew install fzf  # Mac
sudo apt install fzf  # Linux

# MCP Agent Mail not running
cd ~/mcp_agent_mail && docker-compose up -d
```

---

## Agent Communication

Agents can send messages via MCP Agent Mail:

```bash
./scripts/agent-mail-helper.sh whoami
./scripts/agent-mail-helper.sh list
./scripts/agent-mail-helper.sh inbox
./scripts/agent-mail-helper.sh send 'AgentName' 'Subject' 'Message'
```

Requires MCP Agent Mail server running on port 8765.

---

## File Structure

```
agent-flywheel-cross-platform/
├── start                           # Quick launcher
├── install.sh                      # One-command installer
├── scripts/
│   ├── visual-session-manager.sh   # Visual interface
│   ├── start-multi-agent-session.sh # Session creator
│   ├── doctor.sh                   # Health check
│   └── agent-mail-helper.sh        # Agent messaging
└── .session-state/                 # Saved sessions
```

---

## Platform Support

- **Mac** - Terminal or iTerm2
- **Windows** - Auto-installs WSL, works with Command Prompt/PowerShell
- **Linux** - Any distro with bash

---

## Advanced Setup

<details>
<summary>Manual configuration</summary>

### Prerequisites

**macOS:**
```bash
brew install tmux jq
```

**Linux/WSL:**
```bash
sudo apt install -y tmux jq curl python3 python3-pip git docker.io
```

### ChatGPT OAuth Setup

```bash
./scripts/setup-codex-oauth.sh
```

### API Key Setup

```bash
echo "sk-proj-YOUR-KEY" > /tmp/openai-key.txt
./scripts/setup-openai-key.sh
```

### MCP Agent Mail

Installed automatically by `./install.sh`. Manual setup:

```bash
git clone https://github.com/mcp-agent-mail/server ~/mcp_agent_mail
cd ~/mcp_agent_mail
docker-compose up -d
```

</details>

---

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Detailed setup walkthrough
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[VISUAL-INTERFACE-GUIDE.md](VISUAL-INTERFACE-GUIDE.md)** - Complete testing guide
- **[AGENT_MAIL.md](AGENT_MAIL.md)** - Agent communication system

---

## License

MIT License - see [LICENSE](LICENSE) file

Based on [agent-flywheel](https://agent-flywheel.com) by Jeffrey Emanuel

---

## Support

- **Health Check:** `./scripts/doctor.sh`
- **Issues:** https://github.com/7D-Solutions/agent-flywheel-cross-platform/issues
- **Error Messages:** Read them - they tell you what to do
