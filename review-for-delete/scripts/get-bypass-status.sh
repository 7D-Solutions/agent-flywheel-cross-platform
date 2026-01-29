#!/bin/bash
# Get current bypass status for tmux status bar

# Configurable projects directory (can be overridden via environment variable)
PROJECTS_DIR="${PROJECTS_DIR:-$HOME/Projects}"

# Dynamically discover all projects
PROJECTS=()
while IFS= read -r dir; do
    PROJECTS+=("$dir")
done < <(find "$PROJECTS_DIR" -maxdepth 1 -mindepth 1 -type d -not -name ".*" 2>/dev/null | sort)

active_bypasses=()

for project in "${PROJECTS[@]}"; do
    if [ -f "$project/.claude-hooks-bypass" ]; then
        project_name=$(basename "$project")
        active_bypasses+=("$project_name")
    fi
done

count=${#active_bypasses[@]}

if [ $count -eq 0 ]; then
    echo "🔒 No bypasses"
elif [ $count -eq 1 ]; then
    echo "⚠️ Bypass '${active_bypasses[0]}'"
elif [ $count -eq 2 ]; then
    echo "⚠️ Bypasses '${active_bypasses[0]}', '${active_bypasses[1]}'"
else
    echo "⚠️ $count bypasses active"
fi
