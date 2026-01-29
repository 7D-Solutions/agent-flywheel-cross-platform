#!/bin/bash
# Add Python user bin to PATH so aider works

# Detect Python bin directory (macOS vs Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    PYTHON_BIN="$HOME/Library/Python/3.9/bin"
else
    PYTHON_BIN="$HOME/.local/bin"
fi

# Detect shell RC file
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bash_profile"
fi

# Check if already added
if grep -q "$PYTHON_BIN" "$SHELL_RC" 2>/dev/null; then
    echo "✓ Python bin already in PATH"
else
    echo "" >> "$SHELL_RC"
    echo "# Python user bin directory (added $(date '+%Y-%m-%d'))" >> "$SHELL_RC"
    echo "export PATH=\"$PYTHON_BIN:\$PATH\"" >> "$SHELL_RC"
    echo "✓ Added Python bin to PATH in $SHELL_RC"
fi

# Apply to current shell
export PATH="$PYTHON_BIN:$PATH"
echo "✓ PATH updated for current shell"

# Test aider
if command -v aider &> /dev/null; then
    echo "✓ aider is now available!"
    echo ""
    echo "Run: source $SHELL_RC"
    echo "Then: aider --yes-always"
else
    echo "✗ aider still not found. Check installation."
fi
