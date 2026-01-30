#!/usr/bin/env bash
# File Reservation Tool - MCP Agent Mail Integration
# Provides advisory file locking to prevent concurrent edit conflicts
# Usage: ./scripts/reserve-files.sh <action> <files...>

set -euo pipefail

# Source shared project configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/lib/project-config.sh"

# Mail server configuration
MAIL_SERVER="${MAIL_SERVER:-http://127.0.0.1:8765}"
MCP_AGENT_MAIL_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"
TOKEN_FILE="$MCP_AGENT_MAIL_DIR/.env"

# Configuration
PROJECT_KEY="${PROJECT_KEY:-$MAIL_PROJECT_KEY}"
AGENT_NAME="${AGENT_NAME:-}"
DEFAULT_TTL=3600  # 1 hour

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load token
if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${RED}Error: Token file not found at $TOKEN_FILE${NC}"
    echo "Is the MCP Agent Mail server running?"
    exit 1
fi
TOKEN=$(grep HTTP_BEARER_TOKEN "$TOKEN_FILE" | cut -d'=' -f2)

# Get current agent name
get_agent_name() {
    if [ -z "$AGENT_NAME" ]; then
        AGENT_NAME=$("$SCRIPT_DIR/agent-mail-helper.sh" whoami 2>/dev/null || echo "unknown")
    fi
    echo "$AGENT_NAME"
}

# Make MCP API call
mcp_call() {
    local method=$1
    local tool_name=$2
    local arguments=$3

    local payload=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "$method",
  "params": {
    "name": "$tool_name",
    "arguments": $arguments
  },
  "id": $(date +%s)
}
EOF
)

    curl -s -X POST "$MAIL_SERVER/mcp" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

# Make MCP resource call
mcp_resource() {
    local uri=$1

    local payload=$(cat <<EOF
{
  "jsonrpc": "2.0",
  "method": "resources/read",
  "params": {
    "uri": "$uri"
  },
  "id": $(date +%s)
}
EOF
)

    curl -s -X POST "$MAIL_SERVER/mcp" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload"
}

usage() {
    cat <<EOF
File Reservation Tool - Advisory file locking via MCP Agent Mail

USAGE:
    $0 reserve <file-patterns...>   Reserve files (exclusive, ${DEFAULT_TTL}s TTL)
    $0 check <file-patterns...>     Check if files are available
    $0 release [file-patterns...]   Release reservations (all if no patterns)
    $0 list                         List your active reservations
    $0 list-all                     List all active reservations (all agents)
    $0 renew [extend-seconds]       Renew all reservations (default: +${DEFAULT_TTL}s)

EXAMPLES:
    $0 reserve src/app.py           Reserve single file
    $0 reserve 'src/**'             Reserve directory tree
    $0 check 'docs/**'              Check if docs are available
    $0 release src/app.py           Release specific file
    $0 release                      Release all your reservations
    $0 renew 7200                   Extend TTL by 2 hours

ENVIRONMENT:
    PROJECT_KEY    Project path (default: from project config)
    AGENT_NAME     Your agent name (default: from agent-mail-helper)
    BYPASS_RESERVATION  Set to 1 to bypass checks (advisory mode)

NOTE: File reservations are ADVISORY - they prevent conflicts but are not enforced.
      Use BYPASS_RESERVATION=1 for optional enforcement in testing.

EOF
    exit 1
}

# Check if reservation bypass is enabled
check_bypass() {
    if [[ "${BYPASS_RESERVATION:-0}" == "1" ]]; then
        echo -e "${YELLOW}⚠️  Reservation bypass enabled (BYPASS_RESERVATION=1)${NC}"
        return 0  # Bypass active
    fi
    return 1  # No bypass
}

