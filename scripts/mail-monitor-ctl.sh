#!/bin/bash
# Control script for Agent Mail Monitor (terminal notifications)
# Usage: ./scripts/mail-monitor-ctl.sh {start|stop|status|restart}

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/project-config.sh"

PROJECT_KEY="$MAIL_PROJECT_KEY"

# Determine pane identifier - always bind to current tmux pane
PANE_ID=$(tmux display-message -p "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null || echo "")
if [ -z "$PANE_ID" ]; then
    echo "Error: Not running inside tmux; cannot determine pane"
    exit 1
fi
SAFE_PANE=$(echo "$PANE_ID" | tr ':.' '-')
if [ -z "$AGENT_NAME" ] && [ -f "$PIDS_DIR/${SAFE_PANE}.agent-name" ]; then
    AGENT_NAME=$(cat "$PIDS_DIR/${SAFE_PANE}.agent-name")
fi
if [ -z "$AGENT_NAME" ]; then
    echo "Error: No agent name found for pane $PANE_ID"
    echo "Make sure ${PIDS_DIR}/${SAFE_PANE}.agent-name exists."
    exit 1
fi

PID_FILE="$PIDS_DIR/${SAFE_PANE}.mail-monitor.pid"
LOG_FILE="$LOGS_DIR/${SAFE_PANE}.mail-monitor.log"

start_monitor() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "❌ Monitor already running (PID: $pid)"
            return 1
        else
            # Stale PID file, remove it
            rm -f "$PID_FILE"
        fi
    fi

    mkdir -p "$(dirname "$LOG_FILE")"

    echo "📬 Starting Agent Mail Monitor (terminal notifications)..."
    if [ -f "$PIDS_DIR/${SAFE_PANE}.agent-name" ]; then
        export AGENT_NAME=$(cat "$PIDS_DIR/${SAFE_PANE}.agent-name")
    fi
    nohup "$SCRIPT_DIR/monitor-agent-mail-to-terminal.sh" "$AGENT_NAME" > "$LOG_FILE" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    sleep 1
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "✅ Monitor started (PID: $pid)"
        echo "   Log: $LOG_FILE"
        echo "   Use 'tail -f $LOG_FILE' to watch for messages"
    else
        echo "❌ Failed to start monitor"
        if [ -f "$LOG_FILE" ]; then
            echo "   Last log lines:"
            tail -n 5 "$LOG_FILE"
        fi
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_monitor() {
    if [ ! -f "$PID_FILE" ]; then
        echo "❌ Monitor not running"
        return 1
    fi

    local pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "📭 Stopping Agent Mail Monitor (PID: $pid)..."
        kill "$pid"
        rm -f "$PID_FILE"
        echo "✅ Monitor stopped"
    else
        echo "❌ Monitor not running (stale PID file)"
        rm -f "$PID_FILE"
        return 1
    fi
}

status_monitor() {
    if [ ! -f "$PID_FILE" ]; then
        echo "📭 Monitor is NOT running"
        return 1
    fi

    local pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "📬 Monitor is RUNNING (PID: $pid)"
        echo "   Log: $LOG_FILE"
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo "Recent activity (last 10 lines):"
            tail -n 10 "$LOG_FILE"
        fi
    else
        echo "📭 Monitor is NOT running (stale PID file)"
        rm -f "$PID_FILE"
        return 1
    fi
}

case "${1:-help}" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    status)
        status_monitor
        ;;
    restart)
        stop_monitor 2>/dev/null || true
        sleep 1
        start_monitor
        ;;
    logs)
        if [ -f "$LOG_FILE" ]; then
            tail -f "$LOG_FILE"
        else
            echo "❌ No log file found"
            exit 1
        fi
        ;;
    help|*)
        cat << 'HELP'
Agent Mail Monitor Control

Usage:
  ./scripts/mail-monitor-ctl.sh <command>

Commands:
  start      Start the mail monitor in background
  stop       Stop the mail monitor
  status     Check if monitor is running and show recent activity
  restart    Restart the monitor
  logs       Follow the monitor log file (Ctrl+C to exit)

The monitor will check for new messages every 5 seconds and display
them in the terminal when they arrive.

HELP
        ;;
esac
