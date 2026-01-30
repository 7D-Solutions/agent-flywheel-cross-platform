# File Reservation Workflow Guide

**Purpose:** Practical guide for agents to coordinate file edits and avoid conflicts

**Status:** Phase 1A Complete - All 7 tests passing

---

## Quick Reference

```bash
# Before editing - check availability
./scripts/reserve-files.sh check 'path/to/files'

# Reserve files
./scripts/reserve-files.sh reserve 'path/to/files'

# Edit files (do your work)

# Release when done
./scripts/reserve-files.sh release
```

---

## Standard Workflow

### 1. Pre-Edit Checks

Before modifying any files, run:

```bash
./scripts/reserve-files.sh check 'src/module.py'
```

**Exit codes:**
- `0` - Available, safe to proceed
- `1` - Reserved by another agent, coordination needed

**Why check first?**
- Avoid wasted work on files someone else is editing
- Signal your intent before claiming resources
- Enables polite coordination

### 2. Reserve Files

```bash
./scripts/reserve-files.sh reserve 'src/module.py'
```

**Tips:**
- Use glob patterns for multiple files: `'src/**'`
- Default TTL: 1 hour (auto-expires)
- Advisory lock - signals intent to other agents

**What happens:**
- Creates exclusive reservation
- Blocks other agents from same files
- Returns conflict if already reserved

### 3. Handle Conflicts

If you see:
```
⚠️  Conflicts detected:
  - src/app.py: held by OrangeFalcon
```

**Options:**

**A) Coordinate via agent mail**
```bash
./scripts/agent-mail-helper.sh send 'OrangeFalcon' \
  'File Coordination' \
  'I need src/app.py. When will you be done?'
```

**B) Work on different files**
```bash
# Find non-conflicting work
./scripts/reserve-files.sh check 'tests/**'  # Try another area
```

**C) Wait and retry**
```bash
# Check inbox for updates
./scripts/agent-mail-helper.sh inbox

# Retry when released
./scripts/reserve-files.sh reserve 'src/app.py'
```

### 4. Do Your Work

Make your edits with confidence:
- You've signaled intent to other agents
- Others will see conflict if they try to edit same files
- TTL gives you 1 hour of protected time

### 5. Release Files

**Always release when done:**
```bash
./scripts/reserve-files.sh release
```

**Specific files:**
```bash
./scripts/reserve-files.sh release 'src/module.py'
```

**Release all:**
```bash
./scripts/reserve-files.sh release
```

---

## Long-Running Tasks

If your work takes more than 1 hour:

```bash
# Initial reserve
./scripts/reserve-files.sh reserve 'docs/**'

# ... work for 45 minutes ...

# Extend TTL by 1 hour
./scripts/reserve-files.sh renew

# ... continue working ...

# Release when complete
./scripts/reserve-files.sh release
```

**Default renew:** Extends by 3600 seconds (1 hour)

**Custom duration:**
```bash
./scripts/reserve-files.sh renew 7200  # Extend by 2 hours
```

---

## Agent Mail Coordination

### Example: Full Coordination Flow

**Scenario:** OrangeFalcon needs a file reserved by IndigoBeaver

**OrangeFalcon:**
```bash
# Try to reserve, get conflict
./scripts/reserve-files.sh reserve 'scripts/launcher.sh'
# ⚠️  Conflicts detected: held by IndigoBeaver

# Send coordination message
./scripts/agent-mail-helper.sh send 'IndigoBeaver' \
  'File Coordination' \
  'I need scripts/launcher.sh. Are you done with it?'
```

**IndigoBeaver:**
```bash
# Check inbox
./scripts/agent-mail-helper.sh inbox

# Reply and release
./scripts/agent-mail-helper.sh send 'OrangeFalcon' \
  'Re: File Coordination' \
  'Released! Go ahead.'

./scripts/reserve-files.sh release
```

**OrangeFalcon:**
```bash
# Retry reservation
./scripts/reserve-files.sh reserve 'scripts/launcher.sh'
# ✓ Reserved: scripts/launcher.sh
```

---

## Bypass Mode

**Use case:** Testing, emergencies, or when you need to override checks

### Enable Bypass

```bash
export BYPASS_RESERVATION=1
```

**Effect:**
- All checks return success
- Reservations still created (for tracking)
- Warning displayed: `⚠️  BYPASS MODE ENABLED`

### Warnings

When bypass is active:
```
⚠️  BYPASS MODE ENABLED - Conflict checks bypassed
```

**When to use:**
- Testing the system
- Emergency fixes when coordination isn't possible
- Debugging reservation issues

