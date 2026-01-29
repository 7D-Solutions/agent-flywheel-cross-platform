#!/bin/bash
# Live display of agent mail notifications
# Usage: ./scripts/show-mail-notifications.sh

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

DISPLAY_FILE="$LOGS_DIR/mail-notifications.txt"

# Create initial display file (already done by config init, but ensure it exists)
mkdir -p "$LOGS_DIR"

while true; do
    clear
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  📬 AGENT MAIL - LIVE NOTIFICATIONS                           ║"
    echo "║  $(date '+%Y-%m-%d %H:%M:%S')                                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check all monitor logs for recent activity
    LOGS=$(ls "$LOGS_DIR/"*.mail-monitor.log 2>/dev/null)

    if [ -z "$LOGS" ]; then
        echo "❌ No mail monitors running"
        echo ""
        echo "Start a monitor: ./scripts/mail-monitor-ctl.sh start"
    else
        for log in $LOGS; do
            if [ ! -f "$log" ]; then
                continue
            fi

            # Get agent name from log
            agent_name=$(head -1 "$log" | grep -o "for [A-Za-z]*" | cut -d' ' -f2)

            # Show last 20 lines (recent activity)
            echo "═══ $agent_name ═══"
            tail -n 20 "$log" | grep -E "MESSAGE|FROM|SUBJECT|│|─|┌|└" || echo "  (No recent messages)"
            echo ""
        done

        echo "─────────────────────────────────────────────────────────────────"
        echo "Refreshing every 5 seconds... Press Ctrl+C to exit"
    fi

    sleep 5
done
