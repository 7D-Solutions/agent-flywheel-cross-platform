#!/bin/bash
# Auto-register agent with mail system (pane-specific)
# Source this in your shell init or run at session start

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

cd "$PROJECT_ROOT" || exit 1

# Allow quiet mode for non-interactive callers
QUIET="${QUIET:-false}"
# Show progress indicators even when QUIET=true (default: true)
SHOW_PROGRESS="${SHOW_PROGRESS:-true}"
log() {
    if [ "$QUIET" = "true" ]; then
        return 0
    fi
    echo "$1"
}

progress_log() {
    local msg="$1"
    if [ "$QUIET" != "true" ]; then
        printf "%s\r" "$msg"
        return 0
    fi
    if [ "$SHOW_PROGRESS" = "true" ] && [ -t 1 ] && [ -w /dev/tty ]; then
        printf "%s\r" "$msg" >/dev/tty
    fi
}

# Get pane-specific identifier (prefer TMUX_PANE when available)
if [ -n "$TMUX_PANE" ]; then
    PANE_ID=$(tmux display-message -t "$TMUX_PANE" -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null)
else
    PANE_ID=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null)
fi
if [ -z "$PANE_ID" ]; then
    log "✗ Not running in tmux"
    return 1 2>/dev/null || exit 1
fi

SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')
AGENT_NAME_FILE="$PROJECT_ROOT/pids/${SAFE_PANE}.agent-name"

# If already registered, load name and exit
if [ -f "$AGENT_NAME_FILE" ]; then
    export AGENT_NAME=$(cat "$AGENT_NAME_FILE")
    log "✓ Agent registered as: $AGENT_NAME (pane: $PANE_ID)"
    return 0 2>/dev/null || exit 0
fi

# Auto-register
log "🔄 Registering new agent for pane $PANE_ID..."

# Get pane index for friendly name
PANE_INDEX=$(echo "$PANE_ID" | grep -oE '\.[0-9]+$' | tr -d '.')
TASK_DESC="Claude $PANE_INDEX - Claude Code Session"

# Register using helper script (modified to accept pane ID)
mkdir -p "$(dirname "$AGENT_NAME_FILE")"

# Mail server configuration (can be overridden via environment variables)
MAIL_SERVER="${MAIL_SERVER:-http://127.0.0.1:8765}"
MCP_AGENT_MAIL_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"
TOKEN_FILE="$MCP_AGENT_MAIL_DIR/.env"
if [ -f "$TOKEN_FILE" ]; then
    TOKEN=$(grep HTTP_BEARER_TOKEN "$TOKEN_FILE" | cut -d'=' -f2)
else
    log "✗ Token file not found at $TOKEN_FILE"
    return 1 2>/dev/null || exit 1
fi

# Collect active agent names to avoid cross-project collisions
get_active_agent_names() {
    tmux list-panes -a -F "#{@agent_name}" 2>/dev/null \
        | sed '/^$/d' \
        | tr '[:upper:]' '[:lower:]' \
        | sort -u
}

generate_candidate_name() {
    if [ ! -d "$MCP_AGENT_MAIL_DIR/src" ]; then
        log "✗ MCP agent mail library not found at $MCP_AGENT_MAIL_DIR/src"
        log "  Set MCP_AGENT_MAIL_DIR or install mcp_agent_mail to enable name generation."
        return 1
    fi
    local python_bin="python"
    if ! command -v "$python_bin" >/dev/null 2>&1; then
        python_bin="python3"
    fi
    if ! command -v "$python_bin" >/dev/null 2>&1; then
        log "✗ Python not found (need python or python3 for name generation)"
        return 1
    fi
    PYTHONPATH="$MCP_AGENT_MAIL_DIR/src" "$python_bin" - <<'PY'
from mcp_agent_mail.utils import generate_agent_name
print(generate_agent_name())
PY
}

