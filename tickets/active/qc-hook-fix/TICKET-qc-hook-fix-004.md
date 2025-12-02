---
# Metadata
ticket_id: TICKET-qc-hook-fix-004
session_id: qc-hook-fix
sequence: 004
parent_ticket: TICKET-qc-hook-fix-003
title: Ticket validator for pre-work validation
cycle_type: development
status: expediter_review
created: 2025-12-02
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/qc-hook-fix
---

# Requirements

## What Needs to Be Done

Create a ticket validator script that validates ticket state BEFORE work begins, catching misconfigured tickets early with actionable error messages.

### Part 1: Create hooks/validate-ticket.sh

```bash
#!/usr/bin/env bash
# validate-ticket.sh - Validate ticket is properly activated before work
#
# Usage: validate-ticket.sh <ticket-path>
# Exit codes:
#   0 - Ticket valid, work can proceed
#   1 - Ticket invalid, work should not proceed
#   2 - Ticket file not found

set -euo pipefail

validate_ticket() {
    local ticket_path="$1"
    local errors=()

    # Parse YAML frontmatter
    local worktree_path status ticket_id
    worktree_path=$(grep -oP 'worktree_path:\s*\K.+' "$ticket_path" | tr -d ' ')
    status=$(grep -oP 'status:\s*\K.+' "$ticket_path" | tr -d ' ')
    ticket_id=$(grep -oP 'ticket_id:\s*\K.+' "$ticket_path" | tr -d ' ')

    # Check 1: worktree_path is set
    if [[ "$worktree_path" == "null" || -z "$worktree_path" ]]; then
        errors+=("worktree_path is null - ticket not activated")
    fi

    # Check 2: worktree_path exists
    if [[ "$worktree_path" != "null" && ! -d "$worktree_path" ]]; then
        errors+=("worktree_path does not exist: $worktree_path")
    fi

    # Check 3: cwd matches worktree_path
    if [[ "$worktree_path" != "null" && "$(pwd)" != "$worktree_path"* ]]; then
        errors+=("Current directory does not match worktree_path")
        errors+=("  Expected: $worktree_path")
        errors+=("  Actual:   $(pwd)")
    fi

    # Check 4: status is in_progress
    if [[ "$status" != "in_progress" ]]; then
        errors+=("Ticket status is '$status', expected 'in_progress'")
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "❌ TICKET VALIDATION FAILED: $ticket_id" >&2
        echo "" >&2
        for error in "${errors[@]}"; do
            echo "  • $error" >&2
        done
        echo "" >&2
        echo "To activate ticket properly:" >&2
        echo "  ./scripts/activate-ticket.sh $ticket_path" >&2
        return 1
    fi

    echo "✓ Ticket validated: $ticket_id"
    return 0
}
```

### Part 2: Update Agent AGENT.md Files

Add validation step to creator agents (code-developer, tech-writer, prompt-engineer):

```markdown
## Pre-Implementation Checklist

Before any file modifications:
1. Read the ticket file
2. Run: `bash hooks/validate-ticket.sh <ticket-path>`
3. If validation fails, STOP and report to coordinator
4. Only proceed if validation passes
```

### Part 3: Optional SessionStart Integration

Consider adding to `set-quality-cycle-context.sh`:
- Detect if ticket context exists
- Run validation automatically
- Set environment variable with validation result

## Acceptance Criteria
- [ ] validate-ticket.sh checks worktree_path is not null
- [ ] validate-ticket.sh checks worktree_path directory exists
- [ ] validate-ticket.sh checks cwd matches worktree_path
- [ ] validate-ticket.sh checks status is in_progress
- [ ] Clear error messages with remediation steps
- [ ] code-developer AGENT.md updated with validation step
- [ ] tech-writer AGENT.md updated with validation step
- [ ] prompt-engineer AGENT.md updated with validation step
- [ ] Shellcheck passes

# Context

## Why This Work Matters

TICKET-qc-hook-fix-003 blocks destructive operations on main branch (reactive protection). This ticket provides proactive protection by validating ticket state before work begins.