# Reserve files
reserve_files() {
    local paths=("$@")
    if [[ ${#paths[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No file patterns specified${NC}"
        usage
    fi

    local agent=$(get_agent_name)

    # Convert paths array to JSON array
    local paths_json=$(printf '%s\n' "${paths[@]}" | jq -R . | jq -s .)

    # Build arguments JSON
    local args=$(cat <<EOF
{
  "project_key": "$PROJECT_KEY",
  "agent_name": "$agent",
  "paths": $paths_json,
  "ttl_seconds": $DEFAULT_TTL,
  "exclusive": true,
  "reason": "File editing session"
}
EOF
)

    echo "Reserving files for $agent..."
    echo "Patterns: ${paths[*]}"
    echo "TTL: ${DEFAULT_TTL}s"
    echo ""

    local response=$(mcp_call "tools/call" "file_reservation_paths" "$args")

    # Check for errors
    local error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
        echo -e "${RED}Error: $error${NC}"
        exit 1
    fi

    # Parse response - use structuredContent if available, otherwise parse text field
    local result_data
    if echo "$response" | jq -e '.result.structuredContent' >/dev/null 2>&1; then
        result_data=$(echo "$response" | jq -r '.result.structuredContent')
    else
        result_data=$(echo "$response" | jq -r '.result.content[0].text')
    fi

    local granted=$(echo "$result_data" | jq -r '.granted // empty')
    local conflicts=$(echo "$result_data" | jq -r '.conflicts // empty')

    if [ -n "$granted" ] && [ "$granted" != "null" ] && [ "$granted" != "[]" ]; then
        echo -e "${GREEN}✓ Reserved:${NC}"
        echo "$granted" | jq -r '.[] | "  - \(.path_pattern) (ID: \(.id), expires: \(.expires_ts))"'
    fi

    if [ -n "$conflicts" ] && [ "$conflicts" != "null" ] && [ "$conflicts" != "[]" ]; then
        echo -e "${YELLOW}⚠️  Conflicts detected:${NC}"
        echo "$conflicts" | jq -r '.[] | "  - \(.path): held by \(.holders | map(.agent) | join(", "))"'
        echo ""
        echo -e "${YELLOW}Another agent is working on these files. Consider:${NC}"
        echo "  1. Wait for them to release"
        echo "  2. Coordinate via agent mail"
        echo "  3. Work on different files"
        exit 5
    fi
}

# Check if files are available
check_files() {
    local paths=("$@")
    if [[ ${#paths[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No file patterns specified${NC}"
        usage
    fi

    if check_bypass; then
        echo -e "${GREEN}✓ Check bypassed - proceeding${NC}"
        return 0
    fi

    local agent=$(get_agent_name)

    # Convert paths array to JSON array
    local paths_json=$(printf '%s\n' "${paths[@]}" | jq -R . | jq -s .)

    # Build arguments JSON - use shared mode to check without blocking others
    local args=$(cat <<EOF
{
  "project_key": "$PROJECT_KEY",
  "agent_name": "$agent",
  "paths": $paths_json,
  "ttl_seconds": 60,
  "exclusive": false,
  "reason": "Availability check"
}
EOF
)

    echo "Checking availability: ${paths[*]}"

    local response=$(mcp_call "tools/call" "file_reservation_paths" "$args")

    # Parse response
    local result_data
    if echo "$response" | jq -e '.result.structuredContent' >/dev/null 2>&1; then
        result_data=$(echo "$response" | jq -r '.result.structuredContent')
    else
        result_data=$(echo "$response" | jq -r '.result.content[0].text')
    fi

    local conflicts=$(echo "$result_data" | jq -r '.conflicts // empty')

    if [ -n "$conflicts" ] && [ "$conflicts" != "null" ] && [ "$conflicts" != "[]" ]; then
        echo -e "${YELLOW}⚠️  Files are currently reserved:${NC}"
        echo "$conflicts" | jq -r '.[] | "  - \(.path): held by \(.holders | map(.agent) | join(", "))"'

        # Release our temporary check reservation
        release_files "${paths[@]}" >/dev/null 2>&1 || true

        return 1
    else
        echo -e "${GREEN}✓ Files are available${NC}"

        # Release our temporary check reservation
        release_files "${paths[@]}" >/dev/null 2>&1 || true

        return 0
    fi
}

# Release reservations
release_files() {
    local paths=("$@")
    local agent=$(get_agent_name)

    # Build arguments JSON
    local args
    if [[ ${#paths[@]} -eq 0 ]]; then
        echo "Releasing ALL reservations for $agent..."
        args=$(cat <<EOF
{
  "project_key": "$PROJECT_KEY",
  "agent_name": "$agent"
}
EOF
)
    else
        echo "Releasing: ${paths[*]}"
        local paths_json=$(printf '%s\n' "${paths[@]}" | jq -R . | jq -s .)
        args=$(cat <<EOF
{
  "project_key": "$PROJECT_KEY",
  "agent_name": "$agent",
  "paths": $paths_json
}
EOF
)
    fi

    local response=$(mcp_call "tools/call" "release_file_reservations" "$args")

    # Check for errors
    local error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
        echo -e "${RED}Error: $error${NC}"
        exit 1
    fi

    # Parse response
    local result_data
    if echo "$response" | jq -e '.result.structuredContent' >/dev/null 2>&1; then
        result_data=$(echo "$response" | jq -r '.result.structuredContent')
    else
        result_data=$(echo "$response" | jq -r '.result.content[0].text')
    fi

    local released=$(echo "$result_data" | jq -r '.released // 0')
    echo -e "${GREEN}✓ Released $released reservation(s)${NC}"
}

# List active reservations for current agent
list_reservations() {
    local agent=$(get_agent_name)

    # Convert project key to slug for resource URI
    local slug=$(echo "$PROJECT_KEY" | sed 's/^\/\+//' | tr '/' '-' | tr '[:upper:]' '[:lower:]')

    echo "Active reservations for $agent:"
    echo "================================"

    local response=$(mcp_resource "resource://file_reservations/$slug?active_only=true")

    # Check for errors
    local error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
        echo -e "${YELLOW}(No reservations or error: $error)${NC}"
        return 0
    fi

    # Parse and filter for current agent
    local reservations=$(echo "$response" | jq -r '.result.contents[0].text' | \
        jq -r --arg agent "$agent" '[.[] | select(.agent == $agent)]')

    if [ -z "$reservations" ] || [ "$reservations" = "null" ] || [ "$reservations" = "[]" ]; then
        echo "(No active reservations)"
    else
        echo "$reservations" | jq -r '.[] | "  [\(.id)] \(.path_pattern) (exclusive: \(.exclusive), expires: \(.expires_ts))"'
    fi
}

# List all active reservations (all agents)
list_all_reservations() {
    # Convert project key to slug for resource URI
    local slug=$(echo "$PROJECT_KEY" | sed 's/^\/\+//' | tr '/' '-' | tr '[:upper:]' '[:lower:]')

    echo "All active reservations in project:"
    echo "===================================="

    local response=$(mcp_resource "resource://file_reservations/$slug?active_only=true")

    # Check for errors
    local error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
        echo -e "${YELLOW}(No reservations or error: $error)${NC}"
        return 0
    fi

    # Parse all reservations
    local reservations=$(echo "$response" | jq -r '.result.contents[0].text')

    if [ -z "$reservations" ] || [ "$reservations" = "null" ] || [ "$reservations" = "[]" ]; then
        echo "(No active reservations)"
    else
        echo "$reservations" | jq -r '.[] | "  [\(.agent)] \(.path_pattern) (ID: \(.id), exclusive: \(.exclusive), expires: \(.expires_ts))"'
    fi
}

# Renew reservations
renew_reservations() {
    local extend_seconds="${1:-$DEFAULT_TTL}"
    local agent=$(get_agent_name)

    echo "Renewing reservations for $agent, extending by ${extend_seconds}s..."

    # Build arguments JSON (omit file_reservation_ids to renew all)
    local args=$(cat <<EOF
{
  "project_key": "$PROJECT_KEY",
  "agent_name": "$agent",
  "extend_seconds": $extend_seconds
}
EOF
)

    local response=$(mcp_call "tools/call" "renew_file_reservations" "$args")

    # Check for errors
    local error=$(echo "$response" | jq -r '.error.message // empty')
    if [ -n "$error" ]; then
        echo -e "${RED}Error: $error${NC}"
        exit 1
    fi

    # Parse response
    local result_data
    if echo "$response" | jq -e '.result.structuredContent' >/dev/null 2>&1; then
        result_data=$(echo "$response" | jq -r '.result.structuredContent')
    else
        result_data=$(echo "$response" | jq -r '.result.content[0].text')
    fi

    local renewed=$(echo "$result_data" | jq -r '.renewed // 0')
    echo -e "${GREEN}✓ Renewed $renewed reservation(s)${NC}"
}

# Main
main() {
    if [[ $# -eq 0 ]]; then
        usage
    fi

    local action="$1"
    shift

    case "$action" in
        reserve)
            reserve_files "$@"
            ;;
        check)
            check_files "$@"
            ;;
        release)
            release_files "$@"
            ;;
        list)
            list_reservations
            ;;
        list-all)
            list_all_reservations
            ;;
        renew)
            renew_reservations "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Unknown action: $action${NC}"
            usage
            ;;
    esac
}

main "$@"
