#!/bin/bash
# Test hook security from any project directory
# Usage: Run this from any known project directory to test hook behavior

PROJECT_ROOT=$(pwd)
echo "Testing hooks from: $PROJECT_ROOT"
echo

echo "✓ Running from: $PROJECT_ROOT"
echo
echo "To test hooks, start a Claude session here and have the agent run these tests:"
echo
# Use parent directory for cross-project tests (wherever this project is located)
PARENT_DIR="$(dirname "$PROJECT_ROOT")"
OTHER_PROJECT_DIR="$PARENT_DIR/other-project-example"

echo "TEST 1: Read from current project (should work)"
echo "  Read(\"$PROJECT_ROOT/README.md\")"
echo
echo "TEST 2: Write to current project (should work)"
echo "  Write(\"$PROJECT_ROOT/test-hook.txt\", \"test\")"
echo
echo "TEST 3: Read from sibling project (should work)"
echo "  Read(\"$OTHER_PROJECT_DIR/[some-file]\")"
echo "  (Note: Create $OTHER_PROJECT_DIR first if testing cross-project access)"
echo
echo "TEST 4: Write to sibling project (should be BLOCKED)"
echo "  Write(\"$OTHER_PROJECT_DIR/test.txt\", \"test\")"
echo "  (Note: This tests that hooks prevent writing outside current project)"
echo