Benefits:
- Catches misconfiguration early (before any work done)
- Better error messages explaining what's wrong
- Guides users to proper activation workflow
- Reduces wasted effort from invalid ticket states

## References
- Parent ticket: `tickets/queue/TICKET-qc-hook-fix-003.md`
- Target files:
  - `hooks/validate-ticket.sh` (new)
  - `agents/code-developer/AGENT.md`
  - `agents/tech-writer/AGENT.md`
  - `agents/prompt-engineer/AGENT.md`
- Ticket template: `tickets/TEMPLATE.md`

# Creator Section

## Implementation Notes

Created `hooks/validate-ticket.sh` with the following validations:
1. **worktree_path not null** - Checks the ticket has been activated
2. **worktree_path exists** - Verifies the directory actually exists on filesystem
3. **cwd matches worktree_path** - Ensures agent is working in the correct worktree
4. **status is in_progress** - Confirms ticket is in active work state

**Design decisions:**
- Used `sed` instead of `grep -oP` for YAML parsing (more portable across systems)
- Removed emojis from output per project preferences
- Errors are written to stderr, success to stdout
- Exit codes: 0=valid, 1=invalid, 2=file not found or usage error
- All errors collected before reporting (shows all issues at once)

Added "Pre-Implementation Validation" section to creator agents:
- `agents/code-developer/AGENT.md` - After "Ticket Operations" section
- `agents/tech-writer/AGENT.md` - After "Start With Clean Isolation" section
- `agents/prompt-engineer/AGENT.md` - After "Ticket Operations" section

## Questions/Concerns

Part 3 (SessionStart integration) was marked as optional in the requirements. Did not implement this in the current scope - it can be a follow-up ticket if desired.

## Changes Made
- File changes:
  - `hooks/validate-ticket.sh` (new, executable)
  - `agents/code-developer/AGENT.md` (added validation section)
  - `agents/tech-writer/AGENT.md` (added validation section)
  - `agents/prompt-engineer/AGENT.md` (added validation section)
- Commits:
  - `1702291` - feat: add ticket validator for pre-work validation
  - `d9c105b` - fix: address code-reviewer findings in validate-ticket.sh

## Iteration 2 Notes (Addressing code-reviewer findings)

**H1 - Path Matching Vulnerability (Fixed)**:
- Changed path matching from `"$(pwd)" != "$worktree_path"*` to `"$cwd" != "$worktree_path" && "$cwd" != "$worktree_path/"*`
- Now requires exact match OR subdirectory with explicit trailing slash
- Tested: `/tmp/test-worktree-other` correctly rejected when worktree_path is `/tmp/test-worktree`

**H2 - Multi-line YAML Value Capture (Fixed)**:
- Added `| head -1` to all three sed YAML parsing commands
- Only captures first occurrence of each key
- Tested: Ticket with duplicate patterns in body content validates correctly

**Testing performed**:
1. Exact match (cwd == worktree_path) - PASS
2. Subdirectory (cwd == worktree_path/subdir) - PASS
3. Prefix collision (cwd == worktree_path-suffix) - FAIL (correct behavior)
4. Multi-line YAML (duplicate keys in body) - PASS (ignores duplicates)
5. Shellcheck - PASS (no warnings)

**Status Update**: 2025-12-02 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] None identified

### HIGH Issues
- [x] **H1: Path Matching Vulnerability (Line 33)** - The cwd matching logic uses `"$(pwd)" != "$worktree_path"*` which is vulnerable to prefix collisions. A directory `/tmp/test-worktree-other` incorrectly matches worktree_path `/tmp/test-worktree` because it shares the same prefix. **Proof:** Created test directories and demonstrated false positive. **Fix:** Change to `"$(pwd)" != "$worktree_path/"* && "$(pwd)" != "$worktree_path"` to require trailing slash or exact match.

