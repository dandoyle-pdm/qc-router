---
# Metadata
ticket_id: TICKET-loop1-enhancement-001
session_id: loop1-enhancement
sequence: 001
parent_ticket: null
title: Enhance Loop 1 with ARC-AGI iteration patterns
cycle_type: development
status: critic_review
created: 2025-12-09 20:00
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/loop1-enhancement
---

# Requirements

## What Needs to Be Done

Enhance the within-cycle iteration model (Loop 1) to incorporate ARC-AGI self-learning patterns. When Judge routes back, it creates a NEW ticket with incremented index containing structured feedback and attempt history, enabling Developer to learn from previous attempts.

## Problem Statement

Current route-back model:
- Judge creates new ticket with issues list
- No structured expected/actual comparison
- No cumulative history of attempts
- No iteration limits with escalation
- Developer starts fresh without context of what was tried

ARC-AGI insight: "When code fails, we don't just say 'wrong.' We show exactly what was expected vs actual, plus accuracy score."

## Acceptance Criteria

- [ ] Ticket schema supports iteration metadata (index, max, parent_ticket)
- [ ] Ticket schema supports attempt_history section
- [ ] Ticket schema supports structured_feedback with expected/actual/score
- [ ] code-tester creates route-back tickets with full history propagation
- [ ] code-tester escalates when iteration.index >= iteration.max (default: 5)
- [ ] code-developer reads attempt_history before implementing
- [ ] code-reviewer generates structured findings compatible with feedback schema
- [ ] Documentation updated to reflect new iteration model

# Context

## The Three Loops

1. **Loop 1 (This Ticket)**: Within-cycle iteration - ticket-scoped, short-lived
2. **Loop 2**: Cross-cycle agent tuning - project-agnostic, long-lived
3. **Loop 3**: Outcome validation - system calibration over time

Loop 1 is the ARC-AGI parallel: "up to 10 tries to refine logic, most solved by iteration 3-5"

## Current Model (Agents Never Loop)

```
TICKET-session-001 → Developer → Reviewer → Tester → ROUTE_BACK
                                                          │
                                                          ▼
TICKET-session-002 → Developer → Reviewer → Tester → APPROVE
```

Each iteration is a NEW ticket. The ticket index IS the iteration counter.

## Enhanced Model

```
TICKET-session-001 (iteration: 1/5)
    → Developer implements
    → Reviewer audits (structured findings)
    → Tester routes back with:
        - Structured feedback (expected/actual/score)
        - Attempt history
        - Specific guidance
                    │
                    ▼
TICKET-session-002 (iteration: 2/5, parent: 001)
    → Developer reads history, focuses on gaps
    → Reviewer builds on previous audit
    → Tester approves OR creates 003
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
    APPROVE              TICKET-session-003...
                                │
                    (if iteration >= 5)
                                ▼
                           ESCALATE
```

## Files to Modify

| File | Change |
|------|--------|
| `agents/code-tester/AGENT.md` | Route-back ticket creation with history + structured feedback |
| `agents/code-developer/AGENT.md` | Read and utilize attempt_history |
| `agents/code-reviewer/AGENT.md` | Generate structured findings format |
| `docs/observer/cycles/code-cycle.md` | Document enhanced iteration model |
| `docs/observer/PHILOSOPHY.md` | Add Loop 1/2/3 distinction |

## Structured Feedback Schema

Route-back ticket must include:

```yaml
iteration:
  index: 2
  max: 5
  parent_ticket: TICKET-session-001
  accuracy_score: 0.6

attempt_history:
  - ticket: TICKET-session-001
    outcome: route_back
    accuracy: 0.3
    gaps: ["no tests", "no error handling"]

structured_feedback:
  - requirement: "error handling"
    expected: "try/catch around API calls"
    actual: "no error handling"
    score: 0.0
    guidance: "Wrap lines 42-58 in try/catch"
  - requirement: "test coverage"
    expected: "80% line coverage"
    actual: "40% line coverage"
    score: 0.5
    guidance: "Add tests for error paths"
```

