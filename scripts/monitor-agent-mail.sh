#!/bin/bash
# Agent Mail Monitor - Notifies when new messages arrive
# Usage: ./scripts/monitor-agent-mail.sh [poll_interval_seconds]

set -e

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

# Mail server configuration (can be overridden via environment variables)
MAIL_SERVER="${MAIL_SERVER:-http://127.0.0.1:8765}"
MCP_AGENT_MAIL_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"
TOKEN_FILE="$MCP_AGENT_MAIL_DIR/.env"
PROJECT_KEY="$MAIL_PROJECT_KEY"
POLL_INTERVAL="${1:-5}"  # Default 5 seconds

# Use environment variable or find any registered agent
if [ -n "$AGENT_NAME" ]; then
    # Use provided agent name
    MY_NAME="$AGENT_NAME"
    SAFE_PANE=$(echo "$MY_NAME" | tr 'A-Z' 'a-z')
else
    # Try pane-specific identity first
    PANE_ID=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || echo "no-pane")
    SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')
    AGENT_NAME_FILE="$PIDS_DIR/${SAFE_PANE}.agent-name"

    # If not found, use any registered agent
    if [ ! -f "$AGENT_NAME_FILE" ]; then
        AGENT_NAME_FILE=$(ls "$PIDS_DIR/"*.agent-name 2>/dev/null | head -1)
        if [ -z "$AGENT_NAME_FILE" ]; then
            echo "Error: No registered agents found. Run: ./scripts/agent-mail-helper.sh register"
            exit 1
        fi
        MY_NAME=$(cat "$AGENT_NAME_FILE")
        SAFE_PANE=$(basename "$AGENT_NAME_FILE" .agent-name)
    else
        MY_NAME=$(cat "$AGENT_NAME_FILE")
    fi
fi

LAST_MSG_FILE="$PIDS_DIR/${SAFE_PANE}.last-msg-id"

# Load token
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found at $TOKEN_FILE"
    exit 1
fi
TOKEN=$(grep HTTP_BEARER_TOKEN "$TOKEN_FILE" | cut -d'=' -f2)

# Initialize last message ID if not exists
if [ ! -f "$LAST_MSG_FILE" ]; then
    echo "0" > "$LAST_MSG_FILE"
fi

echo "📬 Agent Mail Monitor started for $MY_NAME"
echo "   Checking every ${POLL_INTERVAL}s for new messages..."
echo "   Press Ctrl+C to stop"
echo ""

# Function to check for new messages
check_new_messages() {
    # Fetch inbox
    cat > /tmp/monitor-inbox.json << EOF
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "fetch_inbox",
    "arguments": {
      "project_key": "$PROJECT_KEY",
      "agent_name": "$MY_NAME",
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
        -d @/tmp/monitor-inbox.json)

    # Get last seen message ID
    local last_seen=$(cat "$LAST_MSG_FILE")

    # Parse messages and check for new ones
    local messages=$(echo "$response" | jq -r '.result.structuredContent.result // []')

    if [ "$messages" != "[]" ] && [ "$messages" != "null" ]; then
        # Get newest message ID
        local newest_id=$(echo "$response" | jq -r '.result.structuredContent.result[0].id // 0')

        if [ "$newest_id" -gt "$last_seen" ]; then
            # We have new messages!
            local new_messages=$(echo "$response" | jq -r --arg last "$last_seen" '
                .result.structuredContent.result[] |
                select(.id > ($last | tonumber)) |
                .
            ')

            # Display new messages
            echo ""
            echo "╔════════════════════════════════════════════════════════════════╗"
            echo "║  📨 NEW MESSAGE(S) RECEIVED - $(date '+%Y-%m-%d %H:%M:%S')      ║"
            echo "╚════════════════════════════════════════════════════════════════╝"
            echo ""

            echo "$response" | jq -r --arg last "$last_seen" '
                .result.structuredContent.result[] |
                select(.id > ($last | tonumber)) |
                "┌─ Message #\(.id) ─────────────────────────────────────────────\n│ FROM: \(.from)\n│ SUBJECT: \(.subject)\n│ IMPORTANCE: \(.importance)\n│ TIME: \(.created_ts)\n├──────────────────────────────────────────────────────────────\n│ \(.body_md)\n└──────────────────────────────────────────────────────────────\n"
            '

            # Update last seen ID
            echo "$newest_id" > "$LAST_MSG_FILE"
            echo "Use './scripts/agent-mail-helper.sh inbox' to see all messages"
            echo ""
        fi
    fi
}

# Trap Ctrl+C for clean exit
trap 'echo ""; echo "📭 Agent Mail Monitor stopped"; exit 0' INT TERM

# Main monitoring loop
while true; do
    check_new_messages
    sleep "$POLL_INTERVAL"
done
