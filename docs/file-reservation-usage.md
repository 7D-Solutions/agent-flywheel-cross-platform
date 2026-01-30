# File Reservation System - Usage Guide

**Status:** ✅ Phase 1A Task 2 Complete
**Implemented by:** IndigoBeaver
**Date:** 2026-01-29

---

## Overview

The file reservation system provides **advisory file locking** to prevent concurrent edit conflicts between multiple agents working in the same codebase.

**Key principle:** Reservations are ADVISORY, not enforced. They signal intent and enable coordination.

---

## Quick Start

```bash
# Reserve files before editing
./scripts/reserve-files.sh reserve 'src/app.py'

# Edit your files
# ... make changes ...

# Release when done
./scripts/reserve-files.sh release
```

---

## Commands

### Reserve Files
```bash
./scripts/reserve-files.sh reserve <file-patterns...>
```

**Examples:**
```bash
# Single file
./scripts/reserve-files.sh reserve src/main.py

# Multiple files
./scripts/reserve-files.sh reserve src/app.py src/config.py

# Glob patterns
./scripts/reserve-files.sh reserve 'src/**'
./scripts/reserve-files.sh reserve 'tests/*.py'
```

**Behavior:**
- Creates exclusive lock (blocks other exclusive or shared reservations)
- Default TTL: 3600 seconds (1 hour)
- Auto-expires after TTL
- Returns conflict if files already reserved

### Check Availability
```bash
./scripts/reserve-files.sh check <file-patterns...>
```

**Examples:**
```bash
./scripts/reserve-files.sh check 'docs/**'
```

**Behavior:**
- Returns 0 if files are available
- Returns 1 if files are reserved by someone else
- Creates temporary shared reservation (released immediately)

### Release Reservations
```bash
./scripts/reserve-files.sh release [file-patterns...]
```

**Examples:**
```bash
# Release specific files
./scripts/reserve-files.sh release src/app.py

# Release all your reservations
./scripts/reserve-files.sh release
```

### List Reservations
```bash
# List your active reservations
./scripts/reserve-files.sh list

# List all agents' reservations
./scripts/reserve-files.sh list-all
```

### Renew TTL
```bash
./scripts/reserve-files.sh renew [extend-seconds]
```

**Examples:**
```bash
# Extend by default (3600s)
./scripts/reserve-files.sh renew

# Extend by 2 hours
./scripts/reserve-files.sh renew 7200
```

---

## Conflict Handling

When you try to reserve files already held by another agent:

```
⚠️  Conflicts detected:
  - src/app.py: held by AmberGate

Another agent is working on these files. Consider:
  1. Wait for them to release
  2. Coordinate via agent mail
  3. Work on different files
```

**Exit code:** 5 (conflict detected)

**Best practices:**
- Send agent mail to coordinate: `./scripts/agent-mail-helper.sh send 'AgentName' ...`
- Check their task status
- Work on non-overlapping files

---

## Environment Variables

### PROJECT_KEY
Project path for reservations (default: from project config)

```bash
PROJECT_KEY=/path/to/project ./scripts/reserve-files.sh reserve 'src/**'
```

### AGENT_NAME
Your agent name (default: from agent-mail-helper)

```bash
AGENT_NAME=MyAgent ./scripts/reserve-files.sh list
```

### BYPASS_RESERVATION
Bypass conflict checks (for optional enforcement testing)

```bash
BYPASS_RESERVATION=1 ./scripts/reserve-files.sh check 'src/**'
# Always returns success
```

---

## Pre-Edit Checks

**Phase 1A Task 3:** Lightweight pre-edit check script to verify files are available before editing.

### Quick Usage
```bash
# Before editing any files, run pre-edit check
./scripts/pre-edit-check.sh 'src/module.py'

# If check passes (exit 0), proceed with reservation
./scripts/reserve-files.sh reserve 'src/module.py'
# ... make edits ...
./scripts/reserve-files.sh release
```

### Pre-Edit Check Script
The `scripts/pre-edit-check.sh` wrapper provides a simple governance check:

