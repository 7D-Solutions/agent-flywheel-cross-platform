#!/bin/bash
# Launcher script for iTerm2
cd "$(dirname "$0")"

# Check if fzf is available for visual interface
if command -v fzf &> /dev/null; then
    exec bash ./scripts/visual-session-manager.sh
else
    exec bash ./scripts/start-multi-agent-session-v2.sh
fi
