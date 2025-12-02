# Quality Cycle Integration

**Part of**: [Git Worktree Management](../SKILL.md)

---

## Purpose

This document explains how git worktrees enable Creator/Reviewer/Judge workflows for agentic quality cycles. Worktrees provide the isolation and parallel execution capabilities needed to implement sophisticated quality review processes while maintaining code safety and traceability.

## Overview of Quality Cycles with Worktrees

Quality cycles involve multiple agents working in phases to create, review, and validate code or documentation. Worktrees enable this process by:

- **Isolation**: Each phase can work in dedicated worktrees without interfering with others
- **Parallelization**: Multiple code modules can be developed simultaneously in separate worktrees
- **Serialization**: Documentation work remains sequential to prevent conflicts
- **Traceability**: Each worktree maintains its own commit history during the quality cycle
- **Safety**: Changes remain isolated until Judge approves and PR is merged

The fundamental pattern is: worktrees provide physical workspace isolation while branches track logical development progress through the quality cycle.

## Creator Phase

Creator agents work entirely within dedicated worktrees to implement initial features or documentation:

```bash
# Create isolated workspace for initial implementation
git worktree add /home/ddoyle/workspace/worktrees/app/feature-new feature-new
cd /home/ddoyle/workspace/worktrees/app/feature-new

# Creator agent implements here
# All commits stay isolated in this worktree
```

**Key Points:**
- Creator starts from main branch (trunk-based development)
- All implementation work happens in the feature worktree
- Commits are made frequently as checkpoints
- Work remains isolated until ready for review

## Reviewer Phase

Reviewer agents can examine code in the same worktree or via branch comparison and store audit report in the worktree branch:

```bash
# Option 1: Review in the same worktree (after Creator pushes)
cd /home/ddoyle/workspace/worktrees/app/feature-new
git diff main...feature-new

# Option 2: Review via separate read-only worktree
git worktree add --detach /home/ddoyle/workspace/worktrees/app/review-feature-new feature-new
cd /home/ddoyle/workspace/worktrees/app/review-feature-new
```

**Key Points:**
- Reviewer can access the same worktree or create a detached copy
- Audit reports and review comments are committed to the feature branch
- Review process doesn't interfere with Creator's workspace
- Multiple reviewers can work in parallel if needed

## Judge Phase

Judge agents read Reviewer audits and determine whether to route back to creator or leave quality cycle:

```bash
cd /home/ddoyle/workspace/worktrees/app/feature-new

# Run test suite
npm test

# Check build
npm run build

# Verify no regressions
./run-integration-tests.sh
```

**Key Points:**
- Judge validates all quality criteria are met
- Can run tests and builds in the isolated worktree
- Decision to approve or reject routes the workflow
- Only after Judge approval does the branch get merged in the main repository location

## Parallelization Pattern for Code

Multiple worktrees can work simultaneously on different modules:

```bash
# Terminal 1: Backend changes
git worktree add /home/ddoyle/workspace/worktrees/app/backend-api backend-api
cd /home/ddoyle/workspace/worktrees/app/backend-api

# Terminal 2: Frontend changes
git worktree add /home/ddoyle/workspace/worktrees/app/frontend-ui frontend-ui
cd /home/ddoyle/workspace/worktrees/app/frontend-ui

# Terminal 3: Test suite updates
git worktree add /home/ddoyle/workspace/worktrees/app/update-tests update-tests
cd /home/ddoyle/workspace/worktrees/app/update-tests
```

**When to Parallelize:**
- Independent code modules (backend, frontend, tests)
- Non-conflicting features
- Different areas of the codebase
- Isolated component development

**Benefits:**
- Simultaneous development accelerates delivery
- Each quality cycle runs independently
- No cross-contamination between features
- Easy to manage and track progress

## Serial Pattern for Documentation

Only one documentation worktree should be active at a time:

```bash
# Complete this work FULLY before starting another doc worktree
git worktree add /home/ddoyle/workspace/worktrees/docs/update-readme update-readme
cd /home/ddoyle/workspace/worktrees/docs/update-readme
# ... complete quality cycle ...
git worktree remove /home/ddoyle/workspace/worktrees/docs/update-readme

# Now safe to start next documentation task
git worktree add /home/ddoyle/workspace/worktrees/docs/api-docs api-docs
```

**Why Serialize Documentation:**
- Documentation files often overlap (README, architecture docs, etc.)
- Prevents merge conflicts in shared documentation
- Ensures coherent narrative across related docs
- Easier to maintain consistent style and terminology

**Pattern:**
1. Create documentation worktree
2. Complete entire quality cycle (Creator → Reviewer → Judge)
3. Merge via PR when Judge approves
4. Remove worktree
5. Only then start next documentation task

## Related Concepts

- [Code Quality Workflows](code-quality-workflows.md) - Workflow overview, role definitions, and triggering criteria
- [Code Workflow Procedures](code-workflow-procedures.md) - Detailed step-by-step procedures for running quality cycles with code
- [Worktree Operations](worktree-operations.md) - Core commands for managing worktrees
- [Best Practices](best-practices.md) - Guidelines for effective worktree usage
- [Git Worktree Management](../SKILL.md) - Complete skill documentation

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
