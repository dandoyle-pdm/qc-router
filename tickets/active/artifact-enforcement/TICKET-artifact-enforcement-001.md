---
ticket_id: TICKET-artifact-enforcement-001
session_id: artifact-enforcement
title: Enhance quality agents with 50-line artifact validation
cycle_type: development
status: in_progress
created: 2025-12-08
activated: 2025-12-12
branch: ticket/artifact-enforcement
worktree: /home/ddoyle/.novacloud/worktrees/qc-router/artifact-enforcement
---

# Requirements

## What Needs to Be Done

Enhance qc-router quality agents to systematically validate the 50-line artifact standard during quality cycles. This complements the workflow-guard hook enforcement with quality-cycle-based validation.

**The Standard:**
```
Single-Responsibility + 50 Lines = Artifact Standard

All artifacts (code, docs, tickets) MUST be:
- Complete within their responsibility
- Single-responsibility (one reason to change)
- ≤50 substantive lines (excluding blanks, comments, metadata)
```

## Acceptance Criteria

- [ ] Update `code-reviewer/AGENT.md` with explicit 50-line check in CRITICAL issues
- [ ] Update `tech-editor/AGENT.md` with 50-line check for documentation
- [ ] Update `plugin-reviewer/AGENT.md` with 50-line check for plugin artifacts
- [ ] Add validation command snippet agents can use to count lines
- [ ] Reference `ARTIFACT_SPEC.md` and splitting strategy in agent guidance
- [ ] Ensure severity is HIGH (not just MEDIUM) for violations
- [ ] Test with sample artifacts exceeding limit

# Context

## Why This Work Matters

The 50-line rule is a **forcing function** that:
- Pushes details into downstream documents (hierarchy emerges from splits)
- Forces single-responsibility boundaries
- Forces complete-but-concise artifacts
- Prevents scope creep and monolithic files

**Layered Enforcement:**
1. **workflow-guard** (hard stop) - PreToolUse hook blocks writes exceeding limit
2. **qc-router** (soft check) - Quality agents flag violations during review

Both layers needed because:
- Hooks catch violations at write time
- Agents catch violations in existing code being reviewed
- Agents provide nuanced judgment on exceptions

## What Already Exists

**In code-reviewer/AGENT.md (line 163):**
```markdown
Functions too long (>50 lines typically indicates need to decompose)
```

This is MEDIUM priority and only mentions functions. Need to:
- Elevate to HIGH priority
- Apply to ALL artifacts (files, not just functions)
- Reference ARTIFACT_SPEC.md

**In docs project:**
- `ARTIFACT_SPEC.md` (44 lines) - the specification
- `guides/artifacts/validation-checklist.md` - validation commands
- `guides/artifacts/splitting-strategy.md` - how to split

## References

- Specification: `/home/ddoyle/docs/ARTIFACT_SPEC.md`
- Validation guide: `/home/ddoyle/docs/guides/artifacts/validation-checklist.md`
- Splitting strategy: `/home/ddoyle/docs/guides/artifacts/splitting-strategy.md`
- code-reviewer: `/home/ddoyle/.claude/plugins/qc-router/agents/code-reviewer/AGENT.md`
- tech-editor: `/home/ddoyle/.claude/plugins/qc-router/agents/tech-editor/AGENT.md`
- plugin-reviewer: `/home/ddoyle/.claude/plugins/qc-router/agents/plugin-reviewer/AGENT.md`

## Implementation Guidance

### Line Count Validation Command

Add to each reviewer agent's toolkit:

```bash
# Count substantive lines (non-blank, non-comment)
grep -cvE '^[[:space:]]*(#|//|/\*|\*|$)' <file>

# For markdown (exclude blank lines)
grep -cv '^$' <file>.md

# Quick check if over limit
lines=$(grep -cv '^$' <file>); [ "$lines" -gt 50 ] && echo "OVER: $lines lines"
```

### code-reviewer/AGENT.md Updates

**Add to CRITICAL Issues section:**

```markdown
### Artifact Size Violations
- **CRITICAL** if file >50 substantive lines AND contains multiple responsibilities
- **HIGH** if file >50 substantive lines but single responsibility (needs split)
- Validate with: `grep -cvE '^[[:space:]]*(#|//|/\*|\*|$)' <file>`
- Reference: ARTIFACT_SPEC.md - "Single-Responsibility + 50 Lines = Artifact Standard"
- Guidance: See /home/ddoyle/docs/guides/artifacts/splitting-strategy.md
```

**Update existing function length check (line ~163):**

```markdown
~~Functions too long (>50 lines typically indicates need to decompose)~~

**HIGH Priority - Artifact Size:**
- Files exceeding 50 substantive lines (ARTIFACT_SPEC violation)
- Functions exceeding 50 lines (decomposition needed)
- Classes with >3 responsibilities (SRP violation)
- Guidance: Split into single-responsibility artifacts, each ≤50 lines
```

### tech-editor/AGENT.md Updates

**Add to CRITICAL Issues section:**

```markdown
### Documentation Size Violations
- **HIGH** if document section >100 lines (DOCUMENTS.md violation)
- **HIGH** if standalone document >50 substantive lines without downstream refs
- Check document structure: Does it reference downstream guides for detail?
- Reference: ARTIFACT_SPEC.md - all artifacts ≤50 lines
- Guidance: Extract detail to guides/, keep root document as overview + links
```

### plugin-reviewer/AGENT.md Updates

**Add to audit checklist:**

```markdown
### Artifact Size (ARTIFACT_SPEC.md)
- [ ] Each hook script ≤50 substantive lines
- [ ] Each AGENT.md ≤50 substantive lines (excluding examples)
- [ ] Configuration files split by concern
- [ ] SKILL.md overview ≤50 lines, detail in references/
- Validation: `grep -cvE '^[[:space:]]*(#|//|$)' <file>`
- If exceeds: Document justification OR split into focused artifacts
```

### Exception Handling

Agents should recognize valid exceptions:
- Test fixtures and snapshots
- Generated code
- Reference tables (data, not logic)
- HTML templates (structural necessity)

**Exception documentation format:**
```markdown
<!-- ARTIFACT_SPEC Exception: [reason] -->
```

# Creator Section

## Implementation Notes
[To be filled by code-developer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

# Critic Section

## Audit Findings
[To be filled by code-reviewer]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
[To be filled by code-tester]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

**Status Update**: [Date/time] - Changed status to `approved`

# Changelog

## [2025-12-12] - Ticket Activated
- Moved from queue/ to active/artifact-enforcement/
- Created worktree: /home/ddoyle/.novacloud/worktrees/qc-router/artifact-enforcement
- Branch: ticket/artifact-enforcement
- Status: in_progress

## [2025-12-08] - Ticket Created
- Created from docs project ARTIFACT_SPEC.md work
- Complements workflow-guard hook enforcement
- Quality cycle: R1 (code-developer → code-reviewer → code-tester)
