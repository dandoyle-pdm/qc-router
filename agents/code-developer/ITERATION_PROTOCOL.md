# Iteration Protocol: Learning from Previous Attempts

This document describes how to handle iteration tickets (sequence > 001) by learning from previous attempts using the ARC-AGI pattern.

## When This Applies

Check the ticket's YAML frontmatter for iteration metadata:

```yaml
iteration:
  index: 3           # This is iteration 3
  max: 5             # Maximum 5 iterations before escalation
  parent_ticket: TICKET-session-002
  accuracy_score: 0.55  # Previous attempt scored 55%
```

If `iteration.index > 1`, this is a rework ticket. Read the Attempt History section before implementing.

## Reading Attempt History

Look for the Attempt History section in the ticket:

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

Use this history to:
1. Understand what was already tried
2. See progress trajectory (is accuracy improving?)
3. Identify persistent gaps that need special attention

## Reading Structured Feedback

The ticket includes structured feedback with expected/actual/score/guidance:

```markdown
# Structured Feedback

### Requirement: Test Coverage
| Expected | Actual | Score |
|----------|--------|-------|
| >= 80% line coverage | 45% line coverage | 0.56 |
| Error path tests | 2 of 6 tested | 0.33 |

**Guidance**: Add tests for `handleTimeout()` (line 78), `processEmpty()` (line 95)
```

**Critical**: Follow the guidance exactly. It tells you specifically what to fix.

## Iteration-Aware Implementation

When implementing on an iteration ticket:

1. **Read Attempt History First** - Understand what failed before
2. **Check Accuracy Trend** - Is it improving? Stalling?
3. **Focus on Guidance** - Structured feedback gives exact fixes needed
4. **Target Low-Score Requirements** - Prioritize requirements with score < 0.5
5. **Don't Regress** - Maintain previously-achieved accuracy on resolved issues

## Enhanced Iteration Protocol

For iteration tickets (index > 1):

1. **Parse iteration metadata** from frontmatter
2. **Read Attempt History section** - understand trajectory
3. **Read Structured Feedback section** - identify exact gaps
4. **Prioritize by score**: Fix lowest-scoring requirements first
5. **Follow guidance precisely** - it's specific for a reason
6. **Don't repeat failed approaches** - check what was tried before
7. **Track your accuracy impact** - which scores should improve from your changes?

## Recognizing Persistent Patterns

If the same gap appears across multiple iterations:

```
Attempt 1: Gaps - ["tests", "error handling"]
Attempt 2: Gaps - ["tests", "error messages"]
Attempt 3: Gaps - ["tests"]  <-- "tests" is persistent
```

This signals:
- You may not fully understand the testing requirement
- Ask for clarification before another attempt
- Request example test cases if unclear

## Output Format for Iteration Tickets

```
Iteration implementation complete.
Ticket: TICKET-session-003 (iteration 3/5)
Previous Accuracy: 0.55
Target Improvements:
  - Test coverage: 0.56 -> targeting 0.80
  - Error paths: 0.33 -> targeting 0.80
Changes Made:
  - Added 4 tests for error handling paths
  - Added 2 tests for edge cases
Commits: 2 commits
Ready for code-reviewer.
```

## Why This Matters

ARC-AGI insight: "Each iteration sees what the agent predicted vs. what was correct. It's not guessing. It's debugging."

By reading attempt history and structured feedback:
- You don't repeat failed approaches
- You target specific gaps, not general issues
- You can measure your progress with accuracy scores
- You avoid escalation by learning efficiently
