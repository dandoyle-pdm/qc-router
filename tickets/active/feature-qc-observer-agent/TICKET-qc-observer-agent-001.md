---
# Metadata
ticket_id: TICKET-qc-observer-agent-001
session_id: qc-observer-agent
sequence: 001
parent_ticket: TICKET-qc-observer-001
title: Implement QC Observer Agent in qc-router
cycle_type: development
status: critic_review
created: 2025-12-07 18:00
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/feature-qc-observer-agent
---

# Requirements

## What Needs to Be Done
Create the qc-observer agent definition in qc-router. This agent analyzes captured observations and generates improvement recommendations.

## Acceptance Criteria
- [ ] agents/qc-observer/AGENT.md - Agent definition (≤50 lines)
- [ ] Agent can analyze violation patterns from ~/.novacloud/observations/
- [ ] Agent generates improvement prompts when threshold (3x) met
- [ ] Agent follows single-responsibility principle

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

## Changelog
### [2025-12-07 22:30] - Creator
- Created agents/qc-observer/AGENT.md (49 lines)
- Single-responsibility utility agent
- Status changed to critic_review

# References
- Use case doc: docs/QC-OBSERVER-USE-CASES.md
- Parent tickets: TICKET-qc-observer-001, TICKET-qc-observer-002
- Sibling ticket: TICKET-qc-observer-003 (hooks in workflow-guard)