- [x] **H2: Multi-line Value Capture in YAML Parsing (Lines 18-20)** - The sed command captures ALL matching lines when duplicate keys exist or when patterns appear outside YAML frontmatter. Example: A ticket with `status: in_progress` in frontmatter and `status: critic_review` in body produces `'in_progress\ncritic_review'` which fails comparison. **Fix:** Use `sed -n '...' | head -1` to capture only first match, OR parse only within frontmatter boundaries.

### MEDIUM Issues
- [x] **M1: YAML Parsing Not Limited to Frontmatter** - The sed patterns match anywhere in the file, not just between `---` markers. While H2's fix (head -1) mitigates multi-match, proper YAML parsing would limit to frontmatter block. Low priority since well-formed tickets won't have these patterns in body.

## Approval Decision
APPROVED

## Rationale
Two HIGH issues must be addressed before approval:

1. **H1 (Path Matching)** - This is a security issue. An attacker could craft a malicious worktree_path that matches unintended directories, bypassing the isolation guarantee. The fix is simple: require trailing slash for subdirectory matching.

2. **H2 (Multi-line Capture)** - This is a correctness issue. Real-world tickets may have YAML-like patterns in their body content (especially in code examples or documentation), causing false validation failures. The fix is simple: pipe to `head -1`.

The M1 issue is acceptable debt - it can be addressed in a follow-up if needed.

**Positive Observations:**
- Shellcheck passes cleanly
- Exit codes are correct (0/1/2)
- Error messages are actionable
- No command injection vectors (no eval, no shell expansion on user data)
- Agent AGENT.md updates are correctly placed and use canonical paths

**Status Update**: 2025-12-02 - NEEDS_CHANGES - Returning to creator for H1 and H2 fixes

## Re-Audit (2025-12-02)

**H1 Fix Verified:**
- Line 38 now uses: `"$cwd" != "$worktree_path" && "$cwd" != "$worktree_path/"*`
- Tested: `/tmp/test-worktree-other` correctly REJECTED when worktree_path is `/tmp/test-worktree`
- Tested: Exact match and subdirectory still work correctly

**H2 Fix Verified:**
- Lines 18-20 now use `| head -1` for all YAML parsing
- Tested: Ticket with duplicate YAML-like patterns in body correctly parses only frontmatter values
- Parsed values confirmed: only first occurrence of each key is captured

**Shellcheck:** PASS (no warnings)

**Decision:** APPROVED - Both H1 and H2 fixes are correct and complete.

**Status Update**: 2025-12-02 - APPROVED - Forwarding to expediter_review

# Expediter Section

## Validation Results
- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Shellcheck: [PASS/FAIL]
- Agent invocation tests: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created rework ticket

# Changelog

## [2025-12-02] - Critic Re-Audit (code-reviewer)
- Verified H1 fix: Path matching with trailing slash requirement works correctly
- Verified H2 fix: head -1 correctly captures only first YAML value
- Shellcheck passes
- Decision: APPROVED
- Status changed to expediter_review

## [2025-12-02] - Creator Iteration 2 (code-developer)
- Fixed H1: Path matching vulnerability with trailing slash requirement
- Fixed H2: Multi-line YAML capture with head -1 on all sed commands
- Tested all 5 scenarios, shellcheck passes
- Commit: d9c105b
- Status remains critic_review for re-audit

## [2025-12-02] - Critic (code-reviewer)
- Audited validate-ticket.sh and agent AGENT.md updates
- Found H1: Path matching vulnerability (prefix collision)
- Found H2: Multi-line YAML value capture
- Found M1: YAML parsing not limited to frontmatter (acceptable debt)
- Decision: NEEDS_CHANGES for H1 and H2
- Status changed to critic_review (returning to creator)

## [2025-12-02] - Creator
- Implemented hooks/validate-ticket.sh with portable sed-based YAML parsing
- Added Pre-Implementation Validation section to 3 creator agents
- Shellcheck passes, tested with valid and invalid tickets
- Status changed to critic_review

## [2025-12-02] - Coordinator
- Ticket created from ultrathink analysis
- Designed validate-ticket.sh script
- Identified agent files needing updates
