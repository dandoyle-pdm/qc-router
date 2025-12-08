---
# Metadata
ticket_id: TICKET-ticket-naming-hook-001
session_id: ticket-naming-hook
sequence: 001
parent_ticket: null
title: Add PreToolUse hook to enforce consistent ticket naming
cycle_type: development
status: open
created: 2024-12-06 14:30
worktree_path: null
---

# Requirements

## What Needs to Be Done

Create a PreToolUse hook that validates ticket filenames when Write or Edit operations target the `tickets/` directory. The hook should enforce the standard naming pattern and block invalid names with a helpful error message.

**Pattern to enforce:** `^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$`

**Valid examples:**
- `TICKET-mwaa-go-rewrite-001.md`
- `TICKET-qc-hook-fix-002.md`
- `TICKET-protected-branches-001.md`

**Invalid examples to block:**
- `TICKET-MWAA-002-go-rewrite.md` (uppercase, sequence in wrong position)
- `ticket-foo-001.md` (wrong case for prefix)
- `TICKET-foo_bar-001.md` (underscore instead of hyphen)
- `TICKET-foo-1.md` (sequence not 3 digits)
- `TICKET-foo-001.txt` (wrong extension)

## Acceptance Criteria

- [ ] Hook validates Write/Edit operations to any `tickets/` directory
- [ ] Validates filename matches pattern: `TICKET-{kebab-case-session-id}-{3-digit-sequence}.md`
- [ ] Blocks invalid names and outputs clear error with correct format example
- [ ] Allows TEMPLATE.md (exempt from naming rules)
- [ ] Hook registered in hooks.json
- [ ] Manual testing confirms hook works correctly
- [ ] Does not break existing hooks functionality

# Context

## Why This Work Matters

Without enforcement, Claude instances create tickets with inconsistent naming:
- Uppercase in session IDs
- Sequence numbers embedded in middle of name
- Wrong separators

This causes confusion and makes ticket management harder. A hook provides consistent enforcement across all sessions.

## References

- Current hooks: `hooks/hooks.json`, `hooks/enforce-quality-cycle.sh`
- Ticket template: `tickets/TEMPLATE.md`
- Example bad name seen: `TICKET-MWAA-002-go-rewrite.md`

# Creator Section

## Implementation Notes
[What was built, decisions made, approach taken]

## Questions/Concerns
[Anything unclear or requiring discussion]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] `file:line` - Issue description and fix required

### HIGH Issues
- [ ] `file:line` - Issue description and fix required

### MEDIUM Issues
- [ ] `file:line` - Suggestion for improvement

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [PASS/FAIL]
- Security scans: [PASS/FAIL]
- Build: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2024-12-06 14:30] - Creator
- Ticket created
