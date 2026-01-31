#!/bin/bash
# Visual session manager using fzf
# Works on both Mac and Windows (WSL/Git Bash)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="$PROJECT_ROOT/.session-state"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Create state directory for session resurrection
mkdir -p "$STATE_DIR"

# Check if fzf is installed
check_fzf() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${YELLOW}⚠️  fzf is not installed${NC}"
        echo ""
        echo "fzf is required for the visual interface."
        echo ""
        echo -e "${BLUE}Would you like to install it now?${NC}"
        echo ""
        echo -e "  ${GREEN}[Y]${NC} Yes, install fzf (recommended)"
        echo -e "  ${GREEN}[N]${NC} No, use text interface instead"
        echo ""
        read -p "Your choice [Y/n]: " -n 1 install_choice
        echo ""
        echo ""

        case "$install_choice" in
            [Nn])
                echo -e "${BLUE}Using text-based interface...${NC}"
                exec "$SCRIPT_DIR/start-multi-agent-session-v2.sh"
                ;;
            *)
                echo -e "${GREEN}Installing fzf...${NC}"
                echo ""

                # Run setup script
                if [ -f "$PROJECT_ROOT/setup-fzf.sh" ]; then
                    "$PROJECT_ROOT/setup-fzf.sh"

                    # Check if installation succeeded
                    if command -v fzf &> /dev/null; then
                        echo ""
                        echo -e "${GREEN}✓ Installation successful! Starting visual interface...${NC}"
                        sleep 2
                        # Re-run this script now that fzf is installed
                        exec "$0" "$@"
                    else
                        echo ""
                        echo -e "${YELLOW}Installation completed but fzf not found in PATH.${NC}"
                        echo -e "${YELLOW}You may need to restart your terminal.${NC}"
                        echo ""
                        echo -e "${BLUE}Falling back to text interface...${NC}"
                        sleep 2
                        exec "$SCRIPT_DIR/start-multi-agent-session-v2.sh"
                    fi
                else
                    echo -e "${RED}setup-fzf.sh not found${NC}"
                    echo ""
                    echo "Please install fzf manually:"
                    if [[ "$OSTYPE" == "darwin"* ]]; then
                        echo "  ${GREEN}brew install fzf${NC}"
                    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
                        echo "  ${GREEN}scoop install fzf${NC}  (or)  ${GREEN}choco install fzf${NC}"
                    else
                        echo "  ${GREEN}sudo apt install fzf${NC}"
                    fi
                    echo ""
                    echo -e "${BLUE}Falling back to text interface...${NC}"
                    sleep 2
                    exec "$SCRIPT_DIR/start-multi-agent-session-v2.sh"
                fi
                ;;
        esac
    fi
}

# Get list of running tmux sessions (suppressed - not used)
get_running_sessions() {
    tmux list-sessions &>/dev/null && return 0 || return 1
}

# Get list of killed sessions (saved states)
get_killed_sessions() {
    if [ -d "$STATE_DIR" ]; then
        find "$STATE_DIR" -name "*.state" -type f 2>/dev/null | while read -r statefile; do
            basename "$statefile" .state
        done
    fi
}

# Save session state before killing (for resurrection)
save_session_state() {
    local session_name="$1"
    local state_file="$STATE_DIR/${session_name}.state"

    # Save session metadata
    {
        echo "SESSION_NAME=$session_name"
        echo "KILLED_AT=$(date +%s)"
        echo "KILLED_DATE=$(date '+%Y-%m-%d %H:%M:%S')"

        # Save session details
        tmux list-windows -t "$session_name" -F "WINDOW_#{window_index}=#{window_name}" 2>/dev/null || true

        # Save pane information
        tmux list-panes -t "$session_name" -a -F "PANE_#{window_index}_#{pane_index}=#{pane_current_path}|#{pane_current_command}" 2>/dev/null || true

        # Save agent names if available
        tmux list-panes -t "$session_name" -a -F "AGENT_#{window_index}_#{pane_index}=#{@agent_name}" 2>/dev/null | grep -v "AGENT.*=$" || true
    } > "$state_file"

    echo -e "${GREEN}✓ Saved session state: $session_name${NC}" >&2
}

