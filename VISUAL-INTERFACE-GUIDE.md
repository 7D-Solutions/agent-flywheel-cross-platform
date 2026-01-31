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
4. Options:
   - `[N]` Create new session
   - `[Q]` Quit

**Test Action:** Press `N`

**Expected:**
- Native macOS file picker opens
- You select a project folder
- Session creation starts automatically
- 4-agent tmux session launches

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

  🟢 session-1    Running   4 windows
  🟢 session-2    Running   4 windows
  🟢 session-3    Running   4 windows

Tab: Select Multiple | Enter: Action Menu
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

[A] Attach to session(s)
[K] Kill session(s)
[N] Create new session
[C] Cancel

Your choice:
```

---

### Scenario 3: Attach to Single Session

**Action:** Select one session, press Enter, then press `A`

**Expected:**
- Attaches to the tmux session directly
- You see the 4-agent panes
- Detach with `Ctrl+b d`
- Returns to visual interface automatically

---

### Scenario 4: Attach to Multiple Sessions (iTerm2 only)

**Action:**
1. Select 2-3 sessions with `Tab`
2. Press `Enter`
3. Press `A`

**Expected:**
- Message: "Opening 3 sessions in new tabs..."
- Each session opens in a new iTerm tab
- You can switch between tabs to see each session

---

### Scenario 5: Kill Sessions (with Resurrection)

**Action:**
1. Select 1-2 sessions with `Tab`
2. Press `Enter`
3. Press `K`

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
2. Press `Enter`
3. Press `R`

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
2. Press `Enter`
3. Press `D`

**Expected:**
- Warning: "⚠️  This will permanently delete the session state files!"
- Prompt: "Are you sure? [y/N]:"
- If you press `y`:
  - "✓ Permanently deleted: [session-name]"
  - Session removed from list completely

---

### Scenario 8: Create New Session from Visual Interface

**Action:**
1. From any screen, select sessions (or none)
2. Press `Enter`
3. Press `N`

**Expected:**
- Message: "Select project folder for new session"
- Native file picker opens
- Select a folder
- Message: "Selected: /path/to/folder"
- Session creation starts

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

[A] Attach to session(s)
[K] Kill session(s)
[R] Resurrect session(s)
[D] Permanently delete session(s)
[N] Create new session
[C] Cancel
```

Note: All applicable actions shown for mixed selection

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
- [ ] Create new session with file picker
- [ ] Navigate with arrow keys
- [ ] Multi-select with Tab
- [ ] Attach to single session
- [ ] Attach to multiple sessions (iTerm2)
- [ ] Kill sessions (check for save confirmation)
- [ ] Verify killed sessions show with 💀
- [ ] Resurrect a killed session
- [ ] Permanently delete a killed session
- [ ] Create new session from action menu
- [ ] Test Ctrl-A (select all)
- [ ] Test Ctrl-D (deselect all)
- [ ] Test canceling with Ctrl-C
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
