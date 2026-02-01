# Visual Session Manager - Testing Guide

## ✅ Pre-Flight Checks Complete

All scripts passed syntax validation:
- ✓ visual-session-manager.sh
- ✓ file-picker.sh
- ✓ start script
- ✓ start-multi-agent-session-v2.sh

## 📦 Installation

### Step 1: Install fzf

**Mac:**
```bash
brew install fzf
```

**Windows (WSL/Git Bash):**
```bash
# Using scoop
scoop install fzf

# OR using chocolatey
choco install fzf
```

### Step 2: Verify Installation

```bash
fzf --version
```

You should see something like: `0.46.0` or higher

## 🧪 Testing Scenarios

### Scenario 1: First Time Launch (No Sessions)

**Run:**
```bash
cd /Users/james/Projects/agent-flywheel-cross-platform
./start
```

**Expected:**
1. iTerm2 selection prompt appears (if not in iTerm)
2. Visual interface launches
3. Shows: "No sessions found (running or killed)"
4. Press `Ctrl+N` to create new session or `Esc` to quit

**Test Action:** Press `Ctrl+N`

**Expected - 4-Step Workflow:**

**Step 1/4: Select Project Folder**
- Native file picker opens
- Navigate and select your project folder
- Press Enter to confirm

**Step 2/4: Session Name**
- Prompt: "Session name (or press Enter for '[folder-name]'):"
- Type a name or press Enter for default
- System checks for name conflicts
- If conflict exists, prompts to choose different name

**Step 3/4: Agent Configuration**
- Prompt: "Number of Claude agents (press Enter for 2):"
- Type number or press Enter for default
- Prompt: "Number of Codex agents (press Enter for 0):"
- Type number or press Enter for default
- Must have at least 1 agent total

**Step 4/4: Shared Task List**
- Prompt: "Enable shared task list? [y/N]:"
- If yes: "Task list ID (press Enter for '[session-name]-tasks'):"
- Shows whether agents will collaborate or work independently

**Confirmation Screen**
- Shows all your choices:
  - Session name
  - Project path
  - Agent counts
  - Task list configuration
- Prompt: "Create session? [Y/n]:"
- Press Y or Enter to create, N to cancel
- Session creates and you're attached automatically

---

### Scenario 2: Multiple Running Sessions

**Setup:**
Create 2-3 sessions first using the tool.

**Run:**
```bash
./start
```

**Expected Visual Interface:**
```
╭─────────────────────────────────────────────────╮
│      Agent Flywheel - Session Manager          │
╰─────────────────────────────────────────────────╯

  🟢 session-1    Running   3 Claude, 1 Codex
  🟢 session-2    Running   4 Claude
  🟢 session-3    Running   2 Claude

Tab: Select Multiple | Enter: Actions | Ctrl+N: New | Esc: Quit
```

**Test Actions:**

1. **Navigate with Arrow Keys**
   - ↑ and ↓ should move the cursor

2. **Multi-Select**
   - Press `Tab` to select first session (should show `✓`)
   - Press `Tab` again on another session
   - Both should be marked

3. **Select All**
   - Press `Ctrl-A` (all sessions selected)

4. **Deselect All**
   - Press `Ctrl-D` (all deselected)

5. **Open Action Menu**
   - Select 1-2 sessions with `Tab`
   - Press `Enter`

**Expected Action Menu:**
```
Selected 2 session(s)

Choose an action:
- Attach to session(s)
- Kill session(s)
- Cancel

Arrow keys to navigate, Enter to select
```

**Note:** Create new session is now `Ctrl+N` from the main interface, not in action menu.

---

### Scenario 3: Attach to Single Session

**Action:**
1. Select one session with arrow keys
2. Press `Enter` to open action menu
3. Select "Attach" and press Enter

**Expected:**
- Attaches to the tmux session directly
- You see the multi-agent panes
- Detach with `Ctrl+b d`
- Returns to visual interface automatically

---

### Scenario 4: Attach to Multiple Sessions (iTerm2 only)

**Action:**
1. Select 2-3 sessions with `Tab`
2. Press `Enter` to open action menu
3. Select "Attach" and press Enter

**Expected:**
- Message: "Opening 3 sessions in new tabs..."
- Each session opens in a new iTerm tab
- You can switch between tabs to see each session

---

### Scenario 5: Kill Sessions (with Resurrection)

**Action:**
1. Select 1-2 sessions with `Tab`
2. Press `Enter` to open action menu
3. Select "Kill" and press Enter

**Expected:**
- Messages: "Saving and killing: session-1"
- "✓ Saved session state: session-1"
- "✓ Sessions killed and saved"
- Returns to visual interface
- Killed sessions now show with 💀 icon

---

### Scenario 6: Resurrect Killed Session

**Prerequisites:** Must have killed a session first (Scenario 5)

**Action:**
1. Select a killed session (💀 icon)
2. Press `Enter` to open action menu
3. Select "Resurrect" and press Enter