```bash
./scripts/pre-edit-check.sh <file-patterns...>
```

**Exit codes:**
- `0` - Files available, safe to proceed
- `1` - Files reserved by another agent (logs holder names)
- `2` - Error (missing arguments, invalid usage)

**Features:**
- Runs `reserve-files.sh check` internally
- Logs conflict details including agent names
- Respects `BYPASS_RESERVATION=1`
- Provides clear next-step guidance on conflicts

### tmux Integration

**Before editing files in tmux:**
```bash
# Run pre-edit check first
./scripts/pre-edit-check.sh 'docs/**'

# Only proceed if check passes (exit code 0)
# Then reserve, edit, and release
```

**Example conflict scenario:**
```bash
# Agent A reserves files
./scripts/reserve-files.sh reserve 'src/app.py'

# Agent B runs pre-edit check (in different pane)
./scripts/pre-edit-check.sh 'src/app.py'
# Output shows: held by AgentA
# Exit code: 1 (conflict)

# Agent B coordinates via mail or waits
```

### Bypass Mode
For testing or emergencies:
```bash
BYPASS_RESERVATION=1 ./scripts/pre-edit-check.sh 'src/**'
# Always returns 0 (bypassed)
```

---

## Workflow Integration

### Pre-Edit Workflow
```bash
# 1. Run pre-edit check
if ! ./scripts/pre-edit-check.sh 'src/module.py'; then
    echo "Files are in use, coordinate with other agent"
    exit 1
fi

# 2. Reserve files
./scripts/reserve-files.sh reserve 'src/module.py'

# 3. Make your edits
# ... edit files ...

# 4. Release reservation
./scripts/reserve-files.sh release
```

### Long-Running Work
```bash
# Reserve at start
./scripts/reserve-files.sh reserve 'src/**'

# If work takes >1 hour, renew periodically
./scripts/reserve-files.sh renew 3600

# Release when done
./scripts/reserve-files.sh release
```

---

## Technical Details

### MCP Integration
- Uses MCP Agent Mail server (port 8765)
- Tools: `file_reservation_paths`, `release_file_reservations`, `renew_file_reservations`
- Resources: `resource://file_reservations/{project}`

### Reservation Properties
- **ID**: Unique reservation identifier
- **Agent**: Agent name who holds the lock
- **Path pattern**: Glob pattern (e.g., `src/**`)
- **Exclusive**: true/false (exclusive blocks all, shared allows other shared)
- **Reason**: Optional description
- **Created/Expires timestamps**: TTL tracking

### Storage
- SQLite database (MCP Agent Mail server)
- Git artifacts in `file_reservations/*.json`
- Audit trail preserved

---

## Testing

See `testing/reservation-test-plan.md` for multi-agent conflict testing scenarios.

---

## Phase 1A Completion

**What works:**
- ✅ Basic reserve/check/release functions
- ✅ MCP Agent Mail integration
- ✅ Conflict detection
- ✅ TTL management
- ✅ Simple bash wrapper (no complex templates)

**What's next (Phase 1A Tasks 3-5):**
- Add pre-edit checks to workflows
- Test with 2+ agents in real scenarios
- Document patterns that emerge from actual usage

---

## Troubleshooting

### "Error: Token file not found"
MCP Agent Mail server is not running.

```bash
cd ~/mcp_agent_mail && docker-compose up -d
```

### "Error: Not registered in this pane"
Register your agent first:

```bash
./scripts/agent-mail-helper.sh register
```

### Reservations not releasing
Check for stale reservations:

```bash
./scripts/reserve-files.sh list-all
```

Force release via MCP (use with caution):
- Contact the agent who holds the lock
- Wait for TTL expiration
- Use `force_release_file_reservation` tool (advanced)

---

## Related Documentation

- Phase 1A Implementation Guide: `docs/phase-1-implementation-guide.md` (if exists in integration project)
- Governance Framework: `docs/phase-1-governance.md` (if exists in integration project)
- Agent Mail System: `AGENT_MAIL.md`

---

*This is a Phase 1 minimal implementation - simple, tested, ready for real usage.*
