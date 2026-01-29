#!/bin/bash
# Interactive Multi-Agent Tmux Session Creator
# Creates a tmux session with Claude and Codex agents with bypass permissions
# FIXED VERSION - Addresses critical path and pane numbering bugs

set -e

# Detect agent-flywheel root dynamically (cross-platform)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration Constants
readonly MAX_AGENTS_WARNING=10
readonly HISTORY_LIMIT=50000
readonly AGENT_INIT_WAIT=10
readonly MONITOR_START_WAIT=1
readonly LOG_DIR="$HOME/.agent-flywheel"
readonly LOG_FILE="$LOG_DIR/session-creation.log"
readonly FLYWHEEL_DIR="$AGENT_FLYWHEEL_ROOT"  # For backward compatibility, use dynamic root
readonly REQUIRED_MAIL_SCRIPTS=("agent-mail-helper.sh" "mail-monitor-ctl.sh" "monitor-agent-mail-to-terminal.sh" "hook-bypass.sh")
readonly REQUIRED_MAIL_DIRS=("lib")

# Flags
CLEANUP_DETACHED=true
for arg in "$@"; do
    case "$arg" in
        --no-cleanup)
            CLEANUP_DETACHED=false
            ;;
    esac
done

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging function
log() {
    mkdir -p "$LOG_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Dependency check function
check_dependencies() {
    local missing=()
    command -v tmux >/dev/null || missing+=("tmux")
    command -v jq >/dev/null || missing+=("jq")
    command -v docker >/dev/null || missing+=("docker")
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing[*]}${NC}"
        log "ERROR: Missing dependencies: ${missing[*]}"
        exit 1
    fi
    log "Dependency check passed"
}

ensure_mail_scripts_available() {
    local target_dir="$PROJECT_PATH/scripts"
    mkdir -p "$target_dir"

    # Sync helper scripts
    for script_name in "${REQUIRED_MAIL_SCRIPTS[@]}"; do
        local source="$FLYWHEEL_DIR/scripts/$script_name"
        local destination="$target_dir/$script_name"

        if [ "$source" = "$destination" ]; then
            log "Skipping helper script copy (source == destination): $destination"
            continue
        fi

        if [ ! -f "$source" ]; then
            echo -e "${YELLOW}Warning: Required helper $script_name not found at $source${NC}"
            log "WARNING: Missing helper script: $source"
            continue
        fi

        if [ -L "$destination" ] || [ -f "$destination" ]; then
            if cmp -s "$source" "$destination"; then
                log "Helper script already up to date: $destination"
                continue
            fi
        fi

        cp "$source" "$destination"
        chmod +x "$destination"
        echo -e "${GREEN}✓ Installed helper script: ${destination/#$HOME/\~}${NC}"
        log "Installed helper script: $destination"
    done

    # Sync supporting directories (e.g., lib/config files)
    for dir_name in "${REQUIRED_MAIL_DIRS[@]}"; do
        local source_dir="$FLYWHEEL_DIR/scripts/$dir_name"
        local destination_dir="$target_dir/$dir_name"

        if [ "$source_dir" = "$destination_dir" ]; then
            log "Skipping helper directory sync (source == destination): $destination_dir"
            continue
        fi

        if [ ! -d "$source_dir" ]; then
            echo -e "${YELLOW}Warning: Required helper directory $dir_name not found at $source_dir${NC}"
            log "WARNING: Missing helper directory: $source_dir"
            continue
        fi

        mkdir -p "$destination_dir"
        cp -r "$source_dir/." "$destination_dir/"
        echo -e "${GREEN}✓ Synced helper directory: ${destination_dir/#$HOME/\~}${NC}"
        log "Synced helper directory: $destination_dir"
    done
}

# Create AGENT_MAIL.md documentation
create_agent_mail_docs() {
    local agent_mail_md="$PROJECT_PATH/AGENT_MAIL.md"

    cat > "$agent_mail_md" << 'EOF'
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
EOF

    echo -e "${GREEN}✓ Created AGENT_MAIL.md${NC}"
    log "Created AGENT_MAIL.md"
}

