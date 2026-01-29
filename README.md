# Agent-Flywheel Cross-Platform

A cross-platform version of agent-flywheel that works on both macOS and Linux (including WSL).

## Overview

This is a standalone cross-platform version of the agent-flywheel multi-agent system. It has been modified to work seamlessly on:
- macOS (Intel and Apple Silicon)
- Linux (Ubuntu, Debian, etc.)
- Windows Subsystem for Linux (WSL)

## Key Differences from Original

This version fixes three critical compatibility issues:

1. **Dynamic path detection** - No hardcoded `/Users/james` paths
2. **Cross-platform sed** - Uses `tr` instead of macOS-specific `sed -E`
3. **Platform-aware Python paths** - Detects macOS vs Linux Python bin locations
4. **Shell detection** - Works with both bash and zsh

## Prerequisites

### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install tmux jq
```

### Linux/WSL
```bash
# Update package list
sudo apt update

# Install dependencies
sudo apt install -y tmux jq curl python3 python3-pip git
```

## Quick Start

### 1. Clone or Copy This Repository

```bash
# Clone to ANY directory you prefer (no specific structure required):
git clone <repo-url> agent-flywheel-cross-platform
cd agent-flywheel-cross-platform

# Or if copying from existing installation:
cp -r /path/to/agent-flywheel-cross-platform /your/preferred/location/
cd /your/preferred/location/agent-flywheel-cross-platform
```

The scripts will work from any location - there's no requirement for a `~/Projects` directory or any specific folder structure.

### 2. Set Up OpenAI API Key (Optional)

If you want to use AI-powered agents like aider:

```bash
# Create a temporary file with your OpenAI key
echo "sk-proj-YOUR-KEY-HERE" > /tmp/openai-key.txt

# Run the setup script (from wherever you saved the project)
cd /path/to/agent-flywheel-cross-platform
./scripts/setup-openai-key.sh

# The script will:
# - Validate your key
# - Add it to your shell config
# - Set up Python paths
# - Securely delete the temp file
```

### 3. Start a Multi-Agent Session

```bash
cd /path/to/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
```

The script will:
- Prompt you for a session name (default: `flywheel`)
- Prompt you for a project path (defaults to current directory)
- Create a tmux session with multiple panes
- Set up agent communication infrastructure
- Launch your configured agents

### 4. Navigate the Session

Inside tmux:
- `Ctrl+b then arrow keys` - Switch between panes
- `Ctrl+b d` - Detach from session (keeps running)
- `tmux attach -t <session-name>` - Reattach to session
- `Ctrl+b :kill-session` - End session

## Configuration

### Project Configuration

The system automatically creates `scripts/lib/project-config.sh` when needed. You can customize:

- Session name
- Agent panes to launch
- Default commands per pane
- Working directory layout

### Agent Communication

See [AGENT_MAIL.md](./AGENT_MAIL.md) for commands to send messages between agents.

## Platform-Specific Notes

### macOS
- Python packages install to `~/Library/Python/3.9/bin`
- Uses `zsh` by default (can detect bash)
- Native tmux support

### Linux/WSL
- Python packages install to `~/.local/bin`
- Uses `bash` by default (can detect zsh)
- Make sure Windows Terminal is set up for best WSL experience
- WSL-specific setup guide: [README-SETUP-WSL.md](./README-SETUP-WSL.md)

## File Structure

```
agent-flywheel-cross-platform/
├── scripts/
│   ├── start-multi-agent-session.sh    # Main launcher (cross-platform)
│   ├── setup-openai-key.sh             # API key setup (cross-platform)
│   ├── add-aider-to-path.sh            # PATH helper (cross-platform)
│   ├── agent-mail-helper.sh            # Inter-agent messaging
│   ├── auto-register-agent.sh          # Agent registration
│   └── lib/
│       └── project-config.sh           # Project-specific config
├── panes/
│   └── *.sh                            # Pane startup scripts
├── .tmux.conf.agent-flywheel           # tmux configuration
├── AGENT_MAIL.md                       # Communication guide
└── README-SETUP-WSL.md                 # WSL-specific setup
```

## Troubleshooting

### "Command not found: aider"

```bash
# Add Python bin to PATH
./scripts/add-aider-to-path.sh

# Then reload your shell
source ~/.zshrc  # or source ~/.bashrc on Linux
```

### "Session already exists"

```bash
# List existing sessions
tmux list-sessions

# Kill old session
tmux kill-session -t flywheel

# Or attach to it
tmux attach -t flywheel
```

### Python packages not found on Linux

```bash
# Make sure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### WSL-specific issues

See [README-SETUP-WSL.md](./README-SETUP-WSL.md) for detailed WSL troubleshooting.

## Testing

### Test on macOS
```bash
cd /path/to/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
# Should work without errors
```

### Test on Linux/WSL
```bash
cd /path/to/agent-flywheel-cross-platform
./scripts/start-multi-agent-session.sh
# Should work without errors
```

## Contributing

This is a cross-platform fork designed for maximum compatibility. When making changes:

1. Test on both macOS and Linux if possible
2. Avoid platform-specific commands (use conditionals)
3. Use `$OSTYPE` for platform detection
4. Use portable shell constructs (POSIX when possible)

## License

Same as original agent-flywheel project.

## Support

For issues:
- WSL-specific: See [README-SETUP-WSL.md](./README-SETUP-WSL.md)
- General: Check original agent-flywheel documentation
- Agent communication: See [AGENT_MAIL.md](./AGENT_MAIL.md)
