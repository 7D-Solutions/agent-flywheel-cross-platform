#!/bin/bash
# Agent-Flywheel Cross-Platform Installer
# One-command setup for multi-agent coding workflows

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}${BOLD}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Agent-Flywheel Cross-Platform Installer                 ║"
echo "║   Production-ready multi-agent coding system              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)
echo -e "${BLUE}Detected platform: ${BOLD}$PLATFORM${NC}\n"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: Do not run this script as root${NC}"
   exit 1
fi

echo -e "${BOLD}Step 1: Checking dependencies${NC}"

# Check and install dependencies
MISSING_DEPS=()
check_dependency() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_DEPS+=("$pkg")
    else
        echo -e "${GREEN}✓${NC} $cmd"
    fi
}

check_dependency "tmux" "tmux"
check_dependency "jq" "jq"
check_dependency "docker" "docker"
check_dependency "python3" "python3"
check_dependency "git" "git"
check_dependency "curl" "curl"

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo -e "${YELLOW}Would you like to install them now? [y/N]${NC} "
    read -r INSTALL_DEPS

    if [[ "$INSTALL_DEPS" =~ ^[Yy]$ ]]; then
        case $PLATFORM in
            macos)
                if ! command -v brew &> /dev/null; then
                    echo -e "${YELLOW}Installing Homebrew...${NC}"
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                fi
                echo -e "${BLUE}Installing dependencies via Homebrew...${NC}"
                brew install "${MISSING_DEPS[@]}"
                ;;
            linux|wsl)
                echo -e "${BLUE}Installing dependencies via apt...${NC}"
                sudo apt update
                sudo apt install -y "${MISSING_DEPS[@]}"
                ;;
            *)
                echo -e "${RED}Platform not supported for auto-install${NC}"
                echo "Please install manually: ${MISSING_DEPS[*]}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Please install dependencies manually and re-run installer${NC}"
        exit 1
    fi
fi

echo -e "\n${BOLD}Step 2: Checking MCP Agent Mail${NC}"

MCP_DIR="${MCP_AGENT_MAIL_DIR:-$HOME/mcp_agent_mail}"

if [ -d "$MCP_DIR" ]; then
    echo -e "${GREEN}✓${NC} MCP Agent Mail found at $MCP_DIR"
else
    echo -e "${YELLOW}MCP Agent Mail not found${NC}"
    echo -e "${YELLOW}Clone it now? [Y/n]${NC} "
    read -r CLONE_MCP
    CLONE_MCP=${CLONE_MCP:-Y}

    if [[ "$CLONE_MCP" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Cloning MCP Agent Mail...${NC}"
        git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git "$MCP_DIR"
        echo -e "${GREEN}✓${NC} MCP Agent Mail cloned"
    else
        echo -e "${YELLOW}Warning: MCP Agent Mail is required for agent coordination${NC}"
        echo "You can clone it later: git clone https://github.com/Dicklesworthstone/mcp_agent_mail.git ~/mcp_agent_mail"
    fi
fi

echo -e "\n${BOLD}Step 3: Setting up Python environment${NC}"

# Detect Python bin path
if [[ "$PLATFORM" == "macos" ]]; then
    PYTHON_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PYTHON_BIN="$HOME/Library/Python/$PYTHON_VERSION/bin"
elif [[ "$PLATFORM" == "linux" ]] || [[ "$PLATFORM" == "wsl" ]]; then
    PYTHON_BIN="$HOME/.local/bin"
fi

# Check if Python bin is in PATH
if [[ ":$PATH:" != *":$PYTHON_BIN:"* ]]; then
    echo -e "${YELLOW}Adding $PYTHON_BIN to PATH${NC}"

    # Detect shell
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi

    echo "export PATH=\"$PYTHON_BIN:\$PATH\"" >> "$SHELL_RC"
    echo -e "${GREEN}✓${NC} Added to $SHELL_RC"
    echo -e "${YELLOW}Run: source $SHELL_RC${NC}"
fi

echo -e "\n${BOLD}Step 4: AI Authentication Setup${NC}"
echo ""
echo -e "${BLUE}Choose how to authenticate with AI services:${NC}"
echo ""
echo "  1) ChatGPT Subscription (OAuth)"
echo "  2) OpenAI API Key"
echo "  3) Skip for now"
echo ""
read -p "Enter choice [1-3]: " AUTH_CHOICE

case $AUTH_CHOICE in
    1)
        echo -e "\n${BLUE}Setting up ChatGPT OAuth...${NC}"
        ./scripts/setup-codex-oauth.sh
        echo -e "${GREEN}✓${NC} ChatGPT OAuth configured"
        ;;
    2)
        echo -e "\n${BLUE}Setting up OpenAI API Key...${NC}"
        echo "Create /tmp/openai-key.txt with your API key, then run:"
        echo "  ./scripts/setup-openai-key.sh"
        ;;
    3)
        echo -e "\n${BLUE}Skipping AI authentication${NC}"
        echo "You can set it up later with:"
        echo "  ./scripts/setup-codex-oauth.sh"
        echo "  ./scripts/setup-openai-key.sh"
        ;;
    *)
        echo -e "\n${YELLOW}Invalid choice, skipping AI setup${NC}"
        ;;
esac

echo -e "\n${BOLD}Step 5: Configuring agent-flywheel${NC}"

# Set MCP_AGENT_MAIL_DIR env var
SHELL_RC=$([ "$SHELL" = *"zsh"* ] && echo "$HOME/.zshrc" || echo "$HOME/.bashrc")
if ! grep -q "MCP_AGENT_MAIL_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "export MCP_AGENT_MAIL_DIR=\"$MCP_DIR\"" >> "$SHELL_RC"
    echo -e "${GREEN}✓${NC} Set MCP_AGENT_MAIL_DIR in $SHELL_RC"
fi

echo -e "\n${BOLD}Step 6: Verifying installation${NC}"
./verify-cross-platform.sh || echo -e "${YELLOW}Some checks failed - review output above${NC}"

echo -e "\n${GREEN}${BOLD}✅ Installation complete!${NC}\n"

echo -e "${BOLD}Next steps:${NC}"
echo -e "1. ${BLUE}Reload your shell:${NC} source $SHELL_RC"
echo -e "2. ${BLUE}Start MCP Agent Mail server:${NC} ./scripts/start-mail-server.sh"
echo -e "3. ${BLUE}Launch your first multi-agent session:${NC} ./start"
echo -e "\n${BOLD}Documentation:${NC}"
echo -e "- Quick start: ${BLUE}cat README.md${NC}"
echo -e "- Agent communication: ${BLUE}cat AGENT_MAIL.md${NC}"
echo -e "- Health check: ${BLUE}./scripts/doctor.sh${NC}\n"

echo -e "${GREEN}Happy multi-agent coding!${NC}"
