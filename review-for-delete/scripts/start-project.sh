#!/usr/bin/env bash
#
# Start agent flywheel for any project
# Usage: ./start-project.sh <project-path> [project-key]
#

if [ -z "$1" ]; then
  echo "Usage: $0 <project-path> [project-key]"
  echo ""
  echo "Examples:"
  echo "  $0 ~/Projects/Fireproof"
  echo "  $0 ~/Projects/my-app my-app"
  echo "  $0 /absolute/path/to/project"
  exit 1
fi

# Set PROJECT_ROOT
export PROJECT_ROOT="$1"

# Set MAIL_PROJECT_KEY (use provided key or default to PROJECT_ROOT)
if [ -n "$2" ]; then
  export MAIL_PROJECT_KEY="$2"
else
  export MAIL_PROJECT_KEY="$PROJECT_ROOT"
fi

# Validate project directory exists
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Error: Project directory does not exist: $PROJECT_ROOT"
  exit 1
fi

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Starting agent flywheel for custom project..."
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "MAIL_PROJECT_KEY: $MAIL_PROJECT_KEY"
echo ""

# Run the main start script
exec "$SCRIPT_DIR/start-flywheel.sh" "${@:3}"
