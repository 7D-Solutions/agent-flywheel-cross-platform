#!/bin/bash
# Send command to agent and automatically press Enter
# Usage: ./send-to-agent.sh <pane> <command>

PANE="$1"
COMMAND="$2"

if [ -z "$PANE" ] || [ -z "$COMMAND" ]; then
    echo "Usage: $0 <pane> <command>"
    echo "Example: $0 flywheel:0.1 '/clear'"
    exit 1
fi

# Clear current input first
tmux send-keys -t "$PANE" C-u

# Send the command
tmux send-keys -t "$PANE" "$COMMAND"

# Wait briefly to ensure command is received
sleep 0.2

# Press Enter to execute
tmux send-keys -t "$PANE" C-m
