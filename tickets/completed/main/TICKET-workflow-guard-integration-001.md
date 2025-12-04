---
# Metadata
ticket_id: TICKET-workflow-guard-integration-001
session_id: workflow-guard-integration
sequence: 001
parent_ticket: null
title: Document qc-router integration with workflow-guard plugin
cycle_type: documentation
status: approved
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
None identified.

### HIGH Issues
None identified.

### MEDIUM Issues
- [ ] `README.md:9` - Feature count inconsistency: README states "9 Specialized Agents" but actually documents 12 agents (4 cycles x 3 agents). The integration section correctly lists 12 agents, but the Features section needs updating.

## Editorial Checklist

### Technical Accuracy
- [x] Agent identity patterns verified against actual AGENT.md files (spot-checked code-developer, tech-writer, plugin-engineer)
- [x] Identity string format "working as the {agent-name} agent" is accurate
- [x] All 12 agents correctly listed by cycle (Code, Documentation, Prompt, Plugin)
- [x] Integration mechanism described correctly (workflow-guard reads transcripts for identity markers)
- [x] Breaking changes guidance is accurate (identity pattern location, agent renaming)

### Completeness
- [x] README.md documents the integration mechanism clearly
- [x] README.md lists all 12 recognized agents organized by cycle
- [x] README.md includes 3 compatibility maintenance guidelines
- [x] DEVELOPER.md includes agent identity pattern section with examples table
- [x] DEVELOPER.md includes sister project section with dependency diagram
- [x] DEVELOPER.md includes integration sequence diagram
- [x] DEVELOPER.md lists breaking changes to avoid (3 items)
- [x] DEVELOPER.md documents process for adding new agents (4 steps)
- [x] DEVELOPER.md includes current recognized agents table (4x3 = 12)

### Clarity
- [x] README.md integration section follows existing document structure and style
- [x] Step-by-step "How It Works" explanation is clear and understandable
- [x] Code examples show concrete identity string patterns
- [x] Guidelines are actionable for developers modifying AGENT.md files
- [x] DEVELOPER.md cross-references README for user-facing details appropriately

### Coherency
- [x] Style matches existing README.md sections (heading levels, table formatting)
- [x] DEVELOPER.md section placement logical (before Additional Resources)
- [x] Internal cross-reference anchor `#sister-project-workflow-guard` works correctly
- [x] Terminology consistent ("identity pattern", "identity string", "identity marker" - acceptable variation)

### Mermaid Diagrams
- [x] Dependency direction diagram is accurate and visually clear
- [x] Sequence diagram correctly shows the full integration flow
- [x] Diagram styling is appropriate (colors, stroke widths)
- [x] Diagrams are not overly complex

### Cross-References
- [x] DEVELOPER.md links to README.md appropriately
- [x] Internal anchor link in DEVELOPER.md for agent identity pattern section
- [x] Path references to workflow-guard plugin location are correct

### Acceptance Criteria Review
- [x] README.md contains integration section explaining how workflow-guard detects agents
- [x] README.md documents the identity pattern: "working as the {name} agent"
- [x] README.md lists all 12 recognized quality agents
- [x] README.md includes compatibility maintenance guidelines
- [x] DEVELOPER.md exists with technical documentation
- [x] DEVELOPER.md contains sister project section with dependency diagram
- [x] DEVELOPER.md documents breaking changes to avoid
- [x] DEVELOPER.md explains how to add new quality agents

## Approval Decision
APPROVED

## Rationale
The documentation meets all acceptance criteria and passes the editorial checklist. Technical accuracy was verified by spot-checking actual AGENT.md files against documented patterns. The mermaid diagrams are accurate and helpful. The only issue is a MEDIUM-severity inconsistency in the README Features section (9 agents vs 12 agents), which is pre-existing and outside the scope of this ticket's requirements. The integration section itself correctly documents all 12 agents.

The documentation is clear, complete, and maintains coherency with the existing document style. A developer can follow these guidelines to maintain compatibility with workflow-guard.

**Status Update**: [2025-12-04 03:45] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: N/A (documentation only)
- Linting: PASS (markdown formatting verified)
- Type checking: N/A
- Security scans: N/A
- Build: N/A

## Quality Gate Decision
APPROVE

## Rationale

All 8 acceptance criteria verified and satisfied:

1. README.md integration section (lines 111-159) clearly explains workflow-guard detection mechanism
2. Identity pattern documented with example ("working as the {agent-name} agent")
3. All 12 quality agents listed by cycle (Code, Documentation, Prompt, Plugin)
4. Compatibility maintenance guidelines provided (3 actionable items)
5. DEVELOPER.md exists with 590 lines of technical documentation
6. Sister project section includes dependency direction diagram and sequence diagram
7. Breaking changes to avoid documented (3 numbered items)
8. Process for adding new quality agents documented (4 numbered steps)

**Pre-existing Issue Acknowledged**: README Features section states "9 Specialized Agents" but 12 exist. This is out of scope for this ticket and should be addressed separately.

## Next Steps

1. Merge commit `ff2ab02` (docs: add workflow-guard integration documentation)
2. Move ticket to `tickets/completed/main/` directory
3. Consider creating follow-up ticket for README feature count correction (optional)

**Status Update**: [2025-12-04 04:15] - Changed status to `approved`

# Changelog

## [2025-12-04 04:15] - tech-publisher
- Validated all 8 acceptance criteria satisfied
- Verified documentation serves plugin developers and maintainers
- Confirmed coherency with existing documentation patterns
- Acknowledged pre-existing MEDIUM issue (9 vs 12 agents) as out of scope
- Decision: APPROVED
- Status changed to approved

## [2025-12-04 03:45] - tech-editor
- Performed editorial review of workflow-guard integration documentation
- Verified technical accuracy by spot-checking AGENT.md files (code-developer, tech-writer, plugin-engineer)
- Completed full editorial checklist: accuracy, completeness, clarity, coherency, diagrams, cross-references
- Identified 1 MEDIUM issue (pre-existing: README Features says 9 agents, should be 12)
- All acceptance criteria satisfied
- Decision: APPROVED
- Status changed to expediter_review

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
