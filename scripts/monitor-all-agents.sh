#!/bin/bash
# Central Agent Mail Monitor - Watches all registered agents and notifies them
# Run this from a terminal pane (like Bun 3)
# Usage: ./scripts/monitor-all-agents.sh [poll_interval]

set -e

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

# Mail server configuration (can be overridden via environment variables)
MAIL_SERVER="${MAIL_SERVER:-http://127.0.0.1:8765}"
MCP_AGENT_MAIL_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"
TOKEN_FILE="$MCP_AGENT_MAIL_DIR/.env"
PROJECT_KEY="$MAIL_PROJECT_KEY"
POLL_INTERVAL="${1:-5}"

# Load token
if [ ! -f "$TOKEN_FILE" ]; then
    echo "Error: Token file not found at $TOKEN_FILE"
    exit 1
fi
TOKEN=$(grep HTTP_BEARER_TOKEN "$TOKEN_FILE" | cut -d'=' -f2)

echo "📬 Central Mail Monitor started"
echo "   Polling every ${POLL_INTERVAL}s"
echo "   Press Ctrl+C to stop"
echo ""

# Build list of agents to monitor from identity files
declare -A AGENT_PANES
declare -A LAST_MSG_IDS

echo "Discovering agents..."
for identity_file in "$PANES_DIR/"*.identity; do
    if [ -f "$identity_file" ]; then
        MAIL_NAME=$(jq -r '.agent_mail_name // empty' "$identity_file" 2>/dev/null)
        PANE=$(jq -r '.pane // empty' "$identity_file" 2>/dev/null)
        PANE_NAME=$(jq -r '.name // empty' "$identity_file" 2>/dev/null)
        if [ -n "$MAIL_NAME" ] && [ -n "$PANE" ]; then
            AGENT_PANES["$MAIL_NAME"]="$PANE"
            LAST_MSG_IDS["$MAIL_NAME"]=0
            echo "   $MAIL_NAME ($PANE_NAME) -> $PANE"
        fi
    fi
done
echo ""

if [ ${#AGENT_PANES[@]} -eq 0 ]; then
    echo "No registered agents found. Make sure agents have agent_mail_name in their identity files."
    exit 1
fi

# Function to send notification to a specific pane
send_notification() {
    local pane="$1"
    local message="$2"
    tmux send-keys -t "$pane" "$message"
    sleep 0.5
    tmux send-keys -t "$pane" C-m
}

# Function to check inbox for one agent
check_agent_inbox() {
    local agent_name="$1"
    local pane="${AGENT_PANES[$agent_name]}"
    local last_seen="${LAST_MSG_IDS[$agent_name]:-0}"

    local response=$(curl -s -X POST "$MAIL_SERVER/mcp" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"tools/call\",\"params\":{\"name\":\"fetch_inbox\",\"arguments\":{\"project_key\":\"$PROJECT_KEY\",\"agent_name\":\"$agent_name\",\"limit\":10,\"include_bodies\":true}},\"id\":$(date +%s)}")

    local messages=$(echo "$response" | jq -r '.result.structuredContent.messages // []' 2>/dev/null)

    if [ "$messages" != "[]" ] && [ "$messages" != "null" ] && [ -n "$messages" ]; then
        local newest_id=$(echo "$response" | jq -r '.result.structuredContent.messages[0].id // 0' 2>/dev/null)

        if [ "$newest_id" -gt "$last_seen" ] 2>/dev/null; then
            # Get new message details
            local from=$(echo "$response" | jq -r '.result.structuredContent.messages[0].from // "unknown"')
            local subject=$(echo "$response" | jq -r '.result.structuredContent.messages[0].subject // "no subject"')
            local importance=$(echo "$response" | jq -r '.result.structuredContent.messages[0].importance // "normal"')

            echo "[$(date +%H:%M:%S)] 📨 New mail for $agent_name from $from: $subject"

            # Send notification to the agent's pane
            send_notification "$pane" "📨 NEW MAIL from $from"

            LAST_MSG_IDS["$agent_name"]="$newest_id"
        fi
    fi
}

# Trap for clean exit
trap 'echo ""; echo "📭 Central mail monitor stopped"; exit 0' INT TERM

# Main loop
while true; do
    for agent_name in "${!AGENT_PANES[@]}"; do
        check_agent_inbox "$agent_name"
    done
    sleep "$POLL_INTERVAL"
done
