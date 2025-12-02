---
# Metadata
ticket_id: TICKET-qc-hook-fix-004
session_id: qc-hook-fix
sequence: 004
parent_ticket: TICKET-qc-hook-fix-003
title: Ticket validator for pre-work validation
cycle_type: development
status: open
created: 2025-12-02
worktree_path: null
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
[To be filled by code-developer agent]

## Questions/Concerns
[To be filled]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] None identified yet

### HIGH Issues
- [ ] None identified yet

### MEDIUM Issues
- [ ] None identified yet

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

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

## [2025-12-02] - Coordinator
- Ticket created from ultrathink analysis
- Designed validate-ticket.sh script
- Identified agent files needing updates