request_unique_agent_name() {
    local active_names="$1"
    local max_attempts=50
    local attempt=1

    while [ "$attempt" -le "$max_attempts" ]; do
        progress_log "Allocating unique agent name... ($attempt/$max_attempts)"
        local candidate
        candidate=$(generate_candidate_name 2>/dev/null) || candidate=""
        if [ -z "$candidate" ]; then
            log "✗ Failed to generate candidate agent name"
            return 1
        fi

        local candidate_lower
        candidate_lower=$(echo "$candidate" | tr '[:upper:]' '[:lower:]')
        if echo "$active_names" | grep -qx "$candidate_lower"; then
            attempt=$((attempt + 1))
            continue
        fi

        cat > /tmp/agent-reg-${SAFE_PANE}.json << EOF
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "create_agent_identity",
    "arguments": {
      "project_key": "$MAIL_PROJECT_KEY",
      "program": "claude-code",
      "model": "sonnet",
      "name_hint": "$candidate",
      "task_description": "$TASK_DESC"
    }
  },
  "id": $(date +%s)
}
EOF

        RESPONSE=$(curl -s -X POST "$MAIL_SERVER/mcp" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d @/tmp/agent-reg-${SAFE_PANE}.json)

        local err_msg
        err_msg=$(echo "$RESPONSE" | jq -r '.error.message // empty')
        if [ -n "$err_msg" ]; then
            attempt=$((attempt + 1))
            continue
        fi

        AGENT_NAME=$(echo "$RESPONSE" | jq -r '.result.structuredContent.name // .result.structuredContent.agent.name // .result.name // empty')
        if [ -n "$AGENT_NAME" ] && [ "$AGENT_NAME" != "null" ]; then
            return 0
        fi

        attempt=$((attempt + 1))
    done

    return 1
}

ACTIVE_AGENT_NAMES=$(get_active_agent_names)
if ! request_unique_agent_name "$ACTIVE_AGENT_NAMES"; then
    log "✗ Failed to allocate a unique agent name after 50 attempts"
    return 1 2>/dev/null || exit 1
fi

if [ "$AGENT_NAME" != "null" ] && [ -n "$AGENT_NAME" ]; then
    echo "$AGENT_NAME" > "$AGENT_NAME_FILE"
    export AGENT_NAME
    log "✓ Registered as: $AGENT_NAME"


    # Also update tmux pane title
    if [ -n "$TMUX_PANE" ]; then
        tmux set-option -p -t "$TMUX_PANE" @agent_name "$AGENT_NAME" 2>/dev/null || true
        # Also set LLM name based on pane type
        MY_INDEX=$(tmux display-message -t "$TMUX_PANE" -p "#{pane_index}" 2>/dev/null)
        MY_CMD=$(tmux display-message -t "$TMUX_PANE" -p "#{pane_current_command}" 2>/dev/null)
        if [[ "$MY_CMD" == "claude" ]]; then
            LLM_NAME="Claude $MY_INDEX"
        elif [[ "$MY_CMD" == *"codex"* ]]; then
            # Codex CLI detected
            LLM_NAME="Codex $MY_INDEX"
        elif [[ "$MY_CMD" == "python"* ]] || [[ "$MY_CMD" == "aider" ]]; then
            # Check if it's actually aider by looking at process args
            MY_TTY=$(tmux display-message -t "$TMUX_PANE" -p "#{pane_tty}" 2>/dev/null)
            if [ -n "$MY_TTY" ] && lsof -t "$MY_TTY" 2>/dev/null | xargs ps -p 2>/dev/null | grep -q "aider"; then
                LLM_NAME="Codex $MY_INDEX"
            else
                LLM_NAME="Terminal $MY_INDEX"
            fi
        else
            LLM_NAME="Terminal $MY_INDEX"
        fi
        tmux set-option -p -t "$TMUX_PANE" @llm_name "$LLM_NAME" 2>/dev/null || true
    fi
    # Also update pane identity file with agent mail name
    IDENTITY_FILE="$PROJECT_ROOT/panes/${SAFE_PANE}.identity"
    if [ -f "$IDENTITY_FILE" ]; then
        # Add agent_mail_name to identity
        jq --arg name "$AGENT_NAME" '. + {agent_mail_name: $name}' "$IDENTITY_FILE" > "${IDENTITY_FILE}.tmp"
        mv "${IDENTITY_FILE}.tmp" "$IDENTITY_FILE"
    fi
else
    log "✗ Failed to register agent"
    if [ "$QUIET" != "true" ]; then
        echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    fi
    return 1 2>/dev/null || exit 1
fi