# Resurrect a killed session
resurrect_session() {
    local session_name="$1"
    local state_file="$STATE_DIR/${session_name}.state"

    if [ ! -f "$state_file" ]; then
        echo -e "${RED}❌ No saved state found for: $session_name${NC}"
        return 1
    fi

    echo -e "${BLUE}Resurrecting session: $session_name${NC}"

    # For now, we'll just restart the session creation script
    # In a full implementation, we'd restore the exact layout
    echo -e "${YELLOW}Note: Starting fresh session (full state restoration coming soon)${NC}"

    # Remove the state file since we're resurrecting
    rm -f "$state_file"

    # Delegate to the main session creation script
    exec "$SCRIPT_DIR/start-multi-agent-session-v2.sh"
}

# Permanently delete a killed session state
delete_session_state() {
    local session_name="$1"
    local state_file="$STATE_DIR/${session_name}.state"

    if [ -f "$state_file" ]; then
        rm -f "$state_file"
        echo -e "${GREEN}✓ Permanently deleted: $session_name${NC}"
    fi
}

# Build session list for fzf with clear sections
build_session_list() {
    local attached_sessions=""
    local running_sessions=""
    local killed_sessions=""

    # Collect sessions by status
    if tmux list-sessions &>/dev/null; then
        while IFS='|' read -r name status attached windows; do
            if [ "$attached" = "1" ]; then
                # Attached sessions
                attached_sessions+=$(printf "  🔵  %-28s  │  %s agents  │  Active Now|%s|Attached|%s|attached\n" \
                    "$name" "$windows" "$name" "$windows")$'\n'
            else
                # Running but detached
                running_sessions+=$(printf "  🟢  %-28s  │  %s agents  │  Background|%s|Running|%s|running\n" \
                    "$name" "$windows" "$name" "$windows")$'\n'
            fi
        done < <(tmux list-sessions -F "#{session_name}|running|#{session_attached}|#{session_windows}" 2>/dev/null)
    fi

    # Add killed sessions
    while read -r name; do
        if [ -n "$name" ]; then
            local state_file="$STATE_DIR/${name}.state"
            local killed_date=""
            if [ -f "$state_file" ]; then
                killed_date=$(grep "^KILLED_DATE=" "$state_file" | cut -d'=' -f2)
            fi
            killed_sessions+=$(printf "  💀  %-28s  │  Saved      │  %s|%s|Killed|%s|killed\n" \
                "$name" "${killed_date:-Unknown}" "$name" "$killed_date")$'\n'
        fi
    done < <(get_killed_sessions)

    # Build final list with section headers
    local final_list=""

    if [ -n "$attached_sessions" ]; then
        final_list+="||header||header"$'\n'
        final_list+="  ┌──────────────────────────────────────────────────────────────┐||header||header"$'\n'
        final_list+="  │ 📍 ATTACHED SESSIONS (Currently Viewing)                    │||header||header"$'\n'
        final_list+="  └──────────────────────────────────────────────────────────────┘||header||header"$'\n'
        final_list+="$attached_sessions"
    fi

    # Add separator between sections if we have more sections coming
    if [ -n "$attached_sessions" ] && { [ -n "$running_sessions" ] || [ -n "$killed_sessions" ]; }; then
        final_list+="||separator||separator"$'\n'
    fi

    if [ -n "$running_sessions" ]; then
        final_list+="||header||header"$'\n'
        final_list+="  ┌──────────────────────────────────────────────────────────────┐||header||header"$'\n'
        final_list+="  │ ⚡ RUNNING SESSIONS (Background)                             │||header||header"$'\n'
        final_list+="  └──────────────────────────────────────────────────────────────┘||header||header"$'\n'
        final_list+="$running_sessions"
    fi

    # Add separator before killed sessions if needed
    if [ -n "$running_sessions" ] && [ -n "$killed_sessions" ]; then
        final_list+="||separator||separator"$'\n'
    fi

    if [ -n "$killed_sessions" ]; then
        final_list+="||header||header"$'\n'
        final_list+="  ┌──────────────────────────────────────────────────────────────┐||header||header"$'\n'
        final_list+="  │ 💾 SAVED SESSIONS (Can Resurrect)                           │||header||header"$'\n'
        final_list+="  └──────────────────────────────────────────────────────────────┘||header||header"$'\n'
        final_list+="$killed_sessions"
    fi

    echo -n "$final_list"
}

