---
# Metadata
ticket_id: TICKET-qc-hook-fix-003
session_id: qc-hook-fix
sequence: 003
parent_ticket: TICKET-qc-hook-fix-002
title: Block destructive tools on protected branches (main/master/develop)
cycle_type: development
status: open
created: 2025-12-02
worktree_path: null
---

# Requirements

## What Needs to Be Done

Add branch protection to `enforce-quality-cycle.sh` to prevent Write/Edit operations on protected branches (main, master, develop).

### Part 1: Add is_protected_branch() Function

```bash
is_protected_branch() {
    local cwd="${CWD:-$(pwd)}"

    # Check if we're in a git repo
    if ! git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
        return 1  # Not a git repo, not protected
    fi

    local branch
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Protected branches
    case "$branch" in
        main|master|develop|release/*)
            return 0  # Protected
            ;;
        *)
            return 1  # Not protected
            ;;
    esac
}
```

### Part 2: Integrate Branch Check

Insert branch protection check BEFORE quality cycle check (hard gate):

```bash
# For destructive tools on protected branches - block regardless of QC status
case "${tool_name}" in
    Edit|Write)
        if is_protected_branch; then
            # Check for explicit main branch override
            if [[ "${CLAUDE_MAIN_OVERRIDE:-false}" != "true" ]]; then
                generate_branch_error_message "${tool_name}" "${branch}" >&2
                exit 2
            fi
            # Log override usage
            debug_log "AUDIT: MAIN_OVERRIDE used on branch ${branch}"
        fi
        ;;
esac
```

### Part 3: Add CLAUDE_MAIN_OVERRIDE

- Separate from CLAUDE_QC_OVERRIDE (different concerns)
- Log all override usage for audit trail
- Document in error message

### Part 4: Update Error Message

Create `generate_branch_error_message()` that explains:
- Why main branch is protected
- How to use worktrees properly
- CLAUDE_MAIN_OVERRIDE as emergency escape

## Acceptance Criteria
- [ ] Write/Edit blocked on main branch without override
- [ ] Write/Edit blocked on master branch without override
- [ ] Write/Edit blocked on develop branch without override
- [ ] CLAUDE_MAIN_OVERRIDE=true allows bypass with audit log
- [ ] Read/Glob/Grep still work on main (no branch check for read-only)
- [ ] Worktree branches (feature/*) not blocked
- [ ] Error message explains worktree workflow
- [ ] Shellcheck passes

# Context

## Why This Work Matters

TICKET-qc-hook-fix-002 was implemented directly on main branch despite the quality cycle requiring worktree isolation. The enforcement hook checks for quality cycle context and protected paths, but **never checks which branch we're on**.

This is a safety gap: subagents can accidentally commit directly to main, bypassing:
- PR review process
- CI/CD checks
- Branch protection rules

## References
- Parent ticket: `tickets/completed/main/TICKET-qc-hook-fix-002.md`
- Target file: `hooks/enforce-quality-cycle.sh`
- Process note from TICKET-002 changelog documenting the violation

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
- Manual branch tests: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created rework ticket

# Changelog

## [2025-12-02] - Coordinator
- Ticket created from ultrathink analysis
- Identified gap: no branch protection in enforcement hook
- Designed is_protected_branch() function and integration points
