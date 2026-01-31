#!/bin/bash
# Setup script to install fzf for visual session manager

set -e

echo "════════════════════════════════════════════════"
echo "  Installing fzf for Visual Session Manager"
echo "════════════════════════════════════════════════"
echo ""

# Check if already installed
if command -v fzf &> /dev/null; then
    echo "✓ fzf is already installed!"
    fzf --version
    echo ""
    echo "You're all set! Run ./start to use the visual interface."
    exit 0
fi

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo "Detected: macOS"
    echo ""

    # Check for Homebrew
    if command -v brew &> /dev/null; then
        echo "Installing fzf via Homebrew..."
        brew install fzf

        echo ""
        echo "✓ fzf installed successfully!"
        fzf --version

    else
        echo "Homebrew not found. Installing fzf manually..."
        echo ""

        # Manual installation
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all

        echo ""
        echo "✓ fzf installed successfully!"
        echo ""
        echo "⚠️  You may need to restart your terminal for fzf to be available."
    fi

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo "Detected: Linux"
    echo ""

    if command -v apt-get &> /dev/null; then
        echo "Installing fzf via apt..."
        sudo apt-get update
        sudo apt-get install -y fzf
    elif command -v yum &> /dev/null; then
        echo "Installing fzf via yum..."
        sudo yum install -y fzf
    else
        echo "Installing fzf manually..."
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
    fi

    echo ""
    echo "✓ fzf installed successfully!"

elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Detected: Windows"
    echo ""

    if command -v scoop &> /dev/null; then
        echo "Installing fzf via scoop..."
        scoop install fzf
    elif command -v choco &> /dev/null; then
        echo "Installing fzf via chocolatey..."
        choco install fzf -y
    else
        echo "Please install fzf manually:"
        echo ""
        echo "Option 1 - Using scoop:"
        echo "  scoop install fzf"
        echo ""
        echo "Option 2 - Using chocolatey:"
        echo "  choco install fzf"
        echo ""
        echo "Option 3 - Download from:"
        echo "  https://github.com/junegunn/fzf/releases"
        exit 1
    fi

    echo ""
    echo "✓ fzf installed successfully!"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════"
echo ""
echo "Run: ./start"
echo ""
echo "You'll see the beautiful visual session manager! 🎨"
