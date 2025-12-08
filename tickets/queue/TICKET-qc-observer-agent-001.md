---
# Metadata
ticket_id: TICKET-qc-observer-agent-001
session_id: qc-observer-agent
sequence: 001
parent_ticket: TICKET-qc-observer-001
title: Implement QC Observer Agent in qc-router
cycle_type: development
status: open
created: 2025-12-07 18:00
worktree_path: null
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
[To be filled by plugin-engineer]

# References
- Use case doc: docs/QC-OBSERVER-USE-CASES.md
- Parent tickets: TICKET-qc-observer-001, TICKET-qc-observer-002
- Sibling ticket: TICKET-qc-observer-003 (hooks in workflow-guard)
