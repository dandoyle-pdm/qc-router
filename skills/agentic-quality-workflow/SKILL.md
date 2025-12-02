---
name: agentic-quality-workflow
description: Manage git worktrees for isolated agentic quality workflows (Creator/Critic/Judge cycles). Use when setting up quality review cycles, working on multiple branches in parallel, preventing accidental commits to protected branches, or managing isolated development environments. Enforces trunk-based development with worktrees created from main branch.
---

# Agentic Quality Workflow

## Overview

This skill provides comprehensive procedures for managing git worktrees to enable safe, isolated development workflows. Worktrees allow multiple working directories from a single git repository, enabling parallel work without branch conflicts.

**This is an OVERVIEW guide. For detailed procedures, see [Reference Materials](#reference-materials).**

## When To Use This Skill

### For Worktree Management

Use whenever working on isolated tasks requiring branch isolation:

- Any feature, bugfix, or documentation work that needs isolation from main
- Preventing collisions from simultaneous multi-agent development
- Quality review cycles that require branch isolation

### For Quality Cycles (Creator/Critic/Judge)

**ALL work goes through quality cycles.** The type of work determines the recipe:

| Recipe | Work Type | Cycle |
|--------|-----------|-------|
| R1 | Production code | code-developer → code-reviewer → code-tester |
| R2 | Documentation (100+ lines) | tech-writer → tech-editor → tech-publisher |
| R3 | Handoff prompts | tech-editor (quick check) |
| R4 | Read-only queries | None (fast path) |
| R5 | Config/minor changes | Single reviewer |

**See**: [Code Quality Workflows](references/code-quality-workflows.md) for triggering criteria and workflow overview. For step-by-step procedures, see [Code Workflow Procedures](references/code-workflow-procedures.md).

## Quick Start

Minimal 3-step workflow to create a worktree, work in it, and integrate via PR:

```bash
# 1. Create worktree from main branch
git worktree add /home/ddoyle/workspace/worktrees/my-app/feature-name feature-name

# 2. Work and commit in the worktree
cd /home/ddoyle/workspace/worktrees/my-app/feature-name
# ... make changes ...
git add .
git commit -m "Implement feature"
git push origin feature-name

# 3. Create PR, squash commits, and cleanup
git fetch origin main
git merge origin/main
git reset --soft origin/main
git commit -m "feat: complete feature description"
git push --force-with-lease origin feature-name
gh pr create --base main --head feature-name
```

**See**: [Worktree Operations](references/worktree-operations.md) and [Integration Workflows](references/integration-workflows.md) for detailed procedures.

## Core Concepts

### Worktrees vs Branches

**Critical Distinction:**

- **Branch** = A logical pointer to commits in git (exists in .git metadata)
- **Worktree** = A physical working directory where you check out a branch

Each worktree has exactly one branch checked out. A branch can only be checked out in ONE worktree at a time. You work in the worktree (directory), but commits happen on the branch.

**See**: [Worktree Fundamentals](references/worktree-fundamentals.md)

### Critical Safety Rules

**MUST follow these rules:**

- ALWAYS work in git worktrees, never directly on branches
- MUST use standard location: `/home/ddoyle/workspace/worktrees/<project>/<branch>`
- MUST create git worktrees from main branch (trunk-based development)
- NEVER create git worktrees inside the main repository directory

**See**: [Best Practices](references/best-practices.md)

## Common Workflows

### Creating and Working in Worktrees

Create isolated working directories for each task:

1. Create branch and worktree from main
2. Work normally with git add, commit, push
3. Each worktree has its own staging area and state

**See**: [Worktree Operations](references/worktree-operations.md)

### Integration via Pull Request

Standard workflow for merging feature worktrees into main:

1. Complete work and commit in worktree
2. Merge main INTO your feature branch
3. Squash all commits into one clean commit
4. Create Pull Request
5. Remove worktree after merge

**See**: [Integration Workflows](references/integration-workflows.md)

### Quality Cycle Integration

Use worktrees to isolate Creator/Critic/Judge workflows:

- **Creator**: Works in dedicated feature worktree
- **Critic**: Examines code via same worktree or separate read-only worktree
- **Judge**: Validates in worktree before approving PR

**Patterns:**

- **Parallel**: Multiple code worktrees can work simultaneously on different modules
- **Serial**: Documentation worktrees should complete fully before starting another

**See**: [Quality Cycle Integration](references/quality-cycle-integration.md)

### Code Quality Cycles

Step-by-step procedures for running Creator/Critic/Judge workflows with code:

1. **Creator**: Implements code in feature worktree, commits after each todo
2. **Critic**: Reviews using checklist, provides specific feedback
3. **Judge**: Runs automated validation, approves or routes back to Creator

**When to use**: All production code changes (R1 recipe)

**See**: [Code Quality Workflows](references/code-quality-workflows.md) for overview and [Code Workflow Procedures](references/code-workflow-procedures.md) for detailed steps. Use [Code Review Checklists](references/code-review-checklists.md) for review criteria.

## Reference Materials

Complete detailed guides for all worktree operations and workflows:

- **[worktree-fundamentals.md](references/worktree-fundamentals.md)** (~80 lines) - Understanding worktrees vs branches, critical distinctions, safety rules
- **[worktree-operations.md](references/worktree-operations.md)** (~150 lines) - Step-by-step procedures for creating, working, listing, and removing worktrees
- **[integration-workflows.md](references/integration-workflows.md)** (~120 lines) - Pull request workflows, merging strategies, commit squashing, trunk-based development
- **[quality-cycle-integration.md](references/quality-cycle-integration.md)** (~160 lines) - Creator/Critic/Judge workflows, parallelization patterns
- **[code-quality-workflows.md](references/code-quality-workflows.md)** (~250 lines) - Code quality workflow overview, role definitions, triggering criteria, git integration, iteration limits
- **[code-workflow-procedures.md](references/code-workflow-procedures.md)** (~185 lines) - Detailed step-by-step procedures for Creator/Critic/Judge phases
- **[code-review-checklists.md](references/code-review-checklists.md)** (~190 lines) - Detailed review and validation checklists for Critic and Judge phases
- **[troubleshooting.md](references/troubleshooting.md)** (~50 lines) - Common errors and solutions
- **[best-practices.md](references/best-practices.md)** (~60 lines) - Naming conventions, commit frequency, cleanup discipline
- **[emergency-recovery.md](references/emergency-recovery.md)** (~40 lines) - Recovery procedures for worktree accidents

## Troubleshooting

Common issues and quick solutions:

**Error: "fatal: '<branch>' is already checked out"**

- A branch can only be in one worktree at a time
- Solution: `git worktree list` to find it, then remove or use different branch

**Error: "Refusing to remove worktree with modified files"**

- You have uncommitted changes
- Solution: Commit changes or use `git worktree remove --force <path>`

**Orphaned worktrees after manual deletion**

- Deleted directory without using git worktree remove
- Solution: `git worktree prune` to clean up references

**See**: [Troubleshooting Guide](references/troubleshooting.md) for complete error resolution and [Emergency Recovery](references/emergency-recovery.md) for accident recovery.

## Summary

Worktrees enable isolated, parallel development with safe boundaries. Key principles:

1. **Always work in worktrees**, never on branches directly
2. **Use standardized paths** at `/home/ddoyle/workspace/worktrees/<project>/<branch>` (peer to repo, not inside it)
3. **Create from main branch** for each task (trunk-based development)
4. **Commit frequently** as checkpoints while developing
5. **Merge main INTO feature** to resolve conflicts in your branch
6. **Squash before PR** - one comprehensive commit per feature
7. **Use Pull Requests** for all integration into protected branches
8. **Remove promptly** after PR is merged
9. **Parallelize code work**, serialize documentation work

By following these procedures, you achieve safe, reviewable, and reversible development workflows with clean git history.

**For detailed procedures, see [Reference Materials](#reference-materials).**