# Main visual interface
show_visual_interface() {
    while true; do
        # Clear screen first
        clear

        # Build session list
        local sessions
        sessions=$(build_session_list 2>/dev/null)

        if [ -z "$sessions" ]; then
            echo -e "${YELLOW}No sessions found (running or killed)${NC}"
            echo ""
            echo -e "${GREEN}[N]${NC} Create new session"
            echo -e "${GREEN}[Q]${NC} Quit"
            echo ""
            read -p "Your choice: " -n 1 choice
            echo ""

            case "$choice" in
                [Nn])
                    create_new_session
                    ;;
                [Qq])
                    exit 0
                    ;;
            esac
            continue
        fi

        # Show session list with fzf (headers and separators visible but will be filtered after selection)
        local selected=$(echo "$sessions" | fzf \
            --ansi \
            --multi \
            --header="
╔══════════════════════════════════════════════════════════════════════╗
║                  🎡  Agent Flywheel - Session Manager                ║
╠══════════════════════════════════════════════════════════════════════╣
║                                                                      ║
║   ↑↓  Move    │   Tab  Select Multiple    │   Enter  Actions       ║
║   Q   Quit    │   Ctrl-A  Select All      │   N  Create New        ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
" \
            --header-lines=0 \
            --preview='
session_name=$(echo {} | cut -d"|" -f2)
status=$(echo {} | cut -d"|" -f3)

echo ""
echo "╔════════════════════════════════════╗"
echo "║      SESSION INFORMATION           ║"
echo "╚════════════════════════════════════╝"
echo ""
echo "  Name:     $session_name"
echo "  Status:   $status"
echo ""
if [ "$status" = "Attached" ]; then
    echo "  📍 You are currently viewing"
    echo "     this session in another"
    echo "     window/tab."
    echo ""
    echo "  Actions:"
    echo "  • Detach: Ctrl+b then d"
elif [ "$status" = "Running" ]; then
    echo "  ⚡ Agents working in background"
    echo ""
    echo "  Actions:"
    echo "  • Press Enter → A to attach"
    echo "  • Press Enter → K to kill"
elif [ "$status" = "Killed" ]; then
    echo "  💾 Session saved to disk"
    echo ""
    echo "  Actions:"
    echo "  • Press Enter → R to resurrect"
    echo "  • Press Enter → D to delete"
fi
echo ""
' \
            --preview-window=right:45%:wrap:border-rounded \
            --bind='ctrl-a:select-all,ctrl-d:deselect-all,q:abort' \
            --prompt="Select ❯ " \
            --pointer="▶ " \
            --marker="✓ " \
            --delimiter="|" \
            --with-nth=1 \
            --layout=reverse \
            --height=95% \
            --border=rounded \
            --border-label="╣ Select Sessions ╠" \
            --no-info \
            --color='fg:#e0e0e0,bg:#0a0a0a,hl:#00d7ff' \
            --color='fg+:#ffffff,bg+:#1a1a1a,hl+:#00ffff' \
            --color='info:#00d7ff,prompt:#00d7ff,pointer:#ff00ff' \
            --color='marker:#00ff00,spinner:#ff00ff,header:#00d7ff' \
            --color='border:#555555,label:#00d7ff,preview-border:#555555')

        if [ -z "$selected" ]; then
            # User cancelled (Ctrl-C)
            echo ""
            echo -e "${YELLOW}What would you like to do?${NC}"
            echo -e "${GREEN}[N]${NC} Create new session"
            echo -e "${GREEN}[Q]${NC} Quit"
            echo ""
            read -p "Your choice: " -n 1 choice
            echo ""

            case "$choice" in
                [Nn])
                    create_new_session
                    ;;
                *)
                    exit 0
                    ;;
            esac
        fi

        # Filter out any header or separator lines from selection
        selected=$(echo "$selected" | grep -v "||header||header" | grep -v "||separator||separator" | grep -v "^$")

        # If no valid sessions after filtering, go back to menu
        if [ -z "$selected" ]; then
            continue
        fi

        # Process selected sessions
        show_action_menu "$selected"
    done
}

