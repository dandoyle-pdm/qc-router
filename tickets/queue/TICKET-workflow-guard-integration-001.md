---
# Metadata
ticket_id: TICKET-workflow-guard-integration-001
session_id: workflow-guard-integration
sequence: 001
parent_ticket: null
title: Document qc-router integration with workflow-guard plugin
cycle_type: documentation
status: critic_review
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

Implemented documentation for qc-router integration with workflow-guard plugin as specified.

**README.md updates:**
- Added "Integration with workflow-guard" section after "Workflow Pattern" and before "Configuration"
- Documented how workflow-guard blocks file modifications unless quality agent detected
- Explained the agent identity marker pattern: "working as the {agent-name} agent"
- Listed all 12 recognized quality agents organized by cycle (Code, Documentation, Prompt, Plugin)
- Included compatibility maintenance guidelines (3 points for AGENT.md modifications)

**DEVELOPER.md updates:**
- Added "Agent Identity Pattern (CRITICAL)" section to "Adding or Modifying Agents"
- Added examples table showing identity strings from code-developer, tech-writer, plugin-engineer
- Added explanatory note about why identity patterns matter for workflow-guard integration
- Added comprehensive "Sister Project: workflow-guard" section before "Additional Resources" including:
  - Dependency direction mermaid diagram showing workflow-guard depends on qc-router
  - Integration mechanism sequence diagram showing the full flow from user request through Task tool to workflow-guard hook verification
  - Breaking changes to avoid (3 numbered items)
  - Process for adding new quality agents (4 numbered steps)
  - Current recognized agents table (4 cycles x 3 roles = 12 agents)

## Questions/Concerns

None. All acceptance criteria addressed as specified. Existing DEVELOPER.md was comprehensive so I extended it rather than replacing it.

## Changes Made
- File changes:
  - `README.md` - Added integration section (~50 lines)
  - `DEVELOPER.md` - Added agent identity pattern section (~20 lines) and sister project section (~90 lines)
- Commits:
  - `ff2ab02` - docs: add workflow-guard integration documentation

**Status Update**: [2025-12-03 23:15] - Changed status to `critic_review`

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

## [2025-12-03 23:15] - tech-writer
- Implemented README.md integration section with all acceptance criteria
- Extended DEVELOPER.md with agent identity pattern and sister project sections
- Added mermaid diagrams (dependency direction, integration mechanism sequence)
- Committed changes: ff2ab02
- Status changed to critic_review

## [2025-12-03 22:30] - Coordinator
- Ticket created with full context from audit
- Identified all 12 agents have identity patterns
- Ready for tech-writer to implement documentation
