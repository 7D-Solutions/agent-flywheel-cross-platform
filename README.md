# Agent Flywheel 🎡

> **Run multiple AI agents working together on your projects**
> Super simple. Beautiful interface. Works on Mac & Windows.

![Status: Ready to Use](https://img.shields.io/badge/status-ready-brightgreen)
![Beginner Friendly](https://img.shields.io/badge/beginner-friendly-blue)
![Version 1.1.0](https://img.shields.io/badge/version-1.1.0-blue)

📖 **[Quick Start Guide](QUICKSTART.md)** | 📋 **[Changelog](CHANGELOG.md)** | 🩺 **[Health Check](scripts/doctor.sh)**

---

## ⚡ 3-Step Setup (5 minutes)

### Mac / Linux:

```bash
# 1. Get the code
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel

# 2. Run installer
./install.sh

# 3. Start!
./start
```

### Windows:

```cmd
REM 1. Get the code
git clone https://github.com/7D-Solutions/agent-flywheel-cross-platform.git
cd agent-flywheel

REM 2 & 3. Run the Windows launcher (handles everything!)
start.bat
```

**That's literally it.** 🎉

The Windows launcher will:
- ✅ Check if WSL is installed
- ✅ Offer to install WSL if needed (one-click!)
- ✅ Install Ubuntu automatically
- ✅ Run the installer inside WSL
- ✅ Launch the visual interface

**Just double-click `start.bat` or run it from Command Prompt!**

---

## 🎨 What You Get

A beautiful visual interface to manage your AI agent teams:

```
╭────────────────────────────────────────────╮
│     Agent Flywheel - Session Manager      │
╰────────────────────────────────────────────╯

  🟢 my-app        Running    3 Claude, 1 Codex
  🔵 website       Attached   4 Claude
  💀 old-project   Killed     Jan 30

Tab: Select | Enter: Actions | Ctrl+N: New | Esc: Quit
```

**What you can do:**
- 📁 **Create new session** (Ctrl+N) → 4-step guided workflow
- 🚀 **Attach to sessions** → See your agents working
- 💀 **Kill sessions** → They're saved, bring them back later
- 🔄 **Resurrect old sessions** → One click to restore
- 🗑️ **Delete permanently** → Clean up when done

**Controls:**
- **Ctrl+N** - Create new multi-agent session
- **Enter** - Show actions for selected session(s)
- **Tab** - Select multiple sessions
- **Arrow keys** - Navigate
- **Esc** or **Ctrl+C** - Quit

### Creating a New Session (Ctrl+N)

When you press **Ctrl+N**, you'll go through a simple 4-step guided workflow:

**Step 1/4: Select Project Folder**
- Graphical file picker appears
- Navigate and select your project folder
- Press Enter to confirm

**Step 2/4: Session Name**
- Enter a name for your session (or press Enter to use folder name)
- Automatically checks for conflicts with existing sessions
- Names are sanitized to be tmux-safe

**Step 3/4: Agent Configuration**
- Choose number of Claude agents (default: 2)
- Choose number of Codex agents (default: 0)
- Must have at least 1 agent total

**Step 4/4: Shared Task List** (optional)
- Enable shared task list for agent collaboration
- All agents can see and work on the same tasks
- Or keep individual task lists per agent

**Confirmation Screen**
- Review all your settings
- Press Y to create, N to cancel
- Session starts immediately after confirmation

---

## 🤔 What's This For?

### For New Coders
Get AI help on your projects without complex setup. 4 AI agents work together to:
- Write code
- Fix bugs
- Answer questions
- Help you learn

### For Experienced Devs
Save $400+/month by using ChatGPT subscription instead of API billing. Multi-agent coordination for complex tasks.

---

## 💰 Save Money (Important!)

**Before this tool:**
- $20/day on OpenAI API
- $600/month 😰

**After:**
- Use ChatGPT subscription
- ~$200/month ✅
- **Save $400/month!**

**How:** During install, choose **"ChatGPT OAuth"** option.

---

## 🎯 Common Tasks

### Start Your First Project
```bash
./start
```
Press **N** → Pick your project folder → Done!

### Check on Your Agents
```bash
./start
```
Select a session → Press **A** → See them working!

### Take a Break (Keep Agents Working)
Inside a session, press:
**Ctrl+b** then **d**

Agents keep running in background. Come back anytime!

### Stop for the Day
```bash
./start
```
Select sessions → Press **K** → They're saved for tomorrow!

### Resume Tomorrow
```bash
./start
```
Select 💀 killed session → Press **R** → Back in action!

---

## 🖥️ Works On

- ✅ **Mac** (Terminal or iTerm2)
- ✅ **Windows** (Command Prompt, PowerShell, or WSL) - Auto-setup!
- ✅ **Linux** (any distro)

### Windows: Super Easy Setup!

**Just run `start.bat` from Command Prompt** - it does everything:

1. Checks if WSL is installed
2. If not → Offers one-click WSL installation
3. Installs Ubuntu automatically
4. Runs the installer inside WSL
5. Launches the visual interface

**No manual WSL setup needed!** The .bat file handles it all.

**Alternative:** Use `start.ps1` for PowerShell users

---

## 🆘 Help!

### "I don't see the visual interface"

When you run `./start`, it asks: **"Install fzf?"**
Press **Y** → Auto-installs → Visual interface appears!

Or manually:
```bash
./setup-fzf.sh
```

### "Permission denied"

```bash
chmod +x start install.sh setup-fzf.sh
./start
```

### "Nothing's happening"

Check what's running:
```bash
./scripts/doctor.sh
```

This shows what's working and what needs fixing.

### "I'm confused"

Just run `./start` and press buttons! You can't break anything - everything's saved automatically.

---

## 🎓 Learn More

**Beginner Guides:**
- [Full Testing Guide](./VISUAL-INTERFACE-GUIDE.md) - Every feature explained
- [Agent Communication](./AGENT_MAIL.md) - How agents talk to each other

**For Devs:**
- See "Advanced Setup" section below

---

## ⌨️ Keyboard Shortcuts

**In the visual interface:**
- ↑↓ - Navigate
- Tab - Select/deselect
- Enter - Open actions
- Ctrl-A - Select all
- Ctrl-D - Deselect all
- Q - Quit

**Inside a session (with 4 agent panes):**
- **Ctrl+b** then **arrow keys** - Switch panes
- **Ctrl+b** then **d** - Detach (go back to menu)
- **Ctrl+b** then **z** - Zoom current pane
- **Ctrl+b** then **q** - Show pane numbers

---

## 📊 Quick Reference

| I Want To... | What I Do |
|--------------|-----------|
| Start first time | `./install.sh` → `./start` |
| Create new session | `./start` → **Ctrl+N** |
| See all sessions | `./start` |
| Work on a project | `./start` → Select → **Enter** → **A** |
| Stop for now | Inside session: **Ctrl+b d** |
| End session (save it) | `./start` → Select → **Enter** → **K** |
| Resume old session | `./start` → Select 💀 → **Enter** → **R** |
| Delete forever | `./start` → Select 💀 → **Enter** → **D** |
| Fix problems | `./scripts/doctor.sh` |

---

## 🌟 Tips for Success

1. **Use iTerm2 on Mac** - Better experience than Terminal.app
2. **Select multiple sessions** - Tab to select, do actions on all at once
3. **Don't delete right away** - Kill sessions first, resurrect if you need them
4. **Detach, don't quit** - Ctrl+b d keeps agents working in background
5. **Run doctor.sh if stuck** - Shows exactly what's wrong

---

## 🚀 Advanced Setup

<details>
<summary>Click to expand detailed setup options</summary>

### Prerequisites

**macOS:**
```bash
brew install tmux jq
```

**Linux/WSL:**
```bash
sudo apt update
sudo apt install -y tmux jq curl python3 python3-pip git
```

### AI Authentication Options

**Option A: ChatGPT OAuth (Recommended)**
```bash
./scripts/setup-codex-oauth.sh
```
- Uses your ChatGPT Plus/Pro subscription
- No extra API costs
- Unlimited usage within subscription limits

**Option B: OpenAI API Key**
```bash
echo "sk-proj-YOUR-KEY" > /tmp/openai-key.txt
./scripts/setup-openai-key.sh
```
- ⚠️ Costs ~$20/day
- Not recommended unless you don't have ChatGPT subscription

### Manual Session Start

```bash
./scripts/start-multi-agent-session-v2.sh
```

### Health Check

```bash
./scripts/doctor.sh
```

Checks:
- System dependencies
- Docker status
- MCP Agent Mail
- Python environment
- Tmux config
- Active sessions
- File permissions
- Network ports

### Platform-Specific Notes

**macOS:**
- Python packages: `~/Library/Python/3.9/bin`
- Shell: zsh (default)
- Best with iTerm2

**Linux/WSL:**
- Python packages: `~/.local/bin`
- Shell: bash (default)
- Use Windows Terminal for WSL

**Windows:**
- Requires WSL or Git Bash
- See [README-SETUP-WSL.md](./README-SETUP-WSL.md)

### File Structure

```
agent-flywheel/
├── start                    # Quick launcher
├── install.sh               # One-command installer
├── setup-fzf.sh             # Visual interface installer
├── scripts/
│   ├── visual-session-manager.sh    # Visual interface (NEW!)
│   ├── file-picker.sh               # Cross-platform file picker (NEW!)
│   ├── start-multi-agent-session-v2.sh
│   ├── doctor.sh            # Health check
│   ├── setup-codex-oauth.sh # ChatGPT OAuth setup (NEW!)
│   └── setup-openai-key.sh  # API key setup
├── .session-state/          # Saved sessions for resurrection
└── VISUAL-INTERFACE-GUIDE.md
```

</details>

---

## 🐛 Troubleshooting

**First, always run:**
```bash
./scripts/doctor.sh
```

This tells you exactly what's wrong and how to fix it.

**Common fixes:**

```bash
# Permission errors
chmod +x start install.sh setup-fzf.sh

# Missing dependencies
./install.sh

# Visual interface not showing
./setup-fzf.sh

# Session conflicts
./start  # Then press K to kill old sessions

# Python package issues
./scripts/doctor.sh  # Shows the fix
```

---

## 🎯 Philosophy

This tool is designed to be **stupid simple** for beginners:

1. **One command to install** - `./install.sh`
2. **One command to run** - `./start`
3. **Visual interface** - No typing commands
4. **Can't break it** - Everything's saved automatically
5. **Get unstuck fast** - `./scripts/doctor.sh` shows fixes

If you're confused, just run `./start` and press buttons. That's it!

---

## ❤️ You Got This!

New to coding? **Perfect.** This tool is for you.

Experienced dev? **Great.** Save $400/month on AI costs.

**Just run `./start` and explore!** 🚀

---

## 📝 License

MIT License - Use it however you want!

---

## 🙋 Need Help?

1. Run `./scripts/doctor.sh` - Shows what's wrong
2. Check [VISUAL-INTERFACE-GUIDE.md](./VISUAL-INTERFACE-GUIDE.md) - Full guide
3. Read error messages - They tell you what to do
4. Try `./start` again - Often just works™

**Remember:** You can't break anything. Sessions are auto-saved. Just explore! 🌟
