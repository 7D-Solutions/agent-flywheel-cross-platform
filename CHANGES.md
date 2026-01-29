# Cross-Platform Changes

This document summarizes the changes made to create the cross-platform version of agent-flywheel.

## Overview

Created a separate cross-platform project at `~/Projects/agent-flywheel-cross-platform/` that works on both macOS and Linux (including WSL). The original project at `~/Projects/agent-flywheel/` remains completely untouched.

## Files Modified

### 1. scripts/start-multi-agent-session.sh

**Line 272: Fixed sed compatibility**
```bash
# BEFORE (macOS only):
SESSION_SAFE=$(echo "$SESSION_NAME" | sed -E 's/[^A-Za-z0-9_-]+/_/g')

# AFTER (cross-platform):
SESSION_SAFE=$(echo "$SESSION_NAME" | tr -cs 'A-Za-z0-9_-' '_' | sed 's/^_*//;s/_*$//')
```
**Why**: `sed -E` is BSD sed (macOS), but Linux uses GNU sed which needs `sed -r`. The `tr` solution works everywhere.

**Lines 414-416: Fixed hardcoded path**
```bash
# BEFORE (hardcoded):
SOURCE_CONFIG="/Users/james/Projects/agent-flywheel/.tmux.conf.agent-flywheel"

# AFTER (dynamic):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE_CONFIG="$AGENT_FLYWHEEL_ROOT/.tmux.conf.agent-flywheel"
```
**Why**: Hardcoded path fails on WSL. Script-relative paths work anywhere.

### 2. scripts/setup-openai-key.sh

**Added at top (after shebang):**
```bash
# Detect Python bin directory (macOS vs Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PYTHON_BIN="$HOME/Library/Python/3.9/bin"
else
    PYTHON_BIN="$HOME/.local/bin"
fi

# Detect shell RC file
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bash_profile"
fi
```

**Then replaced all instances of:**
- `$HOME/Library/Python/3.9/bin` → `$PYTHON_BIN`
- `$HOME/.zshrc` → `$SHELL_RC`

**Why**: macOS uses `~/Library/Python/3.9/bin`, Linux uses `~/.local/bin`. Different shells use different RC files.

### 3. scripts/add-aider-to-path.sh

**Same platform detection added:**
```bash
# Detect Python bin directory (macOS vs Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PYTHON_BIN="$HOME/Library/Python/3.9/bin"
else
    PYTHON_BIN="$HOME/.local/bin"
fi

# Detect shell RC file
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bash_profile"
fi
```

**Then replaced all instances of:**
- `$HOME/Library/Python/3.9/bin` → `$PYTHON_BIN`
- `~/.zshrc` → `$SHELL_RC`

**Why**: Same reason as setup-openai-key.sh - cross-platform Python paths and shell detection.

### 4. scripts/start-bypass-monitor.sh (Additional Fix)

**Added dynamic path detection:**
```bash
# BEFORE (hardcoded):
cd /Users/james/Projects/agent-flywheel

# AFTER (dynamic):
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$AGENT_FLYWHEEL_ROOT"
```

**Why**: Same as main script - hardcoded path fails on WSL and different installations.

### 5. scripts/test-hooks-from-project.sh (Additional Fix)

**Replaced hardcoded project list with dynamic detection:**
```bash
# BEFORE: Hardcoded list of specific projects
KNOWN_PROJECTS=(
    "/Users/james/Projects/Fireproof"
    "/Users/james/Projects/agent-flywheel"
    # ... etc
)

# AFTER: Pattern-based detection
if [[ "$PROJECT_ROOT" =~ ^(/Users|/home)/[^/]+/Projects/ ]]; then
    echo "✅ In Projects directory: $PROJECT_ROOT"
elif [[ "$PROJECT_ROOT" =~ ^/mnt/[^/]+/Users/[^/]+/Projects/ ]]; then
    echo "✅ In Projects directory (WSL): $PROJECT_ROOT"
```

**Also updated**: All test examples now use dynamic path variables instead of hardcoded paths.

**Why**: Test utility should work in any Projects directory, not just specific hardcoded ones.

### 6. scripts/lib/project-config.sh (Additional Fix)

**Replaced hardcoded fallback with dynamic detection:**
```bash
# BEFORE: Hardcoded fallback
SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/Projects/agent-flywheel/scripts}"

# AFTER: Dynamic detection with smart fallback
if [ -z "$SCRIPTS_DIR" ]; then
    if [ -n "${BASH_SOURCE[0]}" ]; then
        DETECTED_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        SCRIPTS_DIR="$DETECTED_SCRIPT_DIR"
    else
        # Try agent-flywheel-cross-platform first, then agent-flywheel
        if [ -d "$HOME/Projects/agent-flywheel-cross-platform/scripts" ]; then
            SCRIPTS_DIR="$HOME/Projects/agent-flywheel-cross-platform/scripts"
        elif [ -d "$HOME/Projects/agent-flywheel/scripts" ]; then
            SCRIPTS_DIR="$HOME/Projects/agent-flywheel/scripts"
        fi
    fi
fi
```

**Why**: Config file should detect script location dynamically, not assume hardcoded path.

## Files Added

### README.md
Comprehensive guide for using the cross-platform version. Covers:
- Prerequisites for macOS and Linux
- Quick start guide
- Platform-specific notes
- Troubleshooting
- File structure

### CHANGES.md (this file)
Documents all changes made for cross-platform compatibility.

## Files Updated

### README-SETUP-WSL.md
Updated to:
- Reference the cross-platform version
- Remove references to `.fixed.v4.8` scripts
- Add troubleshooting section for WSL-specific issues
- Explain what was fixed

## Files Copied (Unchanged)

All other files were copied as-is:
- All other scripts in `scripts/`
- All pane scripts in `panes/`
- `.tmux.conf.agent-flywheel`
- `AGENT_MAIL.md`

## Testing

### Syntax Validation
All modified scripts pass bash syntax validation:
```bash
bash -n scripts/start-multi-agent-session.sh  # ✓
bash -n scripts/setup-openai-key.sh           # ✓
bash -n scripts/add-aider-to-path.sh          # ✓
```

### macOS Testing
```bash
cd ~/Projects/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
# Should work identically to original version
```

### WSL Testing
```bash
# Prerequisites
sudo apt install -y tmux jq curl python3 git

# Run
cd ~/Projects/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
# Should work without path or sed errors
```

## Impact on Original Project

**ZERO IMPACT** - The original project at `~/Projects/agent-flywheel/` is completely untouched and continues to work exactly as before.

## Nice-to-Have Items (Not Fixed)

These issues exist but are not blocking:
1. `lsof` availability - has fallback in auto-register
2. `fswatch` availability - has polling fallback in monitor script
3. `flock` availability - discover script checks for it
4. Terminal colors - already work on Windows Terminal

Decision: Don't fix these now. They have fallbacks and aren't blocking WSL functionality.

## Maintenance

To keep the cross-platform version in sync with the original:
1. Copy new scripts from original to cross-platform
2. Re-apply the three fixes listed above
3. Test on both platforms

Or maintain them separately if they diverge in purpose.