# Show action menu based on selection
show_action_menu() {
    local selected="$1"
    local count=$(echo "$selected" | wc -l)

    # Determine session types
    local has_running=false
    local has_killed=false

    echo "$selected" | while IFS='|' read -r display name1 name2 status rest; do
        local session_type=$(echo "$rest" | rev | cut -d'|' -f1 | rev)
        if [ "$session_type" = "running" ]; then
            has_running=true
        elif [ "$session_type" = "killed" ]; then
            has_killed=true
        fi
    done

    # Count session types by checking the last field
    local has_running=0
    local has_killed=0

    while IFS='|' read -r line; do
        # Get the last field (session type)
        local type=$(echo "$line" | rev | cut -d'|' -f1 | rev | xargs)
        if [ "$type" = "attached" ] || [ "$type" = "running" ]; then
            has_running=$((has_running + 1))
        elif [ "$type" = "killed" ]; then
            has_killed=$((has_killed + 1))
        fi
    done <<< "$selected"

    echo ""
    echo -e "${BOLD}Selected $count session(s):${NC}"
    echo ""

    # Show which sessions are selected
    echo "$selected" | while IFS='|' read -r display session_name status rest; do
        local session_type=$(echo "$rest" | rev | cut -d'|' -f1 | rev)
        if [ "$session_type" = "attached" ] || [ "$session_type" = "running" ]; then
            echo -e "  ${GREEN}▸${NC} ${CYAN}$session_name${NC} (Running)"
        elif [ "$session_type" = "killed" ]; then
            echo -e "  ${GRAY}▸${NC} ${CYAN}$session_name${NC} (Saved)"
        fi
    done
    echo ""

    # Build action menu based on what's actually selected
    local actions=""

    # Running/Attached sessions
    if [ "$has_running" != "0" ] && [ "$has_killed" = "0" ]; then
        # ONLY running sessions selected
        echo -e "${GREEN}✓ Running sessions selected${NC}"
        echo ""
        actions="${actions}[A] Attach to session(s)\n"
        actions="${actions}[K] Kill session(s) (saves them)\n"
    # Killed sessions
    elif [ "$has_killed" != "0" ] && [ "$has_running" = "0" ]; then
        # ONLY killed sessions selected
        echo -e "${GRAY}💀 Saved sessions selected${NC}"
        echo ""
        actions="${actions}[R] Resurrect session(s)\n"
        actions="${actions}[D] Permanently delete session(s)\n"
    # Mixed selection
    elif [ "$has_running" != "0" ] && [ "$has_killed" != "0" ]; then
        # Mixed - both running and killed
        echo -e "${YELLOW}⚠️  Mixed selection (running + saved)${NC}"
        echo ""
        actions="${actions}[A] Attach to running session(s)\n"
        actions="${actions}[K] Kill running session(s)\n"
        actions="${actions}[R] Resurrect saved session(s)\n"
        actions="${actions}[D] Delete saved session(s)\n"
    fi

    actions="${actions}[N] Create new session\n"
    actions="${actions}[C] Cancel"

    echo -e "$actions"
    echo ""
    read -p "Your choice: " -n 1 action
    echo ""

    case "$action" in
        [Aa])
            attach_sessions "$selected"
            ;;
        [Kk])
            kill_sessions "$selected"
            ;;
        [Rr])
            resurrect_sessions "$selected"
            ;;
        [Dd])
            delete_sessions "$selected"
            ;;
        [Nn])
            create_new_session
            ;;
        *)
            return
            ;;
    esac
}

