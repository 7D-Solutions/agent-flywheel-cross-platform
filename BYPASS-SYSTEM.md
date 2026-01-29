# Hook Bypass System

## Overview

The bypass system allows you to temporarily disable Claude Code hooks for testing or debugging purposes. When enabled, a visible warning appears in your tmux pane borders showing which project has bypass active.

## How It Works

### Bypass Flag

Each project can have a `.claude-hooks-bypass` file in its root directory. When this file exists:
- Hooks will detect it and exit early without running their security checks
- A warning banner appears in all panes for that project
- The warning shows the project name where bypass is enabled

### Visual Warning

When bypass is enabled, you'll see a persistent warning in your tmux pane borders:

```
⚠️bypass: your-project-name
```

This warning is automatically displayed in all panes of the project and updates dynamically as you navigate directories.

## Using the Bypass Utility

```bash
# Enable bypass (create .claude-hooks-bypass in current project)
./scripts/hook-bypass.sh on

# Disable bypass (remove .claude-hooks-bypass)
./scripts/hook-bypass.sh off

# Check status
./scripts/hook-bypass.sh status

# Silent check (for use in hooks)
./scripts/hook-bypass.sh check
```

## Using Bypass in Your Hooks

Add this check at the start of any hook script:

```bash
# Check if bypass is enabled
if ./scripts/hook-bypass.sh check; then
    echo "⚠️  Hooks bypassed for testing"
    exit 0
fi
```

## Technical Details

### Bypass Flag Location
- File: `<project-root>/.claude-hooks-bypass`
- Type: Empty file (existence is what matters)
- Scope: Per-project only

### Warning Display
- Shown in: Tmux pane border format
- Updates: Dynamically based on current pane path
- Scope: Session-specific (each session manages its own)
- Portability: Works from any directory, no configuration needed

### How Tmux Displays the Warning

The session scripts configure tmux to check for the bypass file:

```bash
pane-border-format '#([ -f "#{pane_current_path}/.claude-hooks-bypass" ] && echo "⚠️ Bypass: $(basename "#{pane_current_path}")")'
```

This means:
- Each pane checks its own current path
- Warning appears automatically when `.claude-hooks-bypass` exists
- No background processes or monitoring needed
- Works across all platforms and directory structures

## Security Note

The bypass system is designed for **testing and debugging only**. When bypassed:
- Hook security checks are disabled
- Tool execution is not validated
- File operations are not monitored

Always disable bypass when not actively testing:

```bash
./scripts/hook-bypass.sh off
```

## Portability

The bypass system is fully portable:
- No hardcoded paths or directory assumptions
- Works from any location where you clone the project
- Per-project isolation (one project's bypass doesn't affect others)
- No setup or configuration required
