---
# Metadata
ticket_id: TICKET-workflow-guard-integration-001
session_id: workflow-guard-integration
sequence: 001
parent_ticket: null
title: Document qc-router integration with workflow-guard plugin
cycle_type: documentation
status: open
created: 2025-12-03 22:30
worktree_path: null
---

# Requirements

## What Needs to Be Done

Document how qc-router agents integrate with the workflow-guard plugin. The workflow-guard plugin depends on qc-router agent identity patterns to detect quality context and enforce quality cycle requirements.

**Files to update/create:**
1. `README.md` - Add "Integration with workflow-guard" section
2. `DEVELOPER.md` - Create file with sister project documentation

## Acceptance Criteria

- [ ] README.md contains integration section explaining how workflow-guard detects agents
- [ ] README.md documents the identity pattern: "working as the {agent-name} agent"
- [ ] README.md lists all 12 recognized quality agents
- [ ] README.md includes compatibility maintenance guidelines
- [ ] DEVELOPER.md exists with technical documentation
- [ ] DEVELOPER.md contains sister project section with dependency diagram
- [ ] DEVELOPER.md documents breaking changes to avoid
- [ ] DEVELOPER.md explains how to add new quality agents

# Context

## Why This Work Matters

The workflow-guard plugin (`~/.claude/plugins/workflow-guard/`) is a sister project that enforces git branch protection and quality cycle requirements. Its hooks read qc-router agent transcripts to detect when a quality agent is active, allowing file modifications only within quality cycle context.

Without this documentation:
- Maintainers may inadvertently break the identity pattern
- New agents may be created without proper identity markers
- The integration dependency is undocumented and fragile

## Agent Identity Pattern Analysis

All 12 agents already have the identity pattern in their invocation templates:

**Code cycle agents:**
- code-developer: "You are a pragmatic software developer working as the code-developer agent in a quality cycle workflow."
- code-reviewer: "You are a meticulous code reviewer working as the code-reviewer agent in a quality cycle workflow."
- code-tester: "You are the judge working as the code-tester agent in a quality cycle workflow."

**Documentation cycle agents:**
- tech-writer: "You are a technical writer working as the tech-writer agent in a documentation quality cycle workflow."
- tech-editor: "You are a meticulous technical editor working as the tech-editor agent in a documentation quality cycle workflow."
- tech-publisher: "You are the judge working as the tech-publisher agent in a documentation quality cycle workflow."

**Prompt engineering cycle agents:**
- prompt-engineer: "You are a prompt engineering specialist working as the prompt-engineer agent in a quality cycle workflow."
- prompt-reviewer: "You are a meticulous prompt reviewer working as the prompt-reviewer agent in a quality cycle workflow."
- prompt-tester: "You are the judge working as the prompt-tester agent in a quality cycle workflow."

**Plugin cycle agents:**
- plugin-engineer: "You are a pragmatic plugin developer working as the plugin-engineer agent in a quality cycle workflow."
- plugin-reviewer: "You are a meticulous plugin reviewer working as the plugin-reviewer agent in a quality cycle workflow."
- plugin-tester: "You are the judge working as the plugin-tester agent in a quality cycle workflow."

**Key pattern:** All contain "working as the {agent-name} agent" which workflow-guard can grep for.

## References

- workflow-guard plugin: `~/.claude/plugins/workflow-guard/`
- workflow-guard DEVELOPER.md: Contains integration notes from the other side
- Agent definitions: `agents/*/AGENT.md` (12 agents)

# Creator Section

## Implementation Notes
[To be filled by tech-writer]

## Questions/Concerns
[To be filled by tech-writer]

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
- Automated tests: N/A (documentation only)
- Linting: [PASS/FAIL]
- Type checking: N/A
- Security scans: N/A
- Build: N/A

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-03 22:30] - Coordinator
- Ticket created with full context from audit
- Identified all 12 agents have identity patterns
- Ready for tech-writer to implement documentation