# Attach to selected sessions
attach_sessions() {
    local selected="$1"
    local running_sessions=$(echo "$selected" | grep "|running$" || true)

    if [ -z "$running_sessions" ]; then
        echo -e "${RED}No running sessions selected${NC}"
        sleep 2
        return
    fi

    local count=$(echo "$running_sessions" | wc -l)

    if [ "$count" -eq 1 ]; then
        # Single session - attach directly
        local session_name=$(echo "$running_sessions" | cut -d'|' -f2)
        session_name=$(echo "$session_name" | xargs)
        echo -e "${GREEN}Attaching to: $session_name${NC}"
        tmux attach -t "$session_name"
    else
        # Multiple sessions - open in tabs (if iTerm) or attach to first
        if [[ "${TERM_PROGRAM:-}" == "iTerm.app" ]]; then
            echo -e "${GREEN}Opening $count sessions in new tabs...${NC}"
            echo "$running_sessions" | while IFS='|' read -r display session_name rest; do
                session_name=$(echo "$session_name" | xargs)
                osascript <<EOF
tell application "iTerm"
    tell current window
        create tab with default profile command "tmux attach -t $session_name"
    end tell
end tell
EOF
            done
            sleep 1
        else
            # Attach to first session only
            local session_name=$(echo "$running_sessions" | head -1 | cut -d'|' -f2)
            session_name=$(echo "$session_name" | xargs)
            echo -e "${YELLOW}Multiple attach only works in iTerm2${NC}"
            echo -e "${GREEN}Attaching to first: $session_name${NC}"
            tmux attach -t "$session_name"
        fi
    fi
}

# Kill selected sessions
kill_sessions() {
    local selected="$1"
    local running_sessions=$(echo "$selected" | grep "|running$" || true)

    if [ -z "$running_sessions" ]; then
        echo -e "${RED}No running sessions selected${NC}"
        sleep 2
        return
    fi

    echo "$running_sessions" | while IFS='|' read -r display session_name rest; do
        session_name=$(echo "$session_name" | xargs)
        echo -e "${YELLOW}Saving and killing: $session_name${NC}"
        save_session_state "$session_name"
        tmux kill-session -t "$session_name" 2>/dev/null || true
    done

    echo -e "${GREEN}✓ Sessions killed and saved${NC}"
    sleep 2
}

# Resurrect selected sessions
resurrect_sessions() {
    local selected="$1"
    local killed_sessions=$(echo "$selected" | grep "|killed$" || true)

    if [ -z "$killed_sessions" ]; then
        echo -e "${RED}No killed sessions selected${NC}"
        sleep 2
        return
    fi

    # For now, just resurrect the first one
    local session_name=$(echo "$killed_sessions" | head -1 | cut -d'|' -f2)
    session_name=$(echo "$session_name" | xargs)
    resurrect_session "$session_name"
}

# Delete selected sessions permanently
delete_sessions() {
    local selected="$1"
    local killed_sessions=$(echo "$selected" | grep "|killed$" || true)

    if [ -z "$killed_sessions" ]; then
        echo -e "${RED}No killed sessions selected${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${RED}⚠️  This will permanently delete the session state files!${NC}"
    read -p "Are you sure? [y/N]: " -n 1 confirm
    echo ""

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    echo "$killed_sessions" | while IFS='|' read -r display session_name rest; do
        session_name=$(echo "$session_name" | xargs)
        delete_session_state "$session_name"
    done

    echo -e "${GREEN}✓ Sessions permanently deleted${NC}"
    sleep 2
}

# Create a new session with file picker
create_new_session() {
    echo ""
    echo -e "${BLUE}Select project folder for new session${NC}"
    echo ""

    # Use file picker to select project folder
    local project_path=$("$SCRIPT_DIR/file-picker.sh" folder)

    if [ -z "$project_path" ]; then
        echo -e "${YELLOW}No folder selected, cancelled${NC}"
        sleep 1
        return
    fi

    if [ ! -d "$project_path" ]; then
        echo -e "${RED}Error: Not a valid directory${NC}"
        sleep 2
        return
    fi

    echo -e "${GREEN}Selected: $project_path${NC}"

    # Export the path and delegate to main session creation script
    export SELECTED_PROJECT_PATH="$project_path"
    exec "$SCRIPT_DIR/start-multi-agent-session-v2.sh"
}

# Main entry point
main() {
    check_fzf
    show_visual_interface
}

main "$@"
