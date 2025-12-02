# Worktree Fundamentals

Understanding the critical distinction between worktrees and branches for safe git workflows.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide explains the fundamental concepts of git worktrees and branches, their relationship, and critical safety rules. Understanding this distinction is essential for working safely with worktree-based development workflows.

## Critical Distinction

**Branch** = A logical pointer to a series of commits in git (exists in .git metadata)

**Worktree** = A physical working directory on your filesystem where you can check out a branch

## The Relationship

```
/home/ddoyle/workspace/
├── my-app/                                    # Main repository (primary worktree)
│   ├── .git/                                  # Shared git metadata for all worktrees
│   ├── src/
│   └── (main branch checked out here)
└── worktrees/
    └── my-app/                                # Worktrees for my-app repo
        ├── feature-auth/                      # Secondary worktree
        │   ├── src/
        │   └── (feature-auth branch checked out here)
        └── fix-bug/                           # Another secondary worktree
            ├── src/
            └── (fix-bug branch checked out here)
```

**Critical Safety Note:** Worktrees MUST be outside the main repository directory. Never create worktrees inside `/home/ddoyle/workspace/my-app/` as git might try to track them. Always use `/home/ddoyle/workspace/worktrees/<project>/<branch>` as shown above.

## Key Points

1. **One branch per worktree**: Each worktree has exactly one branch checked out
2. **Multiple worktrees, one repo**: All worktrees share the same `.git` directory and commit history
3. **Branch exclusivity**: A branch can only be checked out in ONE worktree at a time
4. **Naming convention**: Worktree directory names typically match their branch names for clarity

## Practical Example

```bash
# Create a branch (logical pointer)
git branch feature-auth

# Create a worktree with that branch checked out (physical directory)
git worktree add /home/ddoyle/workspace/worktrees/my-app/feature-auth feature-auth

# Result: You now have a directory at that path with feature-auth checked out
# Changes made in that directory affect the feature-auth branch
# The branch and worktree are linked but distinct concepts
```

## Why This Matters

- You **work in a worktree** (a directory on your filesystem)
- Your commits happen **on the branch** (that's checked out in that worktree)
- When you "merge main INTO your feature branch," you're running the command from within the worktree
- The worktree is the workspace; the branch is what gets merged/committed/pushed

## Related Concepts

- [Worktree Operations](worktree-operations.md) - How to create and manage worktrees
- [Integration Workflows](integration-workflows.md) - How branches and worktrees work together in PR workflows
- [Best Practices](best-practices.md) - Safety rules and naming conventions

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
