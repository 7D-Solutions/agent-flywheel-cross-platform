# File Reservation System - Test Plan

**Purpose:** Validate conflict detection and coordination workflows
**Agents needed:** 2+ (IndigoBeaver, AmberGate, OrangeFalcon)
**Duration:** ~15 minutes

---

## Test 1: Basic Reservation Flow

**Agent:** Any single agent

### Steps
1. List current reservations
   ```bash
   ./scripts/reserve-files.sh list
   ```
   Expected: No reservations

2. Reserve a test file
   ```bash
   ./scripts/reserve-files.sh reserve 'README.md'
   ```
   Expected: Success, reservation ID returned

3. List again
   ```bash
   ./scripts/reserve-files.sh list
   ```
   Expected: See your reservation

4. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```
   Expected: Released 1 reservation

5. List again
   ```bash
   ./scripts/reserve-files.sh list
   ```
   Expected: No reservations

**Result:** ✅ / ❌

---

## Test 2: Exclusive Conflict Detection

**Agents:** Agent A (e.g., IndigoBeaver), Agent B (e.g., AmberGate)

### Steps

**Agent A:**
1. Reserve files
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/reserve-files.sh'
   ```
   Expected: Success

**Agent B:**
2. Try to reserve same files
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/reserve-files.sh'
   ```
   Expected: ⚠️ Conflict detected, shows Agent A is holding it

3. List all reservations
   ```bash
   ./scripts/reserve-files.sh list-all
   ```
   Expected: See Agent A's reservation

**Agent A:**
4. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Agent B:**
5. Try again
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/reserve-files.sh'
   ```
   Expected: Success (now available)

6. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Result:** ✅ / ❌

**Notes:**

---

## Test 3: Glob Pattern Conflicts

**Agents:** Agent A, Agent B

### Steps

**Agent A:**
1. Reserve with glob pattern
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/**'
   ```
   Expected: Success

**Agent B:**
2. Try to reserve specific file within pattern
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/agent-mail-helper.sh'
   ```
   Expected: ⚠️ Conflict (specific file matches `scripts/**`)

**Agent A:**
3. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Agent B:**
4. Try again
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/agent-mail-helper.sh'
   ```
   Expected: Success

5. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Result:** ✅ / ❌

**Notes:**

---

## Test 4: Check Availability

**Agents:** Agent A, Agent B

### Steps

**Agent A:**
1. Reserve files
   ```bash
   ./scripts/reserve-files.sh reserve 'docs/**'
   ```

**Agent B:**
2. Check availability (should detect conflict)
   ```bash
   ./scripts/reserve-files.sh check 'docs/**'
   ```
   Expected: Returns non-zero exit code, shows warning

3. Check availability of different files (should succeed)
   ```bash
   ./scripts/reserve-files.sh check 'scripts/**'
   ```
   Expected: Returns 0, files available

**Agent A:**
4. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Agent B:**
5. Check again
   ```bash
   ./scripts/reserve-files.sh check 'docs/**'
   ```
   Expected: Returns 0, files now available

**Result:** ✅ / ❌

**Notes:**

---

## Test 5: TTL Renewal

**Agent:** Any single agent

### Steps

1. Reserve files
   ```bash
   ./scripts/reserve-files.sh reserve 'README.md'
   ```

2. List and note expiration time
   ```bash
   ./scripts/reserve-files.sh list
   ```

3. Renew by 1 hour
   ```bash
   ./scripts/reserve-files.sh renew 3600
   ```

4. List again and verify expiration extended
   ```bash
   ./scripts/reserve-files.sh list
   ```
   Expected: New expiration ~1 hour later than original

5. Release
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Result:** ✅ / ❌

**Notes:**

---

## Test 6: Bypass Mode

**Agent:** Any single agent

### Steps

1. Enable bypass
   ```bash
   export BYPASS_RESERVATION=1
   ```

2. Check files (should always succeed)
   ```bash
   ./scripts/reserve-files.sh check 'scripts/**'
   ```
   Expected: ⚠️ Warning about bypass, returns success

3. Disable bypass
   ```bash
   unset BYPASS_RESERVATION
   ```

4. Check again (normal behavior)
   ```bash
   ./scripts/reserve-files.sh check 'scripts/**'
   ```
   Expected: Normal check, no bypass warning

**Result:** ✅ / ❌

**Notes:**

---

## Test 7: Agent Mail Coordination

**Agents:** Agent A, Agent B

### Scenario
Agent B finds conflict and coordinates with Agent A via agent mail.

### Steps

**Agent A:**
1. Reserve files
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/launcher.sh'
   ```

**Agent B:**
2. Try to reserve, get conflict
   ```bash
   ./scripts/reserve-files.sh reserve 'scripts/launcher.sh'
   ```

3. Send coordination message
   ```bash
   ./scripts/agent-mail-helper.sh send 'AgentA' 'File Coordination' \
       'I need to edit scripts/launcher.sh. Are you done with it?'
   ```

**Agent A:**
4. Check inbox
   ```bash
   ./scripts/agent-mail-helper.sh inbox
   ```

5. Reply and release
   ```bash
   ./scripts/agent-mail-helper.sh send 'AgentB' 'Re: File Coordination' \
       'Released! Go ahead.'
   ./scripts/reserve-files.sh release
   ```

**Agent B:**
6. Check inbox, then reserve
   ```bash
   ./scripts/agent-mail-helper.sh inbox
   ./scripts/reserve-files.sh reserve 'scripts/launcher.sh'
   ```
   Expected: Success

7. Release when done
   ```bash
   ./scripts/reserve-files.sh release
   ```

**Result:** ✅ / ❌

**Notes:**

---

## Test Results Summary

| Test | Result | Notes |
|------|--------|-------|
| 1. Basic flow | ✅ PASS | Reserve/list/release cycle works correctly |
| 2. Exclusive conflict | ✅ PASS | Conflict detection shows holder name, exit code 5 |
| 3. Glob pattern conflict | ✅ PASS | Glob `scripts/**` correctly blocks specific files |
| 4. Check availability | ✅ PASS | Check detects reserved vs available files |
| 5. TTL renewal | ✅ PASS | Renew extends expiration correctly |
| 6. Bypass mode | ✅ PASS | BYPASS_RESERVATION=1 skips checks with warning |
| 7. Agent mail coordination | ✅ PASS | Full workflow: conflict → mail → release → success |

---

## Issues Found

Document any bugs, unexpected behavior, or rough edges:

1. **Multi-reservation behavior:** Agent can create multiple reservations for same file, system reports "conflicts" with own reservations. Advisory locks don't prevent this. (Test 7, IDs 23-24)
2. **Parser bug (FIXED):** Initially used `.agent_name` instead of `.agent` and didn't check `.result.structuredContent` first. Fixed in all parsing locations.
3. None blocking - system works as designed for advisory locking

---

## Improvements Needed

Suggestions for Phase 2:

1. **Duplicate detection:** Optionally prevent same agent from reserving same file twice
2. **Better release targeting:** Allow releasing specific reservation IDs, not just paths
3. **Expiration notifications:** Alert agents when reservations are about to expire
4. **Conflict resolution UI:** Interactive mode for resolving conflicts
5. **Reservation history:** Track who reserved what and when for audit trail

---

## Sign-off

**Tested by:**
- [x] IndigoBeaver (Tests 1-7)
- [x] AmberGate (Test 2 - conflict detection)
- [x] OrangeFalcon (Tests 3, 4, 7 - multi-agent coordination)

**Date:** 2026-01-30

**Status:** Ready for Phase 1A Task 4 ✅

---

*Save this file and commit results after testing.*
