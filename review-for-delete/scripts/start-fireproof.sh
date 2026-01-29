#!/usr/bin/env bash
#
# Start agent flywheel for the Fireproof project
#

# Set PROJECT_ROOT to Fireproof
export PROJECT_ROOT="$HOME/Projects/Fireproof"
export MAIL_PROJECT_KEY="fireproof"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Starting agent flywheel for Fireproof..."
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "MAIL_PROJECT_KEY: $MAIL_PROJECT_KEY"
echo ""

# Run the main start script
exec "$SCRIPT_DIR/start-flywheel.sh" "$@"