## ARC-AGI Principles Applied

| Principle | Application |
|-----------|-------------|
| "Show visual diff" | Structured feedback with expected/actual/score |
| "Up to 10 tries" | Iteration limit (default 5) with escalation |
| "Each iteration sees previous attempts" | attempt_history propagation |
| "Accuracy score" | Per-requirement scores + overall accuracy |
| "Specific guidance" | Concrete next steps, not just issue lists |

# Implementation Notes

## Creator Section

### Implementation Notes

Enhanced the three code quality cycle agents with ARC-AGI inspired iteration patterns:

**code-tester (Judge)**:
- Added "Loop 1: Iteration with Structured Feedback" section
- Documented route-back ticket creation with iteration metadata (index, max, parent_ticket, accuracy_score)
- Added Attempt History section template for cumulative learning
- Defined Structured Feedback section with expected/actual/score/guidance per requirement
- Implemented escalation protocol when iteration.index >= iteration.max
- Added complete route-back workflow and output format

**code-developer (Creator)**:
- Added "Loop 1: Learning from Previous Iterations" section
- Instructions to read iteration metadata from frontmatter
- Guidance for parsing Attempt History section
- Instructions for using Structured Feedback with expected/actual/score/guidance
- Enhanced iteration protocol for targeting low-scoring requirements
- Added pattern recognition for persistent gaps

**code-reviewer (Critic)**:
- Added "Loop 1: Structured Findings for Iteration Support" section
- Defined Structured Findings Format with expected/actual/status tables per requirement
- Added Gap Analysis and Remediation guidance
- Instructions for mapping issues to acceptance criteria
- Iteration-aware review with progress tracking from previous attempts
- Enhanced output format with Structured Findings Summary section

**Documentation**:
- Created `docs/observer/PHILOSOPHY.md` documenting three-layer observation model (Loop 1/2/3)
- Created `docs/observer/cycles/code-cycle.md` with complete Loop 1 iteration documentation

### Questions/Concerns

None - implementation follows the specified requirements and ARC-AGI principles.

### Changes Made

| File | Change Type | Commit |
|------|-------------|--------|
| `agents/code-tester/AGENT.md` | Enhanced | 1c36cf9 |
| `agents/code-developer/AGENT.md` | Enhanced | 94fea3c |
| `agents/code-reviewer/AGENT.md` | Enhanced | d391b22 |
| `docs/observer/cycles/code-cycle.md` | Created | beae7d5 |
| `docs/observer/PHILOSOPHY.md` | Created | 26ae8a7 |

### Status Update
[2025-12-09 22:10] - Changed status to critic_review

## Critic Section
_To be filled during review_

## Expediter Section
_To be filled during validation_

## Changelog
### [2025-12-09 22:10] - Creator
- Implemented Loop 1 enhancements across all three code cycle agents
- Created documentation for observation philosophy and code cycle
- 5 commits made, all acceptance criteria addressed
- Status changed to critic_review

### [2025-12-09 21:15] - Ticket Activated
- Created branch: feature/loop1-enhancement
- Created worktree: /home/ddoyle/workspace/worktrees/qc-router/loop1-enhancement
- Moved ticket to tickets/active/feature-loop1-enhancement/
- Status changed to in_progress
- Delegating to code-developer agent

### [2025-12-09 20:00] - Ticket Created
- Identified Loop 1 enhancement requirements
- Defined structured feedback schema
- Scoped to code quality cycle (tech/prompt/plugin cycles can follow same pattern)
- Research: ARC-AGI article, observer documentation analysis

# References
- research/agentic-self-learning.md - ARC-AGI breakthrough article
- docs/observer/PHILOSOPHY.md - 3-layer observation model
- docs/observer/cycles/code-cycle.md - Current cycle documentation
- docs/observer/transformers/*.md - Agent observation rules
