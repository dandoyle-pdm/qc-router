# Code Quality Cycle

The code quality cycle implements Creator/Critic/Judge pattern for software development with ARC-AGI inspired iteration learning.

## Cycle Flow

```
                    APPROVE
                       ↑
                       │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ code-       │ →  │ code-       │ →  │ code-       │
│ developer   │    │ reviewer    │    │ tester      │
│ (Creator)   │    │ (Critic)    │    │ (Judge)     │
└─────────────┘    └─────────────┘    └─────────────┘
       ↑                                    │
       │                                    │
       └────────────────────────────────────┘
                   ROUTE_BACK
              (new ticket with history)
```

## Agent Roles

### code-developer (Creator)

- Implements code based on ticket requirements
- Reads attempt history on iteration tickets
- Targets low-scoring requirements from structured feedback
- Updates ticket Creator Section on completion

### code-reviewer (Critic)

- Performs adversarial code review
- Generates structured findings with expected/actual comparisons
- Maps issues to acceptance criteria
- Provides severity levels (CRITICAL/HIGH/MEDIUM)

### code-tester (Judge)

- Runs objective tests and validation
- Makes routing decision: APPROVE, ROUTE_BACK, or ESCALATE
- Creates rework tickets with structured feedback
- Enforces iteration limits and escalation protocol

## Loop 1: Within-Cycle Iteration

Loop 1 is the ARC-AGI parallel: "up to 10 tries to refine logic, most solved by iteration 3-5."

### Ticket Progression Model

Each iteration is a NEW ticket. The sequence number IS the iteration counter:

```
TICKET-session-001 (iteration 1/5)
    → Developer implements
    → Reviewer audits with structured findings
    → Tester routes back with feedback
                    │
                    ▼
TICKET-session-002 (iteration 2/5, parent: 001)
    → Developer reads history, targets gaps
    → Reviewer tracks progress from previous
    → Tester approves or creates 003
```

### Why Agents Never Loop

Agents never directly loop or retry. Instead:
1. Judge creates a NEW ticket with incremented sequence
2. New ticket contains attempt history and structured feedback
3. Developer receives new ticket, reads history, implements fixes
4. Cycle continues with fresh agent invocations

This enables:
- Clean context windows for each agent
- Explicit learning through ticket content
- Traceable iteration history
- Natural escalation boundaries

### Iteration Metadata

Route-back tickets include iteration tracking in YAML frontmatter:

```yaml
iteration:
  index: 2           # Current iteration number
  max: 5             # Maximum before escalation
  parent_ticket: TICKET-session-001
  accuracy_score: 0.6  # Overall accuracy achieved
```

### Attempt History

Each ticket accumulates history from all previous attempts:

```markdown
# Attempt History

## Attempt 1: TICKET-session-001
- **Outcome**: ROUTE_BACK
- **Accuracy**: 0.30
- **Key Gaps**: ["no tests", "no error handling"]

## Attempt 2: TICKET-session-002
- **Outcome**: ROUTE_BACK
- **Accuracy**: 0.55
- **Key Gaps**: ["test coverage low"]
```

### Structured Feedback

The Judge provides expected/actual comparison for each requirement:

```markdown
# Structured Feedback

### Requirement: Test Coverage
| Expected | Actual | Score |
|----------|--------|-------|
| >= 80% line coverage | 45% coverage | 0.56 |
| Error paths tested | 2 of 6 tested | 0.33 |

**Guidance**: Add tests for handleTimeout() and processEmpty()
```

This enables the Developer to:
- Target specific gaps instead of guessing
- Track progress with accuracy scores
- Follow explicit guidance for fixes

## Escalation Protocol

When iteration.index >= iteration.max (default: 5):

1. Judge sets verdict to ESCALATE (not ROUTE_BACK)
2. Full attempt history included in escalation
3. Pattern analysis identifies persistent gaps
4. Recommended intervention provided for coordinator

Escalation triggers coordinator review to:
- Break down scope if too complex
- Provide examples for persistent gaps
- Reassign or pair if skills mismatch

## Quality Thresholds

### Automatic Reject

- Any CRITICAL issue unresolved
- Tests fail or don't run
- Build fails
- New code has no test coverage

### Strong Reject

- Multiple HIGH priority issues
- Core architectural violations
- Significant security concerns

### Consider Accept

- All CRITICAL resolved
- HIGH issues minor or non-blocking
- Tests pass with adequate coverage
- Build succeeds cleanly

## Scoring

Accuracy scores quantify progress:

```
Accuracy = (Passing Aspects) / (Total Aspects)
```

Each requirement's aspects are evaluated as PASS/FAIL, then averaged.

Progress between iterations should show:
- Rising overall accuracy
- Declining number of gaps
- Resolution of persistent issues

## Integration with Observer Layer

The code cycle feeds observation data to:
- **Loop 2** (cross-cycle): Agent tuning based on iteration patterns
- **Loop 3** (outcome): System calibration from approval/escalation rates

See [PHILOSOPHY.md](../PHILOSOPHY.md) for the complete observation model.
