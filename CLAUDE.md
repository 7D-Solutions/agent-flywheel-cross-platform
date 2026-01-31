# Project Instructions for Claude

This is the **agent-flywheel-cross-platform** project - a multi-agent coordination system that enables multiple AI agents to work together on shared tasks.

## Quick Overview

This project provides:
- **Multi-agent tmux sessions** - Multiple agents working in parallel
- **Agent Mail** - Inter-agent communication via MCP Agent Mail
- **File Reservations** - Advisory locking to prevent edit conflicts
- **Cross-platform support** - Works on macOS, Linux, and WSL

## Key Commands

### Starting a Session
```bash
./start  # Launch multi-agent session
```

### Communication
📧 **Multi-Agent Communication**: See [AGENT_MAIL.md](./AGENT_MAIL.md) for complete agent mail commands.

Quick examples:
- Check inbox: `./scripts/agent-mail-helper.sh inbox`
- Send message: `./scripts/agent-mail-helper.sh send <agent> "Subject" "Body"`
- List agents: `./scripts/agent-mail-helper.sh list-agents`

### File Reservations
Before editing shared files, check and reserve them:
```bash
./scripts/reserve-files.sh check "path/to/file"
./scripts/reserve-files.sh reserve "path/to/file"
# ... make edits ...
./scripts/reserve-files.sh release
```

### Health Check
```bash
./scripts/doctor.sh  # Verify system is healthy
```

## Working Guidelines

1. **Always check file reservations** before editing files that other agents might touch
2. **Use agent mail** to coordinate with other agents on complex tasks
3. **Check your inbox regularly** - other agents may be waiting for your input
4. **Be a good citizen** - Release file reservations when done, respond to messages

## Project Structure

- `scripts/` - Core automation scripts
- `panes/` - Tmux pane initialization scripts
- `docs/` - Documentation
- `pids/` - Runtime process IDs and agent names
- `.ntm/` - Session metadata

## Important Notes

- This is a **coordination framework**, not application code
- Multiple agents may be working simultaneously
- Scripts are designed to be fault-tolerant and cross-platform
- See main [README.md](./README.md) for installation and setup

## Need Help?

- Installation issues: Run `./scripts/doctor.sh`
- Agent mail not working: Check MCP server is running (`docker ps`)
- General questions: See [README.md](./README.md) and [docs/](./docs/)
