---
# Metadata
ticket_id: TICKET-loop1-enhancement-001
session_id: loop1-enhancement
sequence: 001
parent_ticket: null
title: Enhance Loop 1 with ARC-AGI iteration patterns
cycle_type: development
status: open
created: 2025-12-09 20:00
worktree_path: null
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
_To be filled during implementation_

## Critic Section
_To be filled during review_

## Expediter Section
_To be filled during validation_

## Changelog
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
