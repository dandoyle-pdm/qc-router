---
# Metadata
ticket_id: TICKET-qc-observer-agent-001
session_id: qc-observer-agent
sequence: 001
parent_ticket: TICKET-qc-observer-001
title: Implement QC Observer Agent in qc-router
cycle_type: development
status: approved
created: 2025-12-07 18:00
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/feature-qc-observer-agent
---

# Requirements

## What Needs to Be Done
Create the qc-observer agent definition in qc-router. This agent analyzes captured observations and generates improvement recommendations.

## Acceptance Criteria
- [x] agents/qc-observer/AGENT.md - Agent definition (≤50 lines)
- [x] Agent can analyze violation patterns from ~/.novacloud/observations/
- [x] Agent generates improvement prompts when threshold (3x) met
- [x] Agent follows single-responsibility principle

# Context

## Agent Role
The qc-observer agent is invoked to:
1. Analyze accumulated observations
2. Identify recurring violation patterns
3. Generate targeted improvement prompts
4. Recommend changes to qc-router, workflow-guard, or project practices

## Not Real-Time
Unlike hooks (which fire automatically), this agent is invoked on-demand:
- Manually when user wants analysis
- After SessionEnd when patterns accumulate
- Via skill that triggers analysis

## Observation Types It Analyzes

| Type | What It Means |
|------|---------------|
| quality_bypass | Code modification without quality agent |
| artifact_standard | >50 lines, multi-responsibility |
| git_workflow | Direct commit to main, skip PR |
| ticket_lifecycle | Missing ticket, broken chain |
| agent_behavior | Wrong agent for phase, role breach |

# Implementation Notes

## Creator Section

### What Was Built
Created `agents/qc-observer/AGENT.md` - a minimal utility agent definition (49 lines, within 50-line limit).

### Design Decisions
1. **Model: sonnet** - Analysis task, not heavy creation; appropriate for pattern matching
2. **Single-responsibility** - Only analyzes observations and generates prompts; does NOT capture observations (that's the hooks' job)
3. **Minimal footprint** - 49 lines vs 200-340 lines for cycle agents; utility agents need less ceremony
4. **Threshold-based** - Only generates prompts when 3+ occurrences detected (avoids noise)

### Structure
- Frontmatter (5 lines): name, description, model, invocation
- Intro (2 lines): Purpose statement
- How to Invoke (9 lines): Simple invocation template
- Core Process (5 lines): 4-step workflow
- Output Format (11 lines): Improvement prompt template
- Observation Types (6 lines): Reference table

### Changes Made
- `agents/qc-observer/AGENT.md` - New file (49 lines)
- Commit: `ee39b2b` - feat: add qc-observer agent for pattern analysis and improvement prompts

### Status Update
[2025-12-07 22:30] - Changed status to critic_review

## Critic Section

### Audit Findings

**Total Issues Found**: 5 (CRITICAL: 0, HIGH: 1, MEDIUM: 4)

#### HIGH Priority

**Issue 1: Observation Directory Path Inconsistency**
- **Location**: `agents/qc-observer/AGENT.md:25` and lines 45-49
- **Problem**: Agent's observation types table doesn't align with use case documentation. The ticket defines observation types as `quality_bypass`, `artifact_standard`, `git_workflow`, `ticket_lifecycle`, `agent_behavior` but the agent's table shows different categories (`quality_bypass`, `blocking`, `patterns`) that are directories, not types.
- **Recommendation**: Align the agent's Observation Types table to match either the ticket's violation types OR the directory structure from use case doc, with clear mapping between them.

#### MEDIUM Priority

**Issue 2: Missing Error Handling Guidance**
- Agent lacks guidance for error scenarios (missing directory, malformed files, invalid Focus)
- Recommendation: Add brief note about error handling output

**Issue 3: Focus Parameter Values Not Documented**
- Invocation shows `[quality-cycle | blocking | patterns | all]` without explaining what each means
- Recommendation: Add brief descriptions of focus options

**Issue 4: Threshold Value Not Configurable**
- Threshold "3+" is hardcoded; use case doc shows it's configurable in ruleset
- Acceptable for 50-line constraint but worth noting

**Issue 5: Output Format Simplified**
- Output format is minimal compared to use case doc's detailed format
- Acceptable given line constraints

