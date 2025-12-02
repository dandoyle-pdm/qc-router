# Best Practices

## Purpose

This document outlines conventions and guidelines for effective worktree workflows, including naming standards, commit strategies, cleanup discipline, and context management. Following these practices ensures maintainable, organized development across multiple parallel workspaces.

**Part of**: [Git Worktree Management](../SKILL.md)

---

## Naming Conventions

Use descriptive, hierarchical branch names that map to clear worktree paths:

- `feature/user-authentication` → `.../worktrees/project/feature-user-authentication`
- `fix/login-timeout` → `.../worktrees/project/fix-login-timeout`
- `docs/api-reference` → `.../worktrees/project/docs-api-reference`

## Commit Frequency and Squashing

**During Development:** Commit frequently in worktrees, especially before:

- Switching focus to another worktree
- Ending a work session
- Starting a quality review cycle

This creates checkpoint states and makes worktree removal safer.

**Before Pull Request:** Always squash all commits into one comprehensive commit:

- Use `git reset --soft origin/main` followed by a single commit
- Write detailed commit message explaining the entire feature
- Force push with `--force-with-lease`
- This keeps main branch history clean (one commit = one feature)

**Philosophy:** Commit often during development (safety), squash before merging (clean history).

## Cleanup Discipline

Remove worktrees promptly after merging. Accumulating stale worktrees:

- Consumes disk space
- Creates confusion about active work
- Makes git worktree list output cluttered

## Context Switching

When switching between worktrees, use explicit cd commands or terminal tabs/windows. Each worktree is a separate working directory with its own state.

---

## Related Concepts

- [Worktree Operations](worktree-operations.md) - Core commands and management
- [Integration Workflows](integration-workflows.md) - Quality cycle integration patterns

## See Also

- [Git Worktree Management](../SKILL.md) - Main skill documentation
