#!/bin/bash
# Start the bypass file monitor in the background

# Detect agent-flywheel root dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$AGENT_FLYWHEEL_ROOT"

# Check if monitor is already running
if pgrep -f "monitor-bypass-files.sh" > /dev/null; then
    echo "Bypass monitor is already running"
    exit 0
fi

# Start monitor in background
nohup ./scripts/monitor-bypass-files.sh > ~/.claude/bypass-monitor.log 2>&1 &

echo "Bypass monitor started (PID: $!)"
echo "Logs: ~/.claude/bypass-monitor.log"
echo "Alerts: ~/.claude/bypass-alerts.log"