**Expected:**
- Message: "Resurrecting session: [name]"
- "Note: Starting fresh session (full state restoration coming soon)"
- Session creation starts
- New session created with same name

---

### Scenario 7: Permanently Delete Killed Session

**Prerequisites:** Must have killed a session first

**Action:**
1. Select one or more killed sessions (💀)
2. Press `Enter` to open action menu
3. Select "Delete permanently" and press Enter

**Expected:**
- Warning: "⚠️  This will permanently delete the session state files!"
- Prompt: "Are you sure? [y/N]:"
- If you press `y`:
  - "✓ Permanently deleted: [session-name]"
  - Session removed from list completely

---

### Scenario 8: Create New Session from Visual Interface

**Action:**
1. From the main session list, press `Ctrl+N`

**Expected:**
- 4-step workflow begins (see Scenario 1 for details)
- Step 1: File picker opens
- Step 2: Name your session
- Step 3: Configure agents
- Step 4: Shared task list
- Confirmation screen
- Session creates and attaches

---

### Scenario 9: Mixed Session States

**Setup:** Have both running and killed sessions

**Expected Interface:**
```
  🟢 active-project    Running   4 windows
  🔵 current-work      Attached  4 windows
  💀 old-session       Killed    2024-01-31
  🟢 test-env          Running   4 windows
  💀 archived-work     Killed    2024-01-30
```

**Test:**
1. Select a running session + a killed session
2. Press `Enter`

**Expected Action Menu:**
```
Selected 2 session(s)

Choose an action:
- Attach to session(s)
- Kill session(s)
- Resurrect session(s)
- Delete permanently
- Cancel

Arrow keys to navigate, Enter to select
```

Note: All applicable actions shown for mixed selection. Use `Ctrl+N` from main screen for new sessions.

---

### Scenario 10: Fallback to Text Interface

**Test:** Run without fzf installed

**Simulate:**
```bash
# Temporarily hide fzf
alias fzf='false'
./start
```

**Expected:**
- Falls back to text-based interface
- Original menu-driven interface appears
- All functionality still works (just not visual)

---

## 🐛 Troubleshooting

### Issue: "fzf is not installed"

**Solution:**
```bash
# Mac
brew install fzf

# Windows
scoop install fzf
```

### Issue: File picker doesn't open

**Mac:**
- Check System Preferences → Security & Privacy
- Allow Terminal/iTerm2 to access files

**Windows:**
- Make sure PowerShell is available
- Run from Git Bash or WSL

### Issue: Sessions don't open in iTerm tabs

**Reason:** Multi-tab attach only works in iTerm2

**Solution:**
- Run `./start` and select option 1 (iTerm2)
- Or open iTerm2 first, then run from there

### Issue: Visual interface looks broken

**Check:**
```bash
# Verify terminal supports colors
echo -e "\033[0;32mGreen\033[0m"

# Check fzf version
fzf --version

# Should be 0.40.0 or higher for best experience
```

---

## 📊 Test Checklist

- [ ] Install fzf
- [ ] Run `./start` - visual interface appears
- [ ] Press `Ctrl+N` - 4-step workflow begins
- [ ] Step 1: File picker opens and folder selection works
- [ ] Step 2: Session name validation and conflict detection
- [ ] Step 3: Agent count validation (must be > 0)
- [ ] Step 4: Shared task list configuration
- [ ] Confirmation screen shows all settings correctly
- [ ] Session creates after confirmation
- [ ] Navigate session list with arrow keys
- [ ] Multi-select with Tab
- [ ] Press Enter - action menu appears
- [ ] Attach to single session
- [ ] Attach to multiple sessions (iTerm2)
- [ ] Kill sessions (check for save confirmation)
- [ ] Verify killed sessions show with 💀 and agent counts
- [ ] Resurrect a killed session
- [ ] Permanently delete a killed session
- [ ] Test Esc to quit
- [ ] Verify auto-return to menu after attach/detach

---

## 🎯 Success Criteria

✅ All scripts pass syntax checks
✅ fzf launches without errors
✅ File picker opens native dialog
✅ Sessions list correctly with status icons
✅ Multi-select works smoothly
✅ Attach/kill/resurrect all function
✅ Auto-return to menu after operations
✅ iTerm2 multi-tab attach works
✅ Fallback to text interface when no fzf

---

## 📝 Notes

- Session state files stored in: `.session-state/*.state`
- Each killed session saves metadata for resurrection
- File picker works cross-platform (Mac/Windows)
- Visual interface requires fzf 0.40.0+
- All features also available in text mode

---

## 🚀 Quick Start

```bash
# Install fzf
brew install fzf

# Launch
cd /Users/james/Projects/agent-flywheel-cross-platform
./start

# Select iTerm2 if prompted
# Visual interface appears
# Press Tab to select sessions
# Press Enter for action menu
# Enjoy! 🎉
```
