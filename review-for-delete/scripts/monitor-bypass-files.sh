#!/bin/bash
# Global bypass file monitor
# Watches all known projects for .claude-hooks-bypass creation/modification

# Configurable projects directory (can be overridden via environment variable)
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

PROJECTS=()
while IFS= read -r dir; do
    PROJECTS+=("$dir")
done < <(find "$PROJECTS_DIR" -maxdepth 1 -mindepth 1 -type d -not -name ".*" 2>/dev/null | sort)

ALERT_LOG="$HOME/.claude/bypass-alerts.log"
CURRENT_STATE="$HOME/.claude/bypass-current-state"

mkdir -p "$(dirname "$ALERT_LOG")"

# Function to get project name from path
get_project_name() {
    basename "$1"
}

# Function to check all projects and detect changes
check_bypasses() {
    local new_state=""
    local changes=""

    for project in "${PROJECTS[@]}"; do
        if [ -f "$project/.claude-hooks-bypass" ]; then
            project_name=$(get_project_name "$project")
            new_state+="$project_name\n"

            # Check if this is a new bypass (not in previous state)
            if [ -f "$CURRENT_STATE" ] && ! grep -q "^$project_name$" "$CURRENT_STATE" 2>/dev/null; then
                changes+="CREATED: Bypass '$project_name'\n"

                # Log the creation
                echo "$(date '+%Y-%m-%d %H:%M:%S') | CREATED | $project_name | $project/.claude-hooks-bypass" >> "$ALERT_LOG"

                # Display visible alert to user in project terminals
                tmux display-message -d 5000 "⚠️  BYPASS CREATED: '$project_name' - Hook security disabled!" 2>/dev/null
            fi
        fi
    done

    # Check for removed bypasses
    if [ -f "$CURRENT_STATE" ]; then
        while read -r old_project; do
            if [ -n "$old_project" ] && ! echo -e "$new_state" | grep -q "^$old_project$"; then
                changes+="REMOVED: Bypass '$old_project'\n"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | REMOVED | $old_project" >> "$ALERT_LOG"

                # Display visible alert to user in project terminals
                tmux display-message -d 3000 "✅ BYPASS REMOVED: '$old_project' - Hook security re-enabled!" 2>/dev/null
            fi
        done < "$CURRENT_STATE"
    fi

    # Update current state
    echo -e "$new_state" > "$CURRENT_STATE"

    # Display changes
    if [ -n "$changes" ]; then
        echo -e "$changes"
    fi
}

# Check for fswatch
if command -v fswatch >/dev/null 2>&1; then
    echo "Starting fswatch-based bypass monitor..."

    # Build watch list
    watch_paths=()
    for project in "${PROJECTS[@]}"; do
        watch_paths+=("$project/.claude-hooks-bypass")
    done

    # Initial check
    check_bypasses

    # Watch for changes
    fswatch -0 "${watch_paths[@]}" 2>/dev/null | while read -d "" event; do
        project_dir=$(dirname "$event")
        project_name=$(get_project_name "$project_dir")

        if [ -f "$event" ]; then
            echo "🔓 Bypass '$project_name'"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DETECTED | $project_name | $event" >> "$ALERT_LOG"
        fi
    done
else
    # Fallback: polling mode (no fswatch)
    echo "fswatch not found, using polling mode (checks every 10 seconds)..."

    # Initial check
    check_bypasses

    # Poll for changes
    while true; do
        sleep 10
        check_bypasses
    done
fi
