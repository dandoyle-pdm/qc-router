---
# Metadata
ticket_id: TICKET-loop1-enhancement-001
session_id: loop1-enhancement
sequence: 001
parent_ticket: null
title: Enhance Loop 1 with ARC-AGI iteration patterns
cycle_type: development
status: expediter_review
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

### Audit Summary

**Total Issues Found**: 7
- CRITICAL: 1
- HIGH: 3
- MEDIUM: 3

**Recommendation**: NEEDS_CHANGES

---

### Structured Findings Summary

#### Requirement: Ticket schema supports iteration metadata (index, max, parent_ticket)
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| code-tester documents iteration YAML | Full schema in route-back ticket | Lines 403-419 in code-tester/AGENT.md | PASS |
| code-developer reads iteration metadata | Instructions to parse frontmatter | Lines 229-238 in code-developer/AGENT.md | PASS |
| Template updated with iteration fields | TEMPLATE.md includes iteration section | TEMPLATE.md NOT updated | FAIL |

**Gap Analysis**: Agents document how to create/read iteration metadata, but ticket TEMPLATE.md not updated with iteration schema.

---

#### Requirement: Ticket schema supports attempt_history section
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| code-tester creates attempt_history | Template documented | Lines 424-440 | PASS |
| code-developer reads attempt_history | Instructions provided | Lines 242-259 | PASS |
| docs/code-cycle.md documents format | Complete documentation | Lines 93-109 | PASS |

**Gap Analysis**: None - well documented.

---

#### Requirement: Ticket schema supports structured_feedback with expected/actual/score
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| code-tester creates structured_feedback | Detailed template | Lines 442-476 | PASS |
| Expected/actual/score/guidance per requirement | Complete schema | Lines 452-458 tables | PASS |
| Overall accuracy score calculation | Formula documented | Line 475-476 | PASS |

**Gap Analysis**: None - well documented.

---

#### Requirement: code-tester creates route-back tickets with full history propagation
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| Route-back workflow documented | Complete workflow | Lines 534-546 | PASS |
| Parent ticket reading | Instructions to read parent | Lines 527-533 | PASS |
| Accumulated history | Append current to history | Line 531 | PASS |

**Gap Analysis**: None - comprehensive workflow.

---

#### Requirement: code-tester escalates when iteration.index >= iteration.max
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| Escalation protocol defined | Complete protocol | Lines 478-524 | PASS |
| Default max = 5 | Specified | Line 480 | PASS |
| Escalation output format | Complete format | Lines 489-524 | PASS |

**Gap Analysis**: None - well defined.

---

#### Requirement: code-developer reads attempt_history before implementing
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| Enhanced iteration protocol | Step-by-step guidance | Lines 289-299 | PASS |
| Pattern recognition | Persistent gap handling | Lines 301-314 | PASS |

**Gap Analysis**: None - comprehensive guidance.

---

#### Requirement: code-reviewer generates structured findings compatible with feedback schema
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| Structured Findings Format | Expected/Actual/Status tables | Lines 356-370 | PASS |
| Score compatibility with tester | Numeric scores expected | Uses PASS/FAIL status | PARTIAL |
| Iteration-aware review | Previous column for iterations | Lines 497-518 | PASS |

**Gap Analysis**: Reviewer outputs PASS/FAIL status, tester expects numeric scores (0.0-1.0). Conversion not documented.

---

#### Requirement: Documentation updated to reflect new iteration model
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| PHILOSOPHY.md created | Three-loop model documented | 167 lines created | PASS |
| code-cycle.md created | Loop 1 detailed | 189 lines created | PASS |

**Gap Analysis**: Documentation excellent. Loop 2/3 appropriately marked as future work.

---

### CRITICAL Issues

#### Issue 1: Ticket TEMPLATE.md Not Updated with Iteration Schema

**Severity**: CRITICAL
**Location**: Missing update to `tickets/TEMPLATE.md`
**Category**: Missing Implementation

**Analysis**:
The acceptance criterion states "Ticket schema supports iteration metadata." While agents document what iteration metadata looks like, the TEMPLATE.md file has NOT been updated. The qc-router plugin does not have its own TEMPLATE.md (relies on workflow-guard). This means:
1. New tickets won't have iteration fields documented in template
2. Developers creating route-back tickets won't have reference schema
3. "Schema supports" acceptance criterion not fully met