# Add reference to AGENT_MAIL.md in CLAUDE.md
update_claude_md_reference() {
    local claude_md="$PROJECT_PATH/CLAUDE.md"
    local ref_text='

---

📧 **Multi-Agent Communication**: See [AGENT_MAIL.md](./AGENT_MAIL.md) for commands.
'

    if [ -f "$claude_md" ]; then
        if grep -qF '[AGENT_MAIL.md]' "$claude_md" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  CLAUDE.md already references AGENT_MAIL.md${NC}"
        else
            # Ensure file ends with newline
            [ -s "$claude_md" ] && [ "$(tail -c1 "$claude_md" 2>/dev/null | wc -l)" -eq 0 ] && echo "" >> "$claude_md"
            echo "$ref_text" >> "$claude_md"
            echo -e "${GREEN}✓ Added reference to CLAUDE.md${NC}"
        fi
    else
        cat > "$claude_md" << 'EOF'
# Project Instructions

📧 **Multi-Agent Communication**: See [AGENT_MAIL.md](./AGENT_MAIL.md) for commands.
EOF
        echo -e "${GREEN}✓ Created CLAUDE.md${NC}"
    fi
}

log "=== Session creation started ==="
check_dependencies

# Check for detached sessions and offer to clean them up
check_detached_sessions() {
    local detached_sessions=()
    local detached_paths=()

    while IFS= read -r line; do
        local session_name=$(echo "$line" | cut -d: -f1)
        local attached=$(echo "$line" | cut -d: -f2)
        if [ "$attached" = "0" ]; then
            detached_sessions+=("$session_name")
            local session_path
            session_path=$(tmux list-panes -t "$session_name" -F "#{pane_current_path}" 2>/dev/null | head -n 1)
            session_path=${session_path:-"(unknown)"}
            detached_paths+=("$session_path")
        fi
    done < <(tmux list-sessions -F "#{session_name}:#{session_attached}" 2>/dev/null || true)

    if [ ${#detached_sessions[@]} -gt 0 ]; then
        echo -e "${YELLOW}Found ${#detached_sessions[@]} detached session(s):${NC}"
        for i in "${!detached_sessions[@]}"; do
            local session="${detached_sessions[$i]}"
            local pane_count=$(tmux list-panes -t "$session" 2>/dev/null | wc -l | tr -d ' ')
            local session_path="${detached_paths[$i]}"
            echo -e "  $((i+1)). $session ($pane_count panes) [$session_path]"
        done
        echo ""

        # All detached sessions are candidates (no project filtering)
        local candidate_sessions=("${detached_sessions[@]}")
        local candidate_paths=("${detached_paths[@]}")

        # Step 1: Ask what action to take
        while true; do
            echo -en "${YELLOW}What would you like to do? [K]ill / [A]ttach / [S]kip all: ${NC}"
            read action || action=""
            action="$(echo "$action" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

            if [ -z "$action" ] || [ "$action" = "s" ] || [ "$action" = "skip" ]; then
                echo -e "${YELLOW}Keeping detached sessions${NC}"
                echo ""
                return
            fi

            if [ "$action" = "k" ] || [ "$action" = "kill" ]; then
                # Step 2: Ask which sessions to kill
                while true; do
                    echo -en "${YELLOW}Which sessions to kill? (e.g., 1,3,5 or 'all'): ${NC}"
                    read selection || selection=""
                    selection="$(echo "$selection" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

                    if [ -z "$selection" ]; then
                        echo -e "${YELLOW}No selection made${NC}"
                        break
                    fi

                    if [ "$selection" = "all" ]; then
                        if [ ${#candidate_sessions[@]} -gt 5 ]; then
                            echo -en "${YELLOW}Kill ${#candidate_sessions[@]} sessions? [y/N]: ${NC}"
                            read confirm || confirm=""
                            confirm=${confirm:-N}
                            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                                break
                            fi
                        fi
                        for session in "${candidate_sessions[@]}"; do
                            echo -e "${BLUE}Killing session: $session${NC}"
                            tmux kill-session -t "$session" 2>&1 || true
                            log "Killed detached session: $session"
                        done
                        echo -e "${GREEN}✓ Detached sessions cleaned up${NC}"
                        echo ""
                        return
                    fi

                    # Parse comma-separated numbers
                    selection="${selection//,/ }"
                    local indexes=()
                    for token in $selection; do
                        if [[ "$token" =~ ^[0-9]+$ ]]; then
                            indexes+=("$token")
                        fi
                    done

                    if [ ${#indexes[@]} -eq 0 ]; then
                        echo -e "${YELLOW}Invalid selection. Please enter numbers (e.g., 1,3,5) or 'all'${NC}"
                        continue
                    fi

                    if [ ${#indexes[@]} -gt 5 ]; then
                        echo -en "${YELLOW}Kill ${#indexes[@]} sessions? [y/N]: ${NC}"
                        read confirm || confirm=""
                        confirm=${confirm:-N}
                        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                            break
                        fi
                    fi

                    for sel in "${indexes[@]}"; do
                        local idx=$((sel - 1))
                        if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#candidate_sessions[@]} ]; then
                            echo -e "${YELLOW}Invalid session number: $sel${NC}"
                            continue
                        fi
                        local session="${candidate_sessions[$idx]}"
                        echo -e "${BLUE}Killing session: $session${NC}"
                        tmux kill-session -t "$session" 2>&1 || true
                        log "Killed detached session: $session"
                    done
                    echo -e "${GREEN}✓ Detached sessions cleaned up${NC}"
                    echo ""
                    return
                done
                # If we broke from inner loop, go back to action selection
                continue
            fi

            if [ "$action" = "a" ] || [ "$action" = "attach" ]; then
                # Step 2: Ask which session to attach
                echo -en "${YELLOW}Which session to attach? (e.g., 2): ${NC}"
                read selection || selection=""
                selection="$(echo "$selection" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

                if [ -z "$selection" ]; then
                    echo -e "${YELLOW}No selection made${NC}"
                    continue
                fi

                if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
                    echo -e "${YELLOW}Invalid selection. Please enter a number${NC}"
                    continue
                fi

                local idx=$((selection - 1))
                if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#candidate_sessions[@]} ]; then
                    echo -e "${YELLOW}Invalid session number: $selection${NC}"
                    continue
                fi

                local session="${candidate_sessions[$idx]}"
                echo -e "${GREEN}Attaching to session: $session${NC}"
                if [ -n "$TMUX" ]; then
                    tmux switch-client -t "$session"
                else
                    exec tmux attach -t "$session"
                fi
                return
            fi

            echo -e "${YELLOW}Invalid choice. Please enter K, A, or S${NC}"
        done
    fi
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Multi-Agent Tmux Session Creator (FIXED)                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if MCP Agent Mail server is running in Docker
echo -e "${BLUE}Checking MCP Agent Mail server...${NC}"
if docker ps | grep -q "8765.*8765"; then
    echo -e "${GREEN}✓ MCP server is running in Docker (port 8765)${NC}"
    log "MCP server detected on port 8765"
else
    echo -e "${YELLOW}⚠️  MCP server not detected on port 8765${NC}"
    echo -e "${YELLOW}   Agent mail features will not work${NC}"
    echo -e "${YELLOW}   Start it manually: cd \$MCP_AGENT_MAIL_DIR && docker-compose up -d${NC}"
    echo -e "${YELLOW}   (Default: ~/mcp_agent_mail)${NC}"
    log "WARNING: MCP server not detected"
fi
echo ""

# Prompt for session name (loop until resolved)
while true; do
    echo -en "${YELLOW}Session name [default: flywheel]:${NC} "
    read SESSION_NAME || SESSION_NAME=""
    SESSION_NAME=${SESSION_NAME:-flywheel}
    SESSION_SAFE=$(echo "$SESSION_NAME" | tr -cs 'A-Za-z0-9_-' '_' | tr '[:upper:]' '[:lower:]' | sed 's/^_*//;s/_*$//')
    if [ -z "$SESSION_SAFE" ]; then
        echo -e "${RED}Error: Session name cannot be empty after sanitization${NC}"
        log "ERROR: Invalid session name provided"
        continue
    fi
    if [ "$SESSION_SAFE" != "$SESSION_NAME" ]; then
        echo -e "${YELLOW}Note: tmux session name normalized to '$SESSION_SAFE' from '$SESSION_NAME'${NC}"
        log "Session name normalized from $SESSION_NAME to $SESSION_SAFE"
    fi
    log "Session name: $SESSION_NAME (tmux: $SESSION_SAFE)"

    # Check if we're currently in the target session
    CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")

    # Handle existing session as early as possible
    if tmux has-session -t "$SESSION_SAFE" 2>/dev/null; then
        if [ "$CURRENT_SESSION" = "$SESSION_SAFE" ]; then
            echo -e "${YELLOW}⚠️  You are currently in the '$SESSION_SAFE' session.${NC}"
            echo -e "${BLUE}Options:${NC}"
            echo -e "  ${GREEN}D${NC} - Detach and continue with this name"
            echo -e "  ${GREEN}N${NC} - Choose a new session name"
            echo -e "  ${GREEN}E${NC} - Exit"
            echo -en "${YELLOW}Choose [D/N/E]:${NC} "
            read session_choice || session_choice=""
            session_choice=${session_choice:-E}
            case "$session_choice" in
                [Dd])
                    tmux detach-client >/dev/null 2>&1 || true
                    log "Detached from session: $SESSION_SAFE"
                    break
                    ;;
                [Nn])
                    continue
                    ;;
                *)
                    log "User cancelled while in target session"
                    exit 1
                    ;;
            esac
        else
            echo -e "${YELLOW}Session '$SESSION_SAFE' already exists.${NC}"
            echo -e "${BLUE}Options:${NC}"
            echo -e "  ${GREEN}K${NC} - Kill existing session and recreate"
            echo -e "  ${GREEN}A${NC} - Attach to existing session"
            echo -e "  ${GREEN}N${NC} - Choose a new session name"
            echo -e "  ${GREEN}E${NC} - Exit"
            echo -en "${YELLOW}Choose [K/A/N/E]:${NC} "
            read session_choice || session_choice=""
            session_choice=${session_choice:-E}
            case "$session_choice" in
                [Kk])
                    echo -e "${YELLOW}🔄 Killing existing '$SESSION_SAFE' session...${NC}"
                    tmux kill-session -t "$SESSION_SAFE"
                    log "Killed existing session: $SESSION_NAME"
                    break
                    ;;
                [Aa])
                    echo -e "${GREEN}Attaching to existing session...${NC}"
                    log "User chose to attach to existing session: $SESSION_SAFE"
                    exec tmux attach -t "$SESSION_SAFE"
                    ;;
                [Nn])
                    continue
                    ;;
                *)
                    log "User cancelled - existing session kept"
                    exit 1
                    ;;
            esac
        fi
    else
        break
    fi
done

# Shared task list configuration (after session name is set)
TASK_LIST_ID=""
echo ""
echo -e "${BLUE}Shared Task List:${NC}"
echo -en "${YELLOW}Enable shared task list for all agents? [Y/n]:${NC} "
read ENABLE_SHARED_TASKS || ENABLE_SHARED_TASKS=""
ENABLE_SHARED_TASKS=${ENABLE_SHARED_TASKS:-Y}

if [[ "$ENABLE_SHARED_TASKS" =~ ^[Yy] ]]; then
    echo -en "${YELLOW}Task list ID [default: ${SESSION_SAFE}-tasks]:${NC} "
    read TASK_LIST_ID || TASK_LIST_ID=""
    TASK_LIST_ID=${TASK_LIST_ID:-"${SESSION_SAFE}-tasks"}
    echo -e "${GREEN}✓ Shared task list enabled: $TASK_LIST_ID${NC}"
    log "Shared task list enabled: $TASK_LIST_ID"
else
    echo -e "${BLUE}Each agent will have its own task list${NC}"
    log "Shared task list disabled"
fi
echo ""

# Prompt for project path (no directory scanning - fully portable)
echo ""
echo -e "${BLUE}Project Directory:${NC}"
echo -en "${YELLOW}Enter project path [press Enter for current directory]:${NC} "
read PROJECT_PATH || PROJECT_PATH=""

# Use current directory if not specified
if [ -z "$PROJECT_PATH" ]; then
    PROJECT_PATH="$(pwd)"
    echo -e "${GREEN}Using current directory: ${PROJECT_PATH/#$HOME/\~}${NC}"
    log "Using current directory: $PROJECT_PATH"
else
    # Expand ~ to home directory
    PROJECT_PATH="${PROJECT_PATH/#\~/$HOME}"

    # Create directory if it doesn't exist
    if [ ! -d "$PROJECT_PATH" ]; then
        echo -e "${YELLOW}Warning: Directory $PROJECT_PATH does not exist.${NC}"
        read -p "Create it? (y/n): " CREATE_DIR || CREATE_DIR="n"
        if [ "$CREATE_DIR" = "y" ] || [ "$CREATE_DIR" = "Y" ]; then
            mkdir -p "$PROJECT_PATH"
            echo -e "${GREEN}✓ Created directory${NC}"
            log "Created directory: $PROJECT_PATH"
        else
            echo "Exiting..."
            log "User cancelled - directory creation declined"
            exit 1
        fi
    fi
    echo -e "${GREEN}Using: ${PROJECT_PATH/#$HOME/\~}${NC}"
    log "Using project path: $PROJECT_PATH"
fi

if [ "$CLEANUP_DETACHED" = true ]; then
    check_detached_sessions
else
    echo -e "${YELLOW}Skipping detached session cleanup (--no-cleanup)${NC}"
    log "Skipped detached session cleanup (--no-cleanup)"
fi

# Source shared project configuration if available (after PROJECT_PATH is set)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/lib/project-config.sh" ]; then
    export PROJECT_ROOT="$PROJECT_PATH"
    source "$SCRIPT_DIR/lib/project-config.sh"
    log "Sourced project-config.sh"
fi

echo -e "${BLUE}Ensuring agent mail helpers are available in project...${NC}"
ensure_mail_scripts_available

echo -e "${BLUE}Creating agent mail documentation...${NC}"
create_agent_mail_docs
update_claude_md_reference

# Prompt for number of Claude agents
echo -en "${YELLOW}Number of Claude agents [default: 2]:${NC} "
read CLAUDE_COUNT || CLAUDE_COUNT=""
CLAUDE_COUNT=${CLAUDE_COUNT:-2}

# Prompt for number of Codex agents
echo -en "${YELLOW}Number of Codex agents [default: 0]:${NC} "
read CODEX_COUNT || CODEX_COUNT=""
CODEX_COUNT=${CODEX_COUNT:-0}

# Validate counts
if ! [[ "$CLAUDE_COUNT" =~ ^[0-9]+$ ]] || ! [[ "$CODEX_COUNT" =~ ^[0-9]+$ ]]; then
    echo "Error: Agent counts must be numbers"
    log "ERROR: Invalid agent counts - Claude: $CLAUDE_COUNT, Codex: $CODEX_COUNT"
    exit 1
fi

TOTAL_AGENTS=$((CLAUDE_COUNT + CODEX_COUNT))
log "Agent counts - Claude: $CLAUDE_COUNT, Codex: $CODEX_COUNT, Total: $TOTAL_AGENTS"

if [ "$TOTAL_AGENTS" -eq 0 ]; then
    echo "Error: Must have at least one agent"
    log "ERROR: No agents specified"
    exit 1
fi

if [ "$TOTAL_AGENTS" -gt "$MAX_AGENTS_WARNING" ]; then
    echo -e "${YELLOW}Warning: $TOTAL_AGENTS agents will create many panes. Consider using fewer.${NC}"
    read -p "Continue? (y/n): " CONTINUE || CONTINUE="n"
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        log "User cancelled - too many agents"
        exit 0
    fi
fi

# (Session existence handled earlier, right after name selection.)

# Create new session
# Ensure project has tmux config, copy from agent-flywheel if needed
TMUX_CONFIG="$PROJECT_PATH/.tmux.conf.agent-flywheel"
SOURCE_CONFIG="$AGENT_FLYWHEEL_ROOT/.tmux.conf.agent-flywheel"

if [ ! -f "$TMUX_CONFIG" ]; then
    echo -e "${YELLOW}Installing tmux config to project...${NC}"
    cp "$SOURCE_CONFIG" "$TMUX_CONFIG"
    log "Copied tmux config to project: $TMUX_CONFIG"
fi

echo -e "${GREEN}🚀 Creating tmux session '$SESSION_NAME'...${NC}"
tmux -f "$TMUX_CONFIG" new-session -d -s "$SESSION_SAFE" -c "$PROJECT_PATH"
log "Created session: $SESSION_NAME"

# Set iTerm tab title to project name
PROJECT_NAME=$(basename "$PROJECT_PATH")
printf "\033]0;%s\007" "$PROJECT_NAME"

# Apply tmux configuration (session-scoped where possible)
tmux set -t "$SESSION_SAFE" base-index 1
tmux set -t "$SESSION_SAFE" pane-base-index 1
tmux set -t "$SESSION_SAFE" pane-border-status top
tmux set -t "$SESSION_SAFE" pane-border-format '#[fg=cyan]#{@llm_name}#[fg=default] #[fg=green]#{@agent_name}#[align=right]#[fg=yellow]#([ -f "#{pane_current_path}/.claude-hooks-bypass" ] && echo "⚠️ Bypass: $(basename "#{pane_current_path}")" || echo "")'
tmux set -g mouse on
tmux set -g status-interval 5
tmux set -t "$SESSION_SAFE" history-limit "$HISTORY_LIMIT"
log "Applied tmux configuration"

# Auto-rearrange grid and cleanup when pane is closed/killed (SESSION-SPECIFIC)
tmux set-hook -t "$SESSION_SAFE" after-kill-pane "run-shell \"tmux select-layout -t #{session_name}:#{window_index} tiled 2>/dev/null; bash $AGENT_FLYWHEEL_ROOT/scripts/cleanup-after-pane-removal.sh #{session_name} 2>/dev/null || true\""

# Rename first window
tmux rename-window -t "$SESSION_SAFE:1" "agents"

# Split window into required panes
for ((i=2; i<=TOTAL_AGENTS; i++)); do
    if [ $i -eq 2 ]; then
        # First split - vertical
        tmux split-window -h -c "$PROJECT_PATH" -t "$SESSION_SAFE:1"
    elif [ $((i % 2)) -eq 1 ]; then
        # Odd panes (3,5,7...) - split the left side
        tmux split-window -v -c "$PROJECT_PATH" -t "$SESSION_SAFE:1.$(((i-1)/2))"
    else
        # Even panes (4,6,8...) - split the right side
        tmux split-window -v -c "$PROJECT_PATH" -t "$SESSION_SAFE:1.$((i/2))"
    fi
done
log "Created $TOTAL_AGENTS panes"

# CRITICAL FIX #2: Capture actual pane IDs after creation
echo -e "${GREEN}Capturing actual pane IDs...${NC}"
PANE_IDS=()
while IFS= read -r pane_id; do
    PANE_IDS+=("$pane_id")
done < <(tmux list-panes -t "$SESSION_SAFE:1" -F "#{pane_index}" | sort -n)
log "Captured pane IDs: ${PANE_IDS[*]}"

if [ ${#PANE_IDS[@]} -ne "$TOTAL_AGENTS" ]; then
    echo -e "${RED}ERROR: Expected $TOTAL_AGENTS panes but found ${#PANE_IDS[@]}${NC}"
    log "ERROR: Pane count mismatch - expected $TOTAL_AGENTS, got ${#PANE_IDS[@]}"
    exit 1
fi

# Cleanup stale pid/agent-name files for this session only
echo -e "${GREEN}Cleaning up stale pid files for session...${NC}"
ARCHIVE_PIDS_DIR="$PROJECT_PATH/archive/pids"
mkdir -p "$ARCHIVE_PIDS_DIR"
VALID_SAFE_PANES=()
for pane_num in "${PANE_IDS[@]}"; do
    VALID_SAFE_PANES+=("$(echo "$SESSION_SAFE:1.$pane_num" | tr ':.' '-')")
done
is_valid_safe_pane() {
    local candidate="$1"
    for valid in "${VALID_SAFE_PANES[@]}"; do
        [ "$candidate" = "$valid" ] && return 0
    done
    return 1
}
for file in "$PROJECT_PATH/pids/${SESSION_SAFE}-"*.agent-name "$PROJECT_PATH/pids/${SESSION_SAFE}-"*.mail-monitor.pid; do
    [ -f "$file" ] || continue
    base_name=$(basename "$file")
    safe_pane="${base_name%.agent-name}"
    safe_pane="${safe_pane%.mail-monitor.pid}"
    if ! is_valid_safe_pane "$safe_pane"; then
        mv "$file" "$ARCHIVE_PIDS_DIR/"
        log "Archived stale pid file: $base_name"
    fi
done

# Set up Claude agents using actual pane IDs
echo -e "${GREEN}Starting $CLAUDE_COUNT Claude agents...${NC}"
for ((i=0; i<CLAUDE_COUNT; i++)); do
    PANE_NUM=${PANE_IDS[$i]}
    PANE="$SESSION_SAFE:1.$PANE_NUM"
    # Set custom tmux variables for labels (1-indexed for display)
    tmux set -p -t "$PANE" @llm_name "Claude $((i+1))"
    # Export PROJECT_ROOT and MAIL_PROJECT_KEY to agent environment
    EXPORT_CMD="export PROJECT_ROOT='$PROJECT_PATH' MAIL_PROJECT_KEY='$PROJECT_PATH'"
    if [ -n "$TASK_LIST_ID" ]; then
        EXPORT_CMD="$EXPORT_CMD CLAUDE_CODE_TASK_LIST_ID='$TASK_LIST_ID'"
    fi
    tmux send-keys -t "$PANE" "$EXPORT_CMD && claude --dangerously-skip-permissions" C-m
    log "Started Claude agent $((i+1)) in pane $PANE_NUM"
done

# Set up Codex (Qodo) agents using actual pane IDs
echo -e "${GREEN}Starting $CODEX_COUNT Codex agents...${NC}"
for ((i=0; i<CODEX_COUNT; i++)); do
    PANE_INDEX=$((CLAUDE_COUNT + i))
    PANE_NUM=${PANE_IDS[$PANE_INDEX]}
    PANE="$SESSION_SAFE:1.$PANE_NUM"
    # Set custom tmux variables for labels (1-indexed for display)
    tmux set -p -t "$PANE" @llm_name "Codex $((i+1))"
    # Export PROJECT_ROOT and MAIL_PROJECT_KEY to agent environment
    tmux send-keys -t "$PANE" "export PROJECT_ROOT='$PROJECT_PATH' MAIL_PROJECT_KEY='$PROJECT_PATH' && cd \"$PROJECT_PATH\" && codex --dangerously-bypass-approvals-and-sandbox" C-m
    log "Started Codex agent $((i+1)) in pane $PANE_NUM"
done

# Auto-register all agents with mail system
echo -e "${GREEN}Registering agents with mail system...${NC}"
log "Waiting ${AGENT_INIT_WAIT}s for agents to initialize"
sleep "$AGENT_INIT_WAIT"

# Register only the panes in this session (not --all, which would affect other sessions)
for ((i=0; i<TOTAL_AGENTS; i++)); do
    PANE_NUM=${PANE_IDS[$i]}
    PANE_ID="$SESSION_SAFE:1.$PANE_NUM"

    if ! PROJECT_ROOT="$PROJECT_PATH" bash "$FLYWHEEL_DIR/panes/discover.sh" --pane "$PANE_ID" --quiet; then
        echo -e "${YELLOW}Warning: Could not register pane $PANE_ID${NC}"
        log "WARNING: Agent registration failed for $PANE_ID"
    fi
done
log "Successfully registered agents"

# Explicitly set tmux @agent_name variables from registered agent names
for ((i=0; i<TOTAL_AGENTS; i++)); do
    PANE_NUM=${PANE_IDS[$i]}
    PANE_ID="$SESSION_SAFE:1.$PANE_NUM"
    SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')
    AGENT_NAME_FILE="$PROJECT_PATH/pids/${SAFE_PANE}.agent-name"

    if [ -f "$AGENT_NAME_FILE" ]; then
        AGENT_NAME=$(cat "$AGENT_NAME_FILE")
        tmux set-option -p -t "$PANE_ID" @agent_name "$AGENT_NAME" 2>/dev/null || true
        log "Set @agent_name=$AGENT_NAME for pane $PANE_ID"
    fi
done

# Start mail monitors for agents (verify start)
echo -e "${GREEN}Starting mail monitors for agents...${NC}"
for ((i=0; i<TOTAL_AGENTS; i++)); do
    PANE_NUM=${PANE_IDS[$i]}
    PANE_ID="$SESSION_SAFE:1.$PANE_NUM"
    SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')

    # Use PROJECT_PATH for agent name file (project-specific identities)
    AGENT_NAME_FILE="$PROJECT_PATH/pids/${SAFE_PANE}.agent-name"

    if [ -f "$AGENT_NAME_FILE" ]; then
        AGENT_NAME=$(cat "$AGENT_NAME_FILE")
        log "Starting mail monitor for $AGENT_NAME (pane $PANE_NUM)"

        # Run monitor from PROJECT_PATH with PROJECT_ROOT set
        if (cd "$PROJECT_PATH" && \
            PROJECT_ROOT="$PROJECT_PATH" \
            MAIL_PROJECT_KEY="$PROJECT_PATH" \
            AGENT_NAME="$AGENT_NAME" \
            "$PROJECT_PATH/scripts/mail-monitor-ctl.sh" start 2>/dev/null); then
            if (cd "$PROJECT_PATH" && \
                PROJECT_ROOT="$PROJECT_PATH" \
                MAIL_PROJECT_KEY="$PROJECT_PATH" \
                AGENT_NAME="$AGENT_NAME" \
                "$PROJECT_PATH/scripts/mail-monitor-ctl.sh" status >/dev/null 2>&1); then
                log "Mail monitor started for $AGENT_NAME"
            else
                echo -e "${YELLOW}Warning: Monitor status check failed for $AGENT_NAME${NC}"
                log "WARNING: Mail monitor status check failed for $AGENT_NAME"
            fi
        else
            echo -e "${YELLOW}Warning: Failed to start monitor for $AGENT_NAME${NC}"
            log "WARNING: Mail monitor failed for $AGENT_NAME"
        fi
    else
        echo -e "${YELLOW}Warning: No agent name file for pane $PANE_NUM${NC}"
        log "WARNING: Missing agent name file: $AGENT_NAME_FILE"
    fi
done

log "Waiting ${MONITOR_START_WAIT}s for monitors to start"
sleep "$MONITOR_START_WAIT"

# Balance pane layout
tmux select-layout -t "$SESSION_SAFE:1" tiled
log "Applied tiled layout"

# Select first pane
tmux select-pane -t "$SESSION_SAFE:1.${PANE_IDS[0]}"

echo ""
echo -e "${GREEN}✅ Tmux session created successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Session Info:${NC}"
echo "   Session: $SESSION_NAME"
echo "   Total agents: $TOTAL_AGENTS ($CLAUDE_COUNT Claude + $CODEX_COUNT Codex)"
echo "   Working directory: $PROJECT_PATH"
echo "   Log file: $LOG_FILE"
echo ""
echo -e "${BLUE}🎮 Navigation:${NC}"
echo "   Ctrl+b + arrow keys  - Navigate panes"
echo "   Ctrl+b + q           - Show pane numbers"
echo "   Ctrl+b + z           - Zoom current pane"
echo "   Ctrl+b + d           - Detach from session"
echo ""
echo -e "${GREEN}Attaching to session...${NC}"

# Verify session exists before attaching
if ! tmux has-session -t "$SESSION_SAFE" 2>/dev/null; then
    echo -e "${RED}ERROR: Session '$SESSION_NAME' was not created successfully${NC}"
    log "ERROR: Session verification failed"
    read -p "Press Enter to close..." dummy || true
    exit 1
fi

# Check if we're already in tmux
if [ -n "$TMUX" ]; then
    echo -e "${YELLOW}⚠️  You're already in a tmux session${NC}"
    echo -e "${BLUE}To switch to the new session, use:${NC}"
    echo -e "${GREEN}  tmux switch-client -t $SESSION_SAFE${NC}"
    echo ""
    echo -e "${BLUE}Or detach first and attach manually:${NC}"
    echo -e "${GREEN}  Ctrl+b, d  (detach)${NC}"
    echo -e "${GREEN}  tmux attach -t $SESSION_SAFE${NC}"
    log "Session created - switching client"; tmux switch-client -t "$SESSION_SAFE"
else
    # Not in tmux, safe to attach
    echo -e "${GREEN}Attaching to session...${NC}"
    echo -e "${YELLOW}Use 'Ctrl+b, then d' to detach later${NC}"
    log "Session creation complete - attaching"
    sleep 1
    exec tmux attach -t "$SESSION_SAFE"
fi
