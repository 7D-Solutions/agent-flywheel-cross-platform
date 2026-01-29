#!/usr/bin/env bash
# Start multi-project agent flywheel with tabs for different projects

SESSION="flywheel"

# Kill existing session if not currently in it
CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null || echo "")
if tmux has-session -t $SESSION 2>/dev/null; then
    if [ "$CURRENT_SESSION" = "$SESSION" ]; then
        echo "⚠️  You are currently in the '$SESSION' session."
        echo "   Please exit first, then run this script again."
        exit 1
    else
        echo "🔄 Killing existing '$SESSION' session..."
        tmux kill-session -t $SESSION
    fi
fi

# Create new session with first window for Fireproof
echo "🚀 Creating flywheel session..."
tmux new-session -d -s $SESSION -c "$HOME/Projects/Fireproof"
tmux rename-window -t $SESSION:0 "Fireproof"

# Split into 2 panes (side by side)
tmux split-window -h -t $SESSION:0 -c "$HOME/Projects/Fireproof"

# Set pane titles
tmux select-pane -t $SESSION:0.0 -T "Fireproof-1"
tmux select-pane -t $SESSION:0.1 -T "Fireproof-2"

# Start Claude in each pane
tmux send-keys -t $SESSION:0.0 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION:0.1 "claude --dangerously-skip-permissions" C-m

# Window 2: TrashTech
tmux new-window -t $SESSION:1 -n "TrashTech" -c "$HOME/Projects/Fireproof/TrashTech"

# Split into 2 panes
tmux split-window -h -t $SESSION:1 -c "$HOME/Projects/Fireproof/TrashTech"

# Set pane titles
tmux select-pane -t $SESSION:1.0 -T "TrashTech-1"
tmux select-pane -t $SESSION:1.1 -T "TrashTech-2"

# Start Claude in each pane
tmux send-keys -t $SESSION:1.0 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION:1.1 "claude --dangerously-skip-permissions" C-m

# Window 3: 7D Solutions Modules
tmux new-window -t $SESSION:2 -n "7D-Solutions" -c "$HOME/Projects/7D-Solutions Modules"

# Create 2x2 grid for 3 panes
tmux split-window -h -t $SESSION:2 -c "$HOME/Projects/7D-Solutions Modules"
tmux split-window -v -t $SESSION:2.0 -c "$HOME/Projects/7D-Solutions Modules"

# Set pane titles
tmux select-pane -t $SESSION:2.0 -T "7D-1"
tmux select-pane -t $SESSION:2.1 -T "7D-2"
tmux select-pane -t $SESSION:2.2 -T "7D-3"

# Start Claude in each pane
tmux send-keys -t $SESSION:2.0 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION:2.1 "claude --dangerously-skip-permissions" C-m
tmux send-keys -t $SESSION:2.2 "claude --dangerously-skip-permissions" C-m

# Apply tmux configuration for green pane titles
tmux set -g pane-border-status top
tmux set -g pane-border-format "#{?pane_title,#[fg=green]#{pane_title},#[fg=yellow]#{pane_index}}"
tmux set -g mouse on
tmux set -g history-limit 50000

# Select first window
tmux select-window -t $SESSION:0
tmux select-pane -t $SESSION:0.0

echo "✅ Multi-project flywheel session created!"
echo ""
echo "📋 Windows:"
echo "   0: Fireproof (2 agents)"
echo "   1: TrashTech (2 agents)"
echo "   2: 7D-Solutions (3 agents)"
echo ""
echo "🔗 Attach with: tmux attach -t flywheel"
echo ""

# Attach to session
tmux attach -t $SESSION
