#!/bin/bash
# Cleanup stale identity files after pane removal
# Called by tmux hook after-kill-pane

SESSION_NAME="${1:-flywheel}"

# Get the working directory of the first pane in the session to determine PROJECT_ROOT
FIRST_PANE=$(tmux list-panes -t "$SESSION_NAME" -F "#{pane_id}" 2>/dev/null | head -1)
if [ -z "$FIRST_PANE" ]; then
    # No panes left, nothing to clean up
    exit 0
fi

PROJECT_ROOT=$(tmux display-message -t "$FIRST_PANE" -p "#{pane_current_path}" 2>/dev/null)
if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT" ]; then
    exit 0
fi

# Source project config and run discovery to clean up stale files
export PROJECT_ROOT
# Detect agent-flywheel root dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"
if [ -f "$AGENT_FLYWHEEL_ROOT/scripts/lib/project-config.sh" ]; then
    source "$AGENT_FLYWHEEL_ROOT/scripts/lib/project-config.sh"
    if [ -f "$AGENT_FLYWHEEL_ROOT/panes/discover.sh" ]; then
        bash "$AGENT_FLYWHEEL_ROOT/panes/discover.sh" --all --quiet 2>/dev/null || true
    fi
    # Renumber remaining panes to maintain sequential Claude numbering
    if [ -f "$AGENT_FLYWHEEL_ROOT/scripts/renumber-panes.sh" ]; then
        bash "$AGENT_FLYWHEEL_ROOT/scripts/renumber-panes.sh" "$SESSION_NAME" >/dev/null 2>&1 || true
    fi
fi
