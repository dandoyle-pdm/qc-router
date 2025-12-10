# QC Router Observation Philosophy

The QC Router implements a three-layer observation model inspired by ARC-AGI self-learning patterns. Each layer operates at a different timescale and scope to enable continuous improvement.

## The Three Loops

```
┌─────────────────────────────────────────────────────────────────┐
│                         LOOP 3                                   │
│                   Outcome Validation                             │
│              (system calibration over time)                      │
│                                                                  │
│   ┌─────────────────────────────────────────────────────────┐   │
│   │                      LOOP 2                              │   │
│   │               Cross-Cycle Agent Tuning                   │   │
│   │            (project-agnostic, long-lived)                │   │
│   │                                                          │   │
│   │   ┌─────────────────────────────────────────────────┐   │   │
│   │   │                  LOOP 1                          │   │   │
│   │   │           Within-Cycle Iteration                 │   │   │
│   │   │         (ticket-scoped, short-lived)             │   │   │
│   │   │                                                  │   │   │
│   │   │    Developer → Reviewer → Tester → [iterate]     │   │   │
│   │   │                                                  │   │   │
│   │   └─────────────────────────────────────────────────┘   │   │
│   │                                                          │   │
│   └─────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Loop 1: Within-Cycle Iteration

**Scope**: Single ticket, single quality cycle
**Timescale**: Minutes to hours
**Goal**: Iterate toward quality threshold

Loop 1 is the ARC-AGI parallel: "Up to 10 tries to refine logic, most puzzles solved by iteration 3-5."

### How It Works

1. Developer creates initial implementation
2. Reviewer provides structured findings (expected/actual)
3. Tester either approves or creates rework ticket
4. Rework ticket contains:
   - Iteration metadata (index, max, accuracy_score)
   - Attempt history (all previous attempts)
   - Structured feedback (expected/actual/score/guidance per requirement)
5. Developer reads history, targets specific gaps
6. Cycle repeats until APPROVE or ESCALATE

### Key Insight

"When code fails, we don't just say 'wrong.' We show the LLM a visual diff of what it predicted vs. what was correct, plus a score. It's not guessing. It's debugging."

### Implementation

- Ticket sequence number = iteration counter
- Agents never loop directly; new tickets enable fresh context
- History propagates through ticket content
- Escalation after max iterations (default: 5)

See [cycles/code-cycle.md](cycles/code-cycle.md) for complete Loop 1 documentation.

## Loop 2: Cross-Cycle Agent Tuning

**Scope**: Agent behavior across all projects
**Timescale**: Days to weeks
**Goal**: Improve agent effectiveness through pattern recognition

Loop 2 observes patterns across many Loop 1 iterations to tune agent behavior.

### What Gets Observed

- Which requirements consistently need multiple iterations?
- Which issue categories cause persistent gaps?
- What guidance patterns lead to successful resolution?
- Which escalations could have been prevented?

### How It Manifests

- Agent prompts refined based on common failure patterns
- Review checklists expanded for frequently-missed issues
- Developer guidance improved for persistent gap categories
- Threshold calibration based on approval rates

### Example Tuning

If observation shows "test coverage" is persistent gap in 40% of escalations:

1. Developer prompt emphasizes TDD approach
2. Reviewer checklist adds specific test pattern checks
3. Tester provides more detailed test guidance in feedback
4. Documentation includes test examples for common patterns

### Implementation Status

Loop 2 requires observation infrastructure not yet implemented:
- Metrics collection from ticket outcomes
- Pattern analysis across sessions
- Agent prompt versioning
- A/B testing capability

## Loop 3: Outcome Validation

**Scope**: Entire system behavior
**Timescale**: Weeks to months
**Goal**: Calibrate quality thresholds and escalation policies

Loop 3 validates whether approved code actually works in production.

### What Gets Observed

- Do approved tickets result in production issues?
- Are escalated tickets resolved after intervention?
- What's the correlation between accuracy scores and outcomes?
- How do threshold changes affect quality and velocity?

### How It Manifests

- Quality thresholds adjusted (80% coverage might become 85%)
- Escalation triggers refined (max iterations tuned per complexity)
- Severity definitions calibrated (what truly warrants CRITICAL?)
- Approval criteria sharpened

### Example Calibration

If observation shows 30% of approved tickets generate production bugs:

1. Review approval threshold (too lenient?)
2. Analyze gap between test coverage and actual failures
3. Identify issue categories that should be CRITICAL but weren't
4. Refine Tester judgment criteria

### Implementation Status

Loop 3 requires integration not yet implemented:
- Production incident correlation
- Post-approval tracking
- Long-term outcome data
- Threshold experiment framework

## ARC-AGI Principles Applied

| ARC-AGI Principle | QC Router Application |
|-------------------|----------------------|
| "Show visual diff of predicted vs correct" | Structured feedback with expected/actual tables |
| "Plus a score" | Accuracy scores per requirement and overall |
| "Up to 10 tries" | Iteration limits with configurable max (default: 5) |
| "Each iteration sees previous attempts" | Attempt history propagation in tickets |
| "It's not guessing, it's debugging" | Specific guidance in structured feedback |
| "Most solved by iteration 3-5" | Escalation only after multiple attempts |

## Philosophy Summary

1. **Feedback must be structured** - Prose feedback enables guessing; expected/actual tables enable debugging
2. **History must accumulate** - Each iteration builds on previous; nothing is forgotten
3. **Progress must be measurable** - Accuracy scores quantify improvement trajectory
4. **Escalation must be earned** - Multiple honest attempts before giving up
5. **Learning must be systemic** - Loop 2 and 3 improve the system, not just individual tickets

## Related Documentation

- [cycles/code-cycle.md](cycles/code-cycle.md) - Code quality cycle with Loop 1 details
- Agent definitions in `agents/*/AGENT.md` - Individual agent protocols
- `skills/agentic-quality-workflow/SKILL.md` - Workflow procedures
