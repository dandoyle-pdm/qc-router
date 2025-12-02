# Code Quality Workflows

Step-by-step procedures for running Creator/Reviewer/Judge quality cycles with code using git worktrees.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide provides detailed procedures for running Creator/Reviewer/Judge quality cycles for code changes.

**ALL code changes go through quality cycles.** This is the R1 recipe:
- code-developer (Creator) → code-reviewer (Critic) → code-tester (Judge)

## Code Quality Cycle (R1 Recipe)

### Maintenance vs Greenfield Differentiation

**Greenfield Development** (new code, no existing patterns):
- Focus: Establish clean patterns, comprehensive tests, clear abstractions
- Workflow: Define patterns → write tests → implement → document

**Maintenance Development** (working with existing codebase):
- Focus: Pattern consistency, backwards compatibility, migration paths
- Workflow: Understand current patterns → check breaking changes → implement → verify compatibility

## Role Definitions and Scope

### Creator Role

**Scope**: Implement the solution in a feature worktree

**Done when**:
- Implementation complete and tested
- Unit tests written and passing
- Self-review completed
- Edge cases identified and handled
- Commit after every todo completion
- Handoff artifacts prepared for Reviewer

**NOT done until**: Code works, tests pass, and you can explain design decisions

### Reviewer Role

**Scope**: Provide specific, actionable feedback using review checklists

**Done when**:
- Reviewed all changes using code-review-checklists.md
- Specific feedback provided (file + line references) OR approval given
- Handoff artifacts prepared for Judge

**Critical**: Reviewer provides FEEDBACK, not reimplementation
- Good: "auth.py:45 - Password validation missing length check"
- Bad: "Here's how I would rewrite the authentication module..."

### Judge Role

**Scope**: Run automated validation and make merge decision

**Done when**:
- All automated checks pass (tests, linting, type checking)
- Reviewer has approved
- No unresolved issues or concerns
- Merge completed OR routed back to Creator with clear requirements

**NOT done until**: All validation passes and reviewer approved

## Workflow Overview

**Three-Phase Quality Cycle:**

The Creator/Reviewer/Judge workflow operates in three distinct phases with clear handoff points. Each role has specific responsibilities and completion criteria. The workflow supports iterative refinement while maintaining quality standards.

### 1. Creator Phase

**Objective**: Implement a complete, tested solution ready for review

**Key Activities**:
- Create feature worktree from main branch
- Implement solution using greenfield or maintenance approach
- Write and run tests to verify functionality
- Commit after every todo completion
- Perform self-review against code review checklists
- Prepare comprehensive handoff artifacts
- Notify Reviewer when implementation complete

**Completion Criteria**: Code works, tests pass, design decisions documented

**Handoff to**: Reviewer (with CREATOR_HANDOFF.md)

### 2. Reviewer Phase

**Objective**: Provide specific, actionable feedback to improve code quality

**Key Activities**:
- Access code in worktree (same worktree or separate read-only worktree)
- Review changes using comprehensive checklists from code-review-checklists.md
- Check security, test coverage, error handling, performance, patterns
- Provide specific feedback with file and line references
- Distinguish required changes from optional improvements
- Make approval decision
- Notify Judge (if approved) or Creator (if changes needed)

**Completion Criteria**: All code reviewed, specific feedback provided, approval status set

**Handoff to**: Judge (if approved, with REVIEWER_FEEDBACK.md) OR Creator (if changes needed)

### 3. Judge Phase

**Objective**: Validate code through automated checks and make merge decision

**Key Activities**:
- Access code in Creator's worktree
- Run automated validation (tests, linting, type checking, security scans, build)
- Verify Reviewer has approved changes
- Check all validation passes
- Make merge decision based on results
- Execute merge to main (if approved) or route back to Creator (if issues found)
- Prepare final report

**Completion Criteria**: All automated checks pass, reviewer approved, merge completed or clear requirements provided

**Handoff to**: User (merge complete, with JUDGE_REPORT.md) OR Creator (validation failed, with JUDGE_REQUIREMENTS.md)

### Iteration Pattern

**When changes requested**: Creator addresses feedback, commits fixes, notifies Reviewer

**Maximum iterations**: 3 Creator → Reviewer cycles before escalation

**Escalation triggers**: Fundamental disagreements, unclear requirements, technical blockers, breaking changes, iteration limit reached

**Quality gates**: Each phase has explicit completion criteria that must be met before handoff

**See**: [Code Workflow Procedures](code-workflow-procedures.md) for detailed step-by-step instructions for each phase.

## Git Workflow Integration

### Worktree Strategy by Role

**Creator**:
- Works in feature worktree: `/home/ddoyle/workspace/worktrees/<project>/<feature-name>`
- Commits after every todo completion
- Pushes regularly to keep remote updated

**Reviewer**:
- Option A: Same worktree as Creator (after Creator pushes latest)
- Option B: Separate read-only worktree for review
- Leaves feedback in worktree files (REVIEWER_FEEDBACK.md)

**Judge**:
- Uses Creator's worktree for validation
- Runs automated checks
- Merges to main if approved (following integration-workflows.md)

### Branching Strategy

```
main (protected)
  ├─ feature-name (Creator works here in dedicated worktree)
       └─ Reviewer reviews here
       └─ Judge validates here
       └─ Merges back to main via PR
```

### Commit Pattern

- Creator: Commit after EVERY todo completion
- Reviewer: Commit feedback documents
- Judge: Commit validation reports
- Final: Squash all commits before merging to main (per integration-workflows.md)

## Iteration Limits and Escalation

### Maximum Iterations

**Limit**: 3 Creator → Reviewer cycles

After 3 iterations without approval, escalate to user.

### Escalation Triggers

Escalate immediately if:
- **Fundamental disagreement** between Creator and Reviewer on approach
- **Unclear requirements** discovered during implementation
- **Technical blockers** cannot be resolved
- **Breaking changes** unavoidable and impact unclear
- **Iteration limit** reached (3 cycles)

### Bail-Out Procedure

When escalating:

1. **Preserve all work**:
```bash
git add .
git commit -m "WIP: Escalating to user - [reason]"
git push origin <feature-name>
```

2. **Create ESCALATION_SUMMARY.md**:
- What has been completed
- What the blocker/disagreement is
- Options considered
- Recommendation (if any)
- Question for user

3. **Commit and notify**:
```bash
git add ESCALATION_SUMMARY.md
git commit -m "Escalation: Require user decision"
git push origin <feature-name>
```

4. **Wait for user guidance** before continuing

## Related Concepts

- [Code Workflow Procedures](code-workflow-procedures.md) - Detailed step-by-step procedures for Creator/Reviewer/Judge phases
- [Quality Cycle Integration](quality-cycle-integration.md) - Pattern overview (parallel vs serial)
- [Code Review Checklists](code-review-checklists.md) - Detailed review and validation criteria
- [Integration Workflows](integration-workflows.md) - PR workflow and merging to main
- [Worktree Operations](worktree-operations.md) - Creating and managing worktrees
- [Best Practices](best-practices.md) - Commit frequency and cleanup

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
