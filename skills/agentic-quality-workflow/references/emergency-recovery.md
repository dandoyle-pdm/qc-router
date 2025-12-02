# Emergency Recovery

## Purpose

This guide provides recovery procedures for common worktree accidents and issues. When things go wrong with worktrees, these procedures help you recover without losing work or compromising your repository state.

**Part of**: [Git Worktree Management](../SKILL.md)

---

## Recovery Scenarios

### Recover Accidentally Deleted Worktree

If you accidentally delete a worktree directory but want to recover it:

```bash
# The branch and commits still exist
git worktree list  # Shows worktree is gone but branch remains

# Recreate the worktree
git worktree prune  # Clean up references first
git worktree add /home/ddoyle/workspace/worktrees/<project>/<branch> <branch>
```

Your commits are safe on the branch; you just lost the working directory.

### Recover From Failed Merge in Worktree

If a merge attempt in a worktree goes wrong:

```bash
# Abort the merge
git merge --abort

# Or reset to before merge attempt
git reset --hard HEAD

# Start fresh merge attempt or seek help
```

---

## Related Concepts

- [Worktree Operations](worktree-operations.md) - Creating and managing worktrees
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## See Also

- [Git Worktree Management](../SKILL.md) - Main skill documentation
