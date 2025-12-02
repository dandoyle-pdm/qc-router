# Integration Workflows

Detailed procedures for integrating worktree changes via Pull Requests using trunk-based development.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide explains how to integrate changes from feature worktrees into protected branches (main, production) using Pull Requests. It covers merging strategies, conflict resolution, commit squashing, and trunk-based development principles.

## Trunk-Based Development

For worktrees created from main or production branches, **always use Pull Requests**. Never merge directly into these protected branches. This ensures code review, testing, and maintains clean git history.

**Remember:** You work in the worktree (directory), but commits and merges happen on the branch (checked out in that worktree). All commands below are run from within your feature worktree.

## Standard Pull Request Workflow

### Step 1: Complete and Commit Your Work

```bash
cd /home/ddoyle/workspace/worktrees/<project>/<branch-name>
git status  # Should show clean working directory
git add .
git commit -m "Implement feature changes"
git push origin <branch-name>
```

### Step 2: Update Feature Branch with Latest Main

Stay in your worktree and merge main INTO your feature branch (not the reverse):

```bash
# Still in your worktree
git fetch origin main
git merge origin/main
```

### Step 3: Resolve Any Conflicts

If conflicts occur, resolve them in the feature branch:

```bash
# If conflicts occur
git status  # Shows conflicted files

# Edit files to resolve conflicts
# Then stage and commit
git add <resolved-files>
git commit -m "Merge main into <branch-name>, resolve conflicts"
```

### Step 4: Squash Commits into One Clean Commit

Squashing creates a single commit with all your changes, keeping main branch history clean and readable.

```bash
# Soft reset to main - keeps all changes staged
git reset --soft origin/main

# Create one comprehensive commit
git commit -m "feat: implement user authentication

- Add login/logout endpoints
- Implement JWT token generation and validation
- Add password hashing with bcrypt
- Create user session management
- Add authentication middleware

Tested with integration test suite"
```

**Why squash?**

- Main branch history shows one commit per feature (easy to understand)
- Easy to revert entire features if needed (one commit = one revert)
- Makes git bisect more effective (each commit is a complete feature)
- Cleaner changelog generation

### Step 5: Push the Squashed Feature Branch

Since we rewrote commit history, use `--force-with-lease` (safer than `--force`):

```bash
git push --force-with-lease origin <branch-name>
```

### Step 6: Create a Pull Request

```bash
# Create PR using gh CLI or web interface
gh pr create --base main --head <branch-name> --title "feat: implement user authentication" --body "Comprehensive user authentication system with JWT tokens and session management"
```

The PR will now have one clean commit that's conflict-free and ready to merge into main.

## Direct Merge Exception

**Only when a worktree is based on a non-protected branch** (not main or production) may you merge directly:

```bash
cd /home/ddoyle/workspace/<project>
git checkout <parent-branch>
git pull origin <parent-branch>
git merge <feature-branch>
git push origin <parent-branch>
```

This exception allows for hierarchical feature development where sub-features merge into feature branches before the feature branch creates a PR to main.

## Related Concepts

- [Worktree Operations](worktree-operations.md) - Creating and managing worktrees
- [Best Practices](best-practices.md) - Commit frequency and squashing philosophy
- [Troubleshooting](troubleshooting.md) - Handling merge conflicts and errors

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