**Expected vs Actual**:
| Expected | Actual |
|----------|--------|
| TEMPLATE.md includes iteration YAML block | Only parent_ticket exists, no iteration block |
| Attempt History section in template | No such section in template |

**Recommendation**:
Either:
1. Create `tickets/TEMPLATE.md` in qc-router with iteration extensions, OR
2. Update workflow-guard TEMPLATE.md with optional iteration fields, OR
3. Document that iteration sections are ADDED dynamically (update acceptance criterion wording)

---

### HIGH Issues

#### Issue 1: Inconsistent Score vs Status Fields

**Severity**: HIGH
**Location**: `agents/code-reviewer/AGENT.md:364` vs `agents/code-tester/AGENT.md:453`
**Category**: Consistency

**Analysis**:
- code-reviewer outputs: `Status` column (PASS/FAIL)
- code-tester expects: `score` field (0.0-1.0)

No explicit conversion documented. Tester must infer PASS=1.0, FAIL=0.0.

**Recommendation**:
Document explicit conversion: "Reviewer PASS = score 1.0, FAIL = score 0.0, PARTIAL = score 0.5"

---

#### Issue 2: Missing Accuracy Score Calculation Details

**Severity**: HIGH
**Location**: `agents/code-tester/AGENT.md:475-476`
**Category**: Missing Implementation Details

**Analysis**:
Formula says "Average of all requirement scores" but doesn't explain:
- How to weight requirements
- How to handle multiple aspects per requirement
- Scoring for partial compliance

**Recommendation**:
Add "Scoring Algorithm" section with explicit calculation example.

---

#### Issue 3: No Explicit Iteration Index Defaults

**Severity**: HIGH
**Location**: `agents/code-tester/AGENT.md:539-540`
**Category**: Logic Completeness

**Analysis**:
For first iteration tickets (no iteration metadata), behavior is ambiguous:
- Should index default to 1?
- What if parent_ticket exists but no iteration block?

**Recommendation**:
Add explicit rules:
- No iteration block = index defaults to 1
- Route-back creates new ticket with index = previous + 1
- If would exceed max, ESCALATE instead

---

### MEDIUM Issues

#### Issue 1: Documentation References Non-Existent Observer Files

**Severity**: MEDIUM
**Location**: `docs/observer/PHILOSOPHY.md:166-167`
**Category**: Documentation

**Analysis**: References `skills/agentic-quality-workflow/SKILL.md` which may not exist in worktree.

**Recommendation**: Verify path or add note about future work.

---

#### Issue 2: Missing End-to-End Iteration Example

**Severity**: MEDIUM
**Location**: Documentation files
**Category**: Documentation Completeness

**Analysis**: No complete walkthrough showing TICKET-001 through approval or escalation.

**Recommendation**: Add "Complete Iteration Example" section to code-cycle.md.

---

#### Issue 3: Emoji Usage in New Sections

**Severity**: MEDIUM
**Location**: Agent output format sections
**Category**: Style Consistency

**Analysis**: Emojis in output templates may conflict with project preference to avoid emojis.

**Recommendation**: Accept as established pattern in existing agent files.

---

### Strengths Observed

1. **Comprehensive ARC-AGI Parallel**: Structured feedback with expected/actual/score/guidance directly implements "visual diff" pattern. Well-thought-out design.

2. **Consistent Cross-Agent Design**: Three agents have complementary sections that work together. Reviewer output feeds tester input feeds developer iteration.

3. **Excellent Escalation Protocol**: Pattern analysis, attempt summary tables, recommended interventions - goes beyond basic "give up."

4. **Good Documentation Structure**: PHILOSOPHY.md and code-cycle.md create clear conceptual foundation. Three-loop model well-explained.

---

### Approval Decision
NEEDS_CHANGES

### Rationale
One CRITICAL issue (TEMPLATE.md not updated) and three HIGH issues (score/status mismatch, missing calculation details, missing iteration defaults) require addressing before approval. The core implementation is solid and well-designed, but the schema completeness acceptance criterion is not met.

### Status Update
[2025-12-09 23:15] - Changed status to expediter_review

## Expediter Section
_To be filled during validation_

## Changelog
### [2025-12-09 23:15] - Critic
- Audit completed with structured findings summary
- 7 issues found: 1 CRITICAL, 3 HIGH, 3 MEDIUM
- Decision: NEEDS_CHANGES
- CRITICAL: TEMPLATE.md not updated with iteration schema
- HIGH: Score/status field mismatch, missing calculation details, missing iteration defaults
- Status changed to expediter_review

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
