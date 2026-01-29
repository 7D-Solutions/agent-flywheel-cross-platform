# Agent Mail System

This project has multi-agent communication enabled via MCP Agent Mail.

## Commands

All commands use the agent-mail-helper.sh script in ./scripts/

### Check your agent identity
```bash
./scripts/agent-mail-helper.sh whoami
```

### List all agents
```bash
./scripts/agent-mail-helper.sh list
```

### Send a message
```bash
./scripts/agent-mail-helper.sh send 'RecipientName' 'Subject' 'Message body'
```

### Check inbox
```bash
./scripts/agent-mail-helper.sh inbox
```

### Notifications monitor (tmux banner)
```bash
./scripts/mail-monitor-ctl.sh start
```

## Server check

Agent mail requires the MCP Agent Mail server to be running (port 8765).

Quick check:
```bash
docker ps | grep 8765
```

If it's not running:
```bash
cd "$MCP_AGENT_MAIL_DIR" && docker-compose up -d
```

## Troubleshooting

### Not receiving notifications (but inbox has messages)
1) Check monitor status:
```bash
./scripts/mail-monitor-ctl.sh status
```
2) Restart monitor (binds to current pane):
```bash
./scripts/mail-monitor-ctl.sh restart
```
3) Verify this pane has an agent name:
```bash
cat ./pids/$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" | tr ':.' '-').agent-name
```

### Not receiving messages at all
```bash
./scripts/agent-mail-helper.sh inbox
```

## Hook Bypass Utility

For testing purposes, you can temporarily bypass Claude Code hooks.

### Enable bypass
```bash
./scripts/hook-bypass.sh on
```

### Disable bypass
```bash
./scripts/hook-bypass.sh off
```

### Check status
```bash
./scripts/hook-bypass.sh status
```

When bypass is enabled, a warning indicator will appear in the tmux pane borders and status bar.

## Examples

```bash
# See who you are
./scripts/agent-mail-helper.sh whoami

# See all agents in this project
./scripts/agent-mail-helper.sh list

# Send a message
./scripts/agent-mail-helper.sh send 'CloudyBadger' 'Status' 'Feature X complete'

# Check recent messages
./scripts/agent-mail-helper.sh inbox 5
```

## Session Persistence with tmux-resurrect

This project uses tmux-resurrect to save and restore tmux sessions, preventing data loss from system issues or script bugs.

### Save current session
```bash
# Manual save (inside tmux)
# Press: <prefix> + Ctrl-s
# Where <prefix> is typically Ctrl-b
```

The session will be saved to `~/.local/share/tmux/resurrect/`

### Restore last saved session
```bash
# Manual restore (inside tmux)
# Press: <prefix> + Ctrl-r
```

### Automatic saves

tmux-resurrect is configured to automatically capture:
- Pane contents
- Shell history
- Working directories
- Running programs
- Window and pane layout

### Save file location

Session snapshots are stored in: `~/.local/share/tmux/resurrect/tmux_resurrect_YYYYMMDDTHHMMSS.txt`

### Best practices

1. **Save frequently**: Press `<prefix> + Ctrl-s` before risky operations
2. **After setup**: Save immediately after creating a multi-agent session
3. **Before cleanup**: Save before running scripts that modify sessions
4. **Regular backups**: Consider copying resurrect files to a backup location

### Recovery after session loss

If your tmux session is killed or crashes:

1. Start a new tmux session
2. Press `<prefix> + Ctrl-r` to restore
3. All panes, windows, and working directories will be restored
4. You may need to re-register agents with the mail system

### Limitations

- Running processes may need to be restarted manually
- Claude Code sessions will need to be reinitiated
- Agent mail registration may need to be redone
