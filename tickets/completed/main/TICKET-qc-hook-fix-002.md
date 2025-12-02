---
# Metadata
ticket_id: TICKET-qc-hook-fix-002
session_id: qc-hook-fix
sequence: 002
parent_ticket: TICKET-qc-hook-fix-001
title: Extend enforcement to documents + ultrathink for transient content
cycle_type: development
status: approved
created: 2025-12-02
worktree_path: null
---

# Requirements

## Philosophy
Documents and code receive equal treatment - **documents are specifications that guide code**.

| Content Type | Treatment | Rationale |
|--------------|-----------|-----------|
| Code | Full cycle (Creator→Critic→Judge) | Production impact |
| Documents | Full cycle (Creator→Critic→Judge) | Specifications that guide code |
| Tickets | Second pass (ultrathink) | Transient process artifacts |
| Handoffs | Second pass (ultrathink) | Ephemeral session continuity |

## What Needs to Be Done

### Part 1: Hook - Protect Documents (Full Cycle Required)
Add documentation files to `is_protected_path()`:

```bash
# Documentation files (specifications - same rigor as code)
if [[ "${path}" =~ \.(md|mdx|rst|adoc)$ ]]; then
    # Exclude tickets - they get lighter treatment via ultrathink
    if [[ ! "${path}" =~ /tickets/ ]]; then
        return 0
    fi
fi
```

This enforces full quality cycles for:
- README.md, CLAUDE.md, DEVELOPER.md
- Agent definitions (AGENT.md)
- Skill definitions (SKILL.md)
- Any specification document

### Part 2: CLAUDE.md - Ultrathink for Transient Content
Add to CLAUDE.md quality cycle section:

```markdown
### Transient Content (Second Pass)
Tickets and handoff prompts are process artifacts, not specifications.
Use **ultrathink** (extended thinking) when:
- Creating or updating tickets
- Generating handoff prompts
- Writing session summaries

This provides review-equivalent rigor without subagent overhead.
```

### Part 3: Handoff Slash Commands
Update `/workflow-guard:handoff*` commands to require ultrathink in their prompts.

## Acceptance Criteria
- [x] `.md` files (excluding `/tickets/`) trigger hook enforcement
- [x] CLAUDE.md documents ultrathink requirement for tickets/handoffs
- [x] Handoff slash commands specify ultrathink
- [x] Test: Write to README.md without QC → blocked
- [x] Test: Write to tickets/*.md without QC → allowed (ultrathink handles review)
- [x] Shellcheck passes

# Context

## Why This Work Matters
Documents ARE specifications. A poorly written design doc leads to poorly implemented code. The enforcement hook currently only protects code files, leaving documentation unguarded.

Tickets and handoffs are different - they're transient process artifacts. Full quality cycles would add friction without proportional benefit. Ultrathink provides the "second pass" review inline.

## References
- Parent ticket: `tickets/completed/main/TICKET-qc-hook-fix-001.md`
- Target file: `hooks/enforce-quality-cycle.sh`
- CLAUDE.md quality recipes: R2, R3

# Creator Section

## Implementation Notes
Implemented all three parts with one iteration cycle to fix terminology consistency.

## Changes Made
- `hooks/enforce-quality-cycle.sh`: Added .md/.mdx/.rst/.adoc protection with /tickets/ and handoff-*.md exclusions
- `CLAUDE.md`: Added "Transient Content (Second Pass)" section
- `workflow-guard/commands/handoff*.md`: Added ultrathink note to all 5 files
- Commits: cdef6d6, d459448

# Critic Section

## Audit Findings
1. HIGH-1: Terminology inconsistency ("extended thinking" vs "sequential thinking") - FIXED in iteration 2
2. HIGH-2: Handoff output files would be blocked - FIXED by adding handoff-*.md exclusion
3. Security: Path traversal NOT exploitable, regex injection NOT exploitable

## Approval Decision
APPROVED (after iteration 2)

# Expediter Section

## Validation Results
- Shellcheck: PASS (no errors, pre-existing warnings only)
- Functional tests: 8/8 PASS
- Content verification: PASS

## Quality Gate Decision
APPROVE

# Changelog

## [2025-12-02] - Coordinator
- Ticket created as follow-up to TICKET-qc-hook-fix-001

## [2025-12-02] - code-developer
- Implemented all three parts
- Iteration 2: Fixed terminology and handoff exclusion

## [2025-12-02] - code-reviewer
- Initial audit found 2 HIGH issues
- Re-audit confirmed fixes, APPROVED

## [2025-12-02] - code-tester
- All 8 functional tests passed
- APPROVED and moved to completed

## [2025-12-02] - Coordinator
- **PROCESS NOTE**: Work done on main instead of worktree - violation of workflow
- Need to implement ticket validator to prevent this
