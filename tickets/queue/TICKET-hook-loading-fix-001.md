---
# Metadata
ticket_id: TICKET-hook-loading-fix-001
session_id: hook-loading-fix
sequence: 001
parent_ticket: null
title: Fix enforcement hook loading and branch detection
cycle_type: development
status: critic_review
created: 2025-12-02 17:30
worktree_path: null
---

# Requirements

## What Needs to Be Done

Fix two bugs preventing the quality cycle enforcement hook from working:

### Bug 1: Relative paths in hooks.json prevent hook loading

**File**: `hooks/hooks.json`

**Problem**: Hook commands use relative paths (`hooks/set-quality-cycle-context.sh`) which fail to resolve when the plugin is loaded from a different working directory.

**Fix**: Use `${CLAUDE_PLUGIN_ROOT}` variable for path resolution:
```json
{
  "command": "${CLAUDE_PLUGIN_ROOT}/hooks/set-quality-cycle-context.sh"
}
```

### Bug 2: Protected branch check uses CWD instead of file path

**File**: `hooks/enforce-quality-cycle.sh` (function `is_protected_branch()` at line 94)

**Problem**: When checking if a file edit should be blocked, the hook determines the git branch from `CWD` (session working directory) instead of the file being edited. This allows edits to files in worktrees to bypass protection.

**Example failure case**:
- CWD: `/home/user/project` (branch: main)
- File: `/home/user/worktrees/project/feature/src/file.go` (branch: feature)
- Hook checked CWD's branch, not file's branch

**Fix**: Create new function `get_file_repo_branch()` that determines the git branch from the file path's directory, not CWD.

## Acceptance Criteria

- [ ] `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` for all command paths
- [ ] `enforce-quality-cycle.sh` checks branch based on file path directory
- [ ] Hook correctly blocks Edit/Write on protected branches regardless of CWD
- [ ] Hook correctly allows Edit/Write on feature branches regardless of CWD
- [ ] All existing hook functionality preserved (security validations, audit logging)
- [ ] Manual testing confirms hooks load after Claude Code restart
- [ ] `/hooks` command shows both SessionStart and PreToolUse hooks

# Context

## Why This Work Matters

The enforcement hook is the primary mechanism preventing unreviewed code from being committed directly. With these bugs:
1. Hooks don't load at all (relative path issue)
2. Even if loaded, protection can be bypassed via worktrees (CWD vs file path issue)

This undermines the entire quality cycle enforcement for ALL projects using the plugin.

## References

- Debug log: `~/.claude/logs/hooks-debug.log`
- Claude Code hooks guide: https://code.claude.com/docs/en/hooks-guide.md
- Incident: Unreviewed edits to rulesets.go went through silently

# Creator Section

## Implementation Notes

### Bug 1 Fix: Relative paths in hooks.json
Changed both hook command paths from relative (`hooks/...`) to use the `${CLAUDE_PLUGIN_ROOT}` variable:
- `hooks/set-quality-cycle-context.sh` -> `${CLAUDE_PLUGIN_ROOT}/hooks/set-quality-cycle-context.sh`
- `hooks/enforce-quality-cycle.sh` -> `${CLAUDE_PLUGIN_ROOT}/hooks/enforce-quality-cycle.sh`

This ensures hooks load correctly regardless of the session's working directory.

### Bug 2 Fix: Branch detection using file path

**Added two new functions:**

1. `get_file_repo_branch(file_path)` - Determines the git branch from the file's directory, not CWD. Key logic:
   - Extracts the directory containing the file
   - If directory doesn't exist (new file), walks up parent directories to find existing directory
   - Uses `git -C <dir>` to query the branch from that directory
   - Correctly handles git worktrees where the file's directory is on a different branch than CWD

2. `is_file_on_protected_branch(file_path)` - Checks if a file path is on a protected branch using the new function

**Updated protected branch check in main():**
- Moved file path extraction BEFORE the branch check (was extracting after)
- Changed from `is_protected_branch()` (uses CWD) to `is_file_on_protected_branch(target_file_path)`
- Updated audit logging to include `file_branch` instead of just CWD branch
- Added comment explaining the fix

**Design decisions:**
- Kept the old `is_protected_branch()` and `get_current_branch()` functions intact for backward compatibility (they may be used elsewhere)
- New functions are additive, not replacing existing ones
- Parent directory traversal handles edge case of writing to new directories

## Questions/Concerns
- The original `is_protected_branch()` function is now unused in the code. Consider removing it in a future cleanup ticket to avoid confusion.
- Edge case: If a file path points to a non-existent directory outside any git repo, the check returns "not protected" (allows the operation). This is consistent with the original behavior.

## Changes Made
- File changes:
  - `hooks/hooks.json`: Updated both command paths to use `${CLAUDE_PLUGIN_ROOT}`
  - `hooks/enforce-quality-cycle.sh`: Added `get_file_repo_branch()` and `is_file_on_protected_branch()` functions, updated protected branch check logic

- Commits:
  - `cfb4c24` fix(hooks): use CLAUDE_PLUGIN_ROOT for hook command paths
  - `d57942c` fix(hooks): detect protected branch from file path, not CWD
  - `adcdda2` docs: update TICKET-hook-loading-fix-001 with implementation notes

**Status Update**: 2025-12-02 17:45 - Changed status to `critic_review`

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] (None identified yet)

### HIGH Issues
- [ ] (None identified yet)

### MEDIUM Issues
- [ ] (None identified yet)

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[Why this decision]

**Status Update**: [Date/time] - Changed status to `expediter_review`

# Expediter Section

## Validation Results
- Automated tests: [PASS/FAIL details]
- Linting: [PASS/FAIL]
- Type checking: [PASS/FAIL]
- Security scans: [PASS/FAIL]
- Build: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[If approved: integration steps | If rework: what needs fixing | If escalate: why]

**Status Update**: [Date/time] - Changed status to `approved` or created `TICKET-{session-id}-{next-seq}`

# Changelog

## [2025-12-02 17:30] - Investigation
- Root cause identified: two bugs preventing enforcement
- Bug 1: Relative paths in hooks.json
- Bug 2: CWD vs file path mismatch in branch detection
- Ticket created for quality cycle fix