**When NOT to use:**
- Normal development work
- When other agents are active
- Production-like scenarios

### Disable Bypass

```bash
unset BYPASS_RESERVATION
```

---

## Edge Cases

### Self-Reservation Conflicts

**Issue:** You can reserve the same file multiple times

```bash
# First reservation
./scripts/reserve-files.sh reserve 'src/app.py'  # ID: 23

# Second reservation (allowed but warned)
./scripts/reserve-files.sh reserve 'src/app.py'  # ID: 24
# ⚠️  Conflicts detected: src/app.py held by IndigoBeaver
```

**Why it happens:**
- Advisory locks don't prevent self-conflicts
- System warns but allows it

**Best practice:**
```bash
# Check your own reservations first
./scripts/reserve-files.sh list

# Release specific patterns
./scripts/reserve-files.sh release 'src/app.py'

# Or release all
./scripts/reserve-files.sh release
```

### Stale Reservations

**If you forget to release:**
- Auto-expires after TTL (default: 1 hour)
- Other agents can see it's yours via `list-all`
- They can coordinate via agent mail

**Clean up:**
```bash
# See your active reservations
./scripts/reserve-files.sh list

# Release everything
./scripts/reserve-files.sh release
```

### Multi-Agent Deadlock

**Scenario:** Two agents waiting on each other

**Prevention:**
- Use `check` before `reserve` to fail fast
- Set reasonable TTLs
- Coordinate via agent mail proactively
- Consider working on different files

**Resolution:**
- Agent mail negotiation
- One agent releases first
- Wait for TTL expiration

---

## Command Quick Reference

| Command | Purpose | Exit Code |
|---------|---------|-----------|
| `check 'paths'` | Test availability before reserving | 0=available, 1=conflict |
| `reserve 'paths'` | Claim exclusive lock on files | 0=success, 5=conflict |
| `release ['paths']` | Free reservations (all or specific) | 0=success |
| `list` | Show your active reservations | 0=success |
| `list-all` | Show all agents' reservations | 0=success |
| `renew [seconds]` | Extend TTL (default: 3600s) | 0=success |

---

## Best Practices

1. **Always check before reserving** - Fail fast, coordinate early
2. **Reserve at the right scope** - Not too broad (avoid blocking others), not too narrow (avoid multiple reserves)
3. **Release promptly** - Don't hold locks longer than needed
4. **Coordinate proactively** - Use agent mail when conflicts occur
5. **Clean up on errors** - If your task fails, still release files
6. **Use glob patterns wisely** - `'src/**'` blocks entire directory, `'src/module.py'` is specific
7. **Renew if needed** - Don't let locks expire during active work

---

## Integration with Phase 1 Governance

Per `docs/phase-1-governance.md`:

**Pre-flight checks** should include:
1. Estimate files to be edited
2. Check reservations: `./scripts/reserve-files.sh check 'patterns'`
3. Reserve files before editing
4. Do work
5. Self-review
6. Release files

**Bypass mode** should only be used:
- During advisory Phase 1 learning
- With explicit justification logged
- Not as default workflow

---

## Testing

All 7 tests passing (see `testing/reservation-test-plan.md`):
- ✅ Basic reserve/release cycle
- ✅ Exclusive conflict detection
- ✅ Glob pattern conflicts
- ✅ Availability checks
- ✅ TTL renewal
- ✅ Bypass mode
- ✅ Agent mail coordination

**Edge cases discovered:**
- Multiple self-reservations allowed (advisory system working as intended)
- Coordination flow tested successfully with 3 agents

---

## Troubleshooting

**"Token file not found"**
```bash
cd ~/mcp_agent_mail && docker-compose up -d
```

**"Not registered in this pane"**
```bash
./scripts/agent-mail-helper.sh register
```

**Can't release files**
```bash
# Force release all yours
./scripts/reserve-files.sh release

# Check what's still held
./scripts/reserve-files.sh list
```

**Someone won't release**
- Send agent mail reminder
- Wait for TTL expiration (1 hour default)
- Check if they're still active
- Consider working on different files

---

## Related Documentation

- **Command Reference:** `docs/file-reservation-usage.md` - Technical details and all commands
- **Test Plan:** `testing/reservation-test-plan.md` - Multi-agent test scenarios
- **Governance Rules:** `docs/phase-1-governance.md` - When to use reservations
- **Agent Mail:** `AGENT_MAIL.md` - Communication system

---

**Phase 1A Complete** - Simple, tested, ready for real coordination workflows.
