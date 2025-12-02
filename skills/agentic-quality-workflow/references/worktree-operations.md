# Worktree Operations

Step-by-step procedures for creating, using, listing, and removing git worktrees.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide provides detailed operational procedures for managing git worktrees. These are the core commands and workflows you'll use day-to-day when working with worktrees.

## Creating a Worktree

### Step 1: Identify or Create Your Branch

```bash
# If branch doesn't exist yet, create it from current location
git branch feature-name

# Or create from specific starting point
git branch feature-name origin/main
```

### Step 2: Create the Worktree

```bash
# Basic syntax
git worktree add /home/ddoyle/workspace/worktrees/<project>/<branch-name> <branch-name>

# Example for new feature
git worktree add /home/ddoyle/workspace/worktrees/my-app/feature-user-auth feature-user-auth

# Example for bugfix
git worktree add /home/ddoyle/workspace/worktrees/my-app/fix-login-error fix-login-error
```

**What just happened:**

- Git created a new directory at `/home/ddoyle/workspace/worktrees/my-app/feature-user-auth`
- The `feature-user-auth` branch is now checked out in that directory
- This branch is now "locked" to this worktree (can't be checked out elsewhere until you remove this worktree)

### Step 3: Navigate to the Worktree

```bash
cd /home/ddoyle/workspace/worktrees/<project>/<branch-name>
```

You are now in an isolated working directory. Any commits, modifications, or experiments happen here without affecting other worktrees or the main repository.

## Working in a Worktree

Once inside a worktree, work normally:

```bash
# Make changes
vim src/auth.py

# Stage and commit
git add src/auth.py
git commit -m "Implement user authentication"

# Push to remote
git push origin feature-user-auth

# Run tests, build, etc.
npm test
```

**Key insight**: Each worktree is a complete working directory with its own staging area and checked-out branch. Changes in one worktree do not affect others.

**Understanding what happens:**

- `vim src/auth.py` - Modifies files in the worktree (physical directory)
- `git add src/auth.py` - Stages changes for the branch checked out in this worktree
- `git commit -m "..."` - Creates a commit on the feature branch (not on main!)
- `git push origin feature-user-auth` - Pushes the feature branch to remote

The worktree is where you work; the branch is what gets committed and pushed.

## Listing Active Worktrees

To see all current worktrees:

```bash
git worktree list
```

Output example:

```
/home/ddoyle/workspace/my-app              abc123f [main]
/home/ddoyle/workspace/worktrees/my-app/feature-auth  def456a [feature-auth]
/home/ddoyle/workspace/worktrees/my-app/fix-bug      ghi789b [fix-bug]
```

## Removing a Worktree

After work is complete and merged:

### Step 1: Ensure All Changes Are Committed

```bash
cd /home/ddoyle/workspace/worktrees/<project>/<branch-name>
git status  # Must be clean
```

### Step 2: Navigate Out of the Worktree

```bash
cd /home/ddoyle/workspace/<project>
```

### Step 3: Remove the Worktree

```bash
git worktree remove /home/ddoyle/workspace/worktrees/<project>/<branch-name>
```

### Step 4: Optionally Delete the Branch

```bash
# Delete local branch
git branch -d <branch-name>

# Delete remote branch
git push origin --delete <branch-name>
```

## Force Removal

If you need to abandon work in a worktree:

```bash
# Force remove even with uncommitted changes
git worktree remove --force /home/ddoyle/workspace/worktrees/<project>/<branch-name>
```

**Warning**: This discards all uncommitted work in that worktree permanently.

## Related Concepts

- [Worktree Fundamentals](worktree-fundamentals.md) - Understanding worktrees vs branches
- [Integration Workflows](integration-workflows.md) - Using worktrees in PR workflows
- [Best Practices](best-practices.md) - Cleanup discipline and conventions
- [Troubleshooting](troubleshooting.md) - Common errors and solutions

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
