#!/bin/bash
# Agent Mail Monitor - Sends notifications directly to terminal via tmux
# Usage: ./scripts/monitor-agent-mail-to-terminal.sh [agent_name] [poll_interval]

set -e

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

# Mail server configuration (can be overridden via environment variables)
MAIL_SERVER="${MAIL_SERVER:-http://127.0.0.1:8765}"
MCP_AGENT_MAIL_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"
TOKEN_FILE="$MCP_AGENT_MAIL_DIR/.env"
PROJECT_KEY="$MAIL_PROJECT_KEY"
AGENT_NAME="${1:-$AGENT_NAME}"
POLL_INTERVAL="${2:-5}"

# Find agent name if not provided
if [ -z "$AGENT_NAME" ]; then
    # Get from current pane
    PANE_ID=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || echo "")
    if [ -n "$PANE_ID" ]; then
        SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')
        AGENT_FILE="$PIDS_DIR/${SAFE_PANE}.agent-name"
        if [ -f "$AGENT_FILE" ]; then
            AGENT_NAME=$(cat "$AGENT_FILE")
        fi
    fi
fi

if [ -z "$AGENT_NAME" ]; then
    echo "Error: No agent name provided and couldn't detect from pane"
    echo "Usage: $0 <agent_name> [poll_interval]"
    exit 1
fi

# Get this agent's pane ID by searching identity files for agent_mail_name
MY_PANE=""
for identity_file in "$PANES_DIR/"*.identity; do
    if [ -f "$identity_file" ]; then
        MAIL_NAME=$(jq -r '.agent_mail_name // empty' "$identity_file" 2>/dev/null)
        if [ "$MAIL_NAME" = "$AGENT_NAME" ]; then
            MY_PANE=$(jq -r '.pane' "$identity_file")
            break
        fi
    fi
done

if [ -z "$MY_PANE" ]; then
    echo "Error: Could not find pane for agent $AGENT_NAME"
    echo "Make sure the agent is registered and identity file has agent_mail_name set"
    exit 1
fi

# Load token
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found at $TOKEN_FILE"
    exit 1
fi
TOKEN=$(grep HTTP_BEARER_TOKEN "$TOKEN_FILE" | cut -d'=' -f2)

# Track last seen message
LAST_MSG_FILE="$PIDS_DIR/$(echo $AGENT_NAME | tr 'A-Z' 'a-z').last-msg-id"
if [ ! -f "$LAST_MSG_FILE" ]; then
    echo "0" > "$LAST_MSG_FILE"
fi

echo "📬 Mail-to-Terminal Monitor started"
echo "   Agent: $AGENT_NAME"
echo "   Pane: $MY_PANE"
echo "   Polling every ${POLL_INTERVAL}s"
echo "   Press Ctrl+C to stop"
echo ""

# Function to send notification to terminal (as input for Claude Code)
send_to_terminal() {
    local message="$1"
    # Send as actual input that Claude will see
    tmux send-keys -t "$MY_PANE" "$message"
    sleep 0.5
    tmux send-keys -t "$MY_PANE" C-m
}

# Function to check for new messages
check_new_messages() {
    cat > /tmp/monitor-inbox-$AGENT_NAME.json << EOF
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "fetch_inbox",
    "arguments": {
      "project_key": "$PROJECT_KEY",
      "agent_name": "$AGENT_NAME",
      "limit": 50,
      "include_bodies": true
    }
  },
  "id": $(date +%s)
}
EOF

    local response=$(curl -s -X POST "$MAIL_SERVER/mcp" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d @/tmp/monitor-inbox-$AGENT_NAME.json)

    local last_seen=$(cat "$LAST_MSG_FILE")
    local messages=$(echo "$response" | jq -r '.result.structuredContent.result // []')

    if [ "$messages" != "[]" ] && [ "$messages" != "null" ]; then
        local newest_id=$(echo "$response" | jq -r '.result.structuredContent.result[0].id // 0')

        if [ "$newest_id" -gt "$last_seen" ]; then
            # Format and send new messages to terminal
            local notification=$(echo "$response" | jq -r --arg last "$last_seen" '
                .result.structuredContent.result[] |
                select(.id > ($last | tonumber)) |
                "📨 NEW MAIL from \(.from)"
            ')

            if [ -n "$notification" ]; then
                # Print to this script's output
                echo ""
                echo "╔════════════════════════════════════════════╗"
                echo "║  NEW MESSAGE RECEIVED                      ║"
                echo "╚════════════════════════════════════════════╝"
                echo "$notification"

                # Send visual notification to the terminal pane
                echo "$notification" | while IFS= read -r line; do
                    send_to_terminal "$line"
                done
            fi

            echo "$newest_id" > "$LAST_MSG_FILE"
        fi
    fi
}

# Trap for clean exit
trap 'echo ""; echo "📭 Mail monitor stopped"; exit 0' INT TERM

# Main loop
while true; do
    check_new_messages
    sleep "$POLL_INTERVAL"
done
