# Troubleshooting

## Purpose

This guide addresses common errors encountered when working with git worktrees and provides solutions for resolving them. Understanding these scenarios helps prevent data loss and maintains a clean worktree environment.

**Part of**: [Git Worktree Management](../SKILL.md)

---

## Common Errors and Solutions

### Error: "fatal: '<branch>' is already checked out at '<path>'"

A branch can only be checked out in one worktree at a time. Either remove the existing worktree or use a different branch name.

```bash
# Find where it's checked out
git worktree list

# Remove that worktree or use different branch
git worktree remove <path>
```

### Error: "Refusing to remove worktree with modified files"

You have uncommitted changes. Either commit them, stash them, or use force removal.

```bash
# Option 1: Commit changes
cd <worktree-path>
git add .
git commit -m "WIP: Save progress"

# Option 2: Force remove (loses changes)
git worktree remove --force <worktree-path>
```

### Orphaned Worktrees After Manual Deletion

If you deleted a worktree directory manually (without using git worktree remove), clean it up:

```bash
# Prune references to deleted worktrees
git worktree prune

# Or remove specific orphaned entry
git worktree remove <path>  # Even if directory doesn't exist
```

---

## Related Concepts

- [Worktree Operations](worktree-operations.md) - Core worktree management commands
- [Emergency Recovery](emergency-recovery.md) - Recovering from critical situations

## See Also

- [Back to Git Worktree Management](../SKILL.md)