### Strengths Observed
1. Line count compliance (49 lines, meets 50-line standard)
2. Single-responsibility adherence (analysis only, not capture)
3. Appropriate model selection (sonnet for analysis)
4. Clear frontmatter following established patterns
5. Minimal but functional structure

### Approval Decision
**NEEDS_CHANGES**

### Rationale
The HIGH priority issue regarding observation type/directory inconsistency could cause confusion when the agent is invoked. The table in the agent doesn't match the ticket's observation types or provide clear mapping to the storage directories. This is a documentation alignment issue that should be resolved before approval.

MEDIUM issues are acceptable for a utility agent under line constraints but noted for future improvement.

### Status Update
[2025-12-07 23:15] - Changed status to expediter_review

## Expediter Section

### Validation Results

- **Required Sections Check**: PASSED - "How to Invoke" section present
- **Model Specification**: PASSED - `model: sonnet` in frontmatter
- **Frontmatter Completeness**: PASSED - All required fields present (name, description, model, invocation)
- **Line Count**: PASSED - 49 lines (within 50-line limit)
- **Invocation Template**: PASSED - Template present with clear task/focus structure

### Quality Gate Decision

**APPROVE**

### Evaluation of Critic's HIGH Priority Issue

The critic identified "Observation Directory Path Inconsistency" as a HIGH issue, claiming the agent's table doesn't align with the ticket or use case doc.

**Judge Assessment:** Upon careful review, the agent's table IS correct and aligns with the use case documentation:

1. **Use case doc (lines 75-82, 364-367)** defines storage directories as:
   - `quality-cycle/` - Quality cycle violations
   - `blocking/` - Patterns that block operations
   - `patterns/` - Improvement opportunities

2. **Agent's table** maps:
   - `quality_bypass` -> `quality-cycle/` directory
   - `blocking` -> `blocking/` directory
   - `patterns` -> `patterns/` directory

3. **Ticket's table** lists violation subtypes (quality_bypass, artifact_standard, git_workflow, etc.) which are *content within* the directories, not the directories themselves.

These are different levels of abstraction and both are valid. The agent correctly references the storage architecture. The ticket mentions violation categories. The critic confused the two hierarchies.

**Verdict on HIGH issue:** Not a genuine inconsistency. Dismissed.

### Acceptance Criteria Verification

- [x] `agents/qc-observer/AGENT.md` exists (49 lines, within 50-line limit)
- [x] Agent can analyze `~/.novacloud/observations/` - invocation specifies path, core process reads from subdirectories
- [x] Agent generates improvement prompts at threshold (3+) - documented in intro and step 3
- [x] Single-responsibility principle followed - analysis only, not capture

### Deferred Items for Follow-up

MEDIUM issues noted by critic (acceptable for 50-line utility agent):
- Error handling guidance (can add to skill or reference docs)
- Focus parameter descriptions (self-evident from directory names)
- Threshold configurability (ruleset handles this)
- Output format simplification (appropriate for agent brevity)

### Approval Rationale

All validation checks pass. The only HIGH issue raised by the critic was based on a misreading of the documentation hierarchy - the agent's table correctly maps observation types to storage directories as defined in the use case doc. Line count compliance, single-responsibility, proper frontmatter, and invocation template all meet quality standards. MEDIUM issues are appropriate deferrals for a minimal utility agent.

### Status Update
[2025-12-07 23:45] - Changed status to approved

## Changelog
### [2025-12-07 23:45] - Expediter
- Validation completed: All checks passed
- HIGH issue dismissed: Agent table aligns with use case doc storage architecture
- Decision: APPROVE
- Status changed to approved

### [2025-12-07 23:15] - Critic
- Audit completed
- Issues found: 0 CRITICAL, 1 HIGH, 4 MEDIUM
- Decision: NEEDS_CHANGES
- HIGH: Observation types table doesn't align with ticket or use case doc
- Status changed to expediter_review

### [2025-12-07 22:30] - Creator
- Created agents/qc-observer/AGENT.md (49 lines)
- Single-responsibility utility agent
- Status changed to critic_review

# References
- Use case doc: docs/QC-OBSERVER-USE-CASES.md
- Parent tickets: TICKET-qc-observer-001, TICKET-qc-observer-002
- Sibling ticket: TICKET-qc-observer-003 (hooks in workflow-guard)
