#!/bin/bash
# Verification script for cross-platform fixes

echo "=== Agent-Flywheel Cross-Platform Verification ==="
echo ""

PASS=0
FAIL=0

# Check 1: sed fix
echo -n "1. Checking sed fix (tr instead of sed -E)... "
if grep -q "tr -cs 'A-Za-z0-9_-' '_'" scripts/start-multi-agent-session.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 2: Dynamic path detection
echo -n "2. Checking dynamic path (no hardcoded /Users/james)... "
if grep -q 'AGENT_FLYWHEEL_ROOT="$(dirname "$SCRIPT_DIR")"' scripts/start-multi-agent-session.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 3: No hardcoded paths in SOURCE_CONFIG
echo -n "3. Checking no hardcoded paths in SOURCE_CONFIG... "
if ! grep -q "/Users/james" scripts/start-multi-agent-session.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (found hardcoded /Users/james path)"
    ((FAIL++))
fi

# Check 4: Platform detection in setup-openai-key.sh
echo -n "4. Checking platform detection in setup-openai-key.sh... "
if grep -q 'if \[\[ "$OSTYPE" == "darwin"\* \]\]; then' scripts/setup-openai-key.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 5: Platform detection in add-aider-to-path.sh
echo -n "5. Checking platform detection in add-aider-to-path.sh... "
if grep -q 'if \[\[ "$OSTYPE" == "darwin"\* \]\]; then' scripts/add-aider-to-path.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 6: Shell detection
echo -n "6. Checking shell detection (bash/zsh)... "
if grep -q 'if \[ -f "$HOME/.zshrc" \]; then' scripts/setup-openai-key.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 7: PYTHON_BIN variable usage
echo -n "7. Checking PYTHON_BIN variable usage... "
if grep -q 'PYTHON_BIN=' scripts/setup-openai-key.sh && grep -q 'PYTHON_BIN=' scripts/add-aider-to-path.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 8: Essential files exist
echo -n "8. Checking essential files exist... "
if [ -f "README.md" ] && [ -f "CHANGES.md" ] && [ -f ".tmux.conf.agent-flywheel" ] && [ -f "AGENT_MAIL.md" ]; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 9: Syntax validation
echo -n "9. Checking bash syntax... "
if bash -n scripts/start-multi-agent-session.sh 2>/dev/null && \
   bash -n scripts/setup-openai-key.sh 2>/dev/null && \
   bash -n scripts/add-aider-to-path.sh 2>/dev/null; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL"
    ((FAIL++))
fi

# Check 10: Script permissions
echo -n "10. Checking script permissions... "
if [ -x "scripts/start-multi-agent-session.sh" ] && \
   [ -x "scripts/setup-openai-key.sh" ] && \
   [ -x "scripts/add-aider-to-path.sh" ]; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "⚠ WARNING (scripts not executable - run: chmod +x scripts/*.sh)"
    # Don't count as fail, just a warning
fi

# Check 11: No hardcoded paths in tmux hooks
echo -n "11. Checking tmux hooks use dynamic paths... "
if ! grep -q 'Projects/agent-flywheel"' scripts/start-multi-agent-session.sh 2>/dev/null && \
   grep -q 'AGENT_FLYWHEEL_ROOT' scripts/start-multi-agent-session.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (tmux hooks have hardcoded paths)"
    ((FAIL++))
fi

# Check 12: cleanup-after-pane-removal.sh uses dynamic paths
echo -n "12. Checking cleanup-after-pane-removal.sh... "
if ! grep -q '/Users/james' scripts/cleanup-after-pane-removal.sh 2>/dev/null && \
   grep -q 'AGENT_FLYWHEEL_ROOT' scripts/cleanup-after-pane-removal.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (has hardcoded paths)"
    ((FAIL++))
fi

# Check 13: agent-mail-helper.sh uses dynamic paths
echo -n "13. Checking agent-mail-helper.sh... "
if ! grep -q 'Projects/agent-flywheel"' scripts/agent-mail-helper.sh 2>/dev/null && \
   grep -q 'AGENT_FLYWHEEL_ROOT' scripts/agent-mail-helper.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (has hardcoded paths)"
    ((FAIL++))
fi

# Check 14: setup-openai-key.sh uses $SHELL_RC not hardcoded .zshrc
echo -n "14. Checking setup-openai-key.sh uses \$SHELL_RC... "
if ! grep -q 'source ~/.zshrc"' scripts/setup-openai-key.sh 2>/dev/null && \
   grep -q 'source \$SHELL_RC' scripts/setup-openai-key.sh; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (still has hardcoded .zshrc reference)"
    ((FAIL++))
fi

# Check 15: AGENT_FLYWHEEL_ROOT defined early in main script
echo -n "15. Checking AGENT_FLYWHEEL_ROOT defined at top... "
if head -20 scripts/start-multi-agent-session.sh | grep -q 'AGENT_FLYWHEEL_ROOT'; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (should be defined near top of script)"
    ((FAIL++))
fi

# Check 16: No hardcoded paths in .tmux.conf.agent-flywheel
echo -n "16. Checking .tmux.conf.agent-flywheel has no hardcoded paths... "
if ! grep -q "Projects/agent-flywheel" .tmux.conf.agent-flywheel 2>/dev/null; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (tmux config has hardcoded paths)"
    ((FAIL++))
fi

# Check 17: No stray temp files
echo -n "17. Checking for temp files (*.tmp, *.bak)... "
TEMP_FILES=$(find scripts/ -name "*.tmp" -o -name "*.bak" 2>/dev/null | wc -l)
if [ "$TEMP_FILES" -eq 0 ]; then
    echo "✓ PASS"
    ((PASS++))
else
    echo "✗ FAIL (found $TEMP_FILES temp file(s) - should be removed)"
    find scripts/ -name "*.tmp" -o -name "*.bak" 2>/dev/null | sed 's/^/  /'
    ((FAIL++))
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✓ All checks passed! Cross-platform version is ready."
    echo ""
    echo "Test on macOS:"
    echo "  cd /path/to/agent-flywheel-cross-platform"
    echo "  ./scripts/start-multi-agent-session.sh"
    echo ""
    echo "Test on WSL:"
    echo "  sudo apt install -y tmux jq curl python3 git"
    echo "  cd /path/to/agent-flywheel-cross-platform"
    echo "  ./scripts/start-multi-agent-session.sh"
    exit 0
else
    echo "✗ Some checks failed. Review the output above."
    exit 1
fi
