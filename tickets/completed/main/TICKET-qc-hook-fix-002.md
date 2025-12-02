---
# Metadata
ticket_id: TICKET-qc-hook-fix-002
session_id: qc-hook-fix
sequence: 002
parent_ticket: TICKET-qc-hook-fix-001
title: Extend enforcement to documents + ultrathink for transient content
cycle_type: development
status: open
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
- [ ] `.md` files (excluding `/tickets/`) trigger hook enforcement
- [ ] CLAUDE.md documents ultrathink requirement for tickets/handoffs
- [ ] Handoff slash commands specify ultrathink
- [ ] Test: Write to README.md without QC → blocked
- [ ] Test: Write to tickets/*.md without QC → allowed (ultrathink handles review)
- [ ] Shellcheck passes

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
[To be filled by code-developer agent]

## Changes Made
- File changes:
- Commits:

# Critic Section

## Audit Findings
[To be filled by code-reviewer agent]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

# Expediter Section

## Validation Results
[To be filled by code-tester agent]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

# Changelog

## [2025-12-02] - Coordinator
- Ticket created as follow-up to TICKET-qc-hook-fix-001
- Identified gap: ticket files and handoff prompts not covered by enforcement
