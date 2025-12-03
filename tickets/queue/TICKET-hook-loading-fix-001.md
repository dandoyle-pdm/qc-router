---
# Metadata
ticket_id: TICKET-hook-loading-fix-001
session_id: hook-loading-fix
sequence: 001
parent_ticket: null
title: Fix enforcement hook loading and branch detection
cycle_type: development
status: expediter_review
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
- [x] None identified

### HIGH Issues
- [x] None identified

### MEDIUM Issues
- [x] **Pre-existing shellcheck warnings** - Unused variables (SCRIPT_DIR, RED, YELLOW, NC) and SC2155 warnings exist in the codebase. These are not introduced by this change and should be addressed in a separate cleanup ticket.

## Security Review

**Command Injection**: No new vectors introduced. The new `get_file_repo_branch()` function:
- Takes file_path as input and extracts directory using `dirname` (safe)
- Uses `git -C "$file_dir"` with quoted variable (safe)
- No user-controlled data flows into command execution unsafely

**Path Traversal**: The function walks up parent directories to find valid git repos, but this is intentional behavior to handle new file creation. The path validation happens separately via `validate_file_path()` before branch checking occurs in the main flow.

**Race Conditions**: None introduced. File existence checks are for informational purposes only.

**Audit Logging**: Improved - now includes `file_branch` and `file` path in MAIN_OVERRIDE audit logs, providing better forensic information.

## Correctness Review

**Bug 1 Fix (hooks.json)**:
- Changed relative paths to `${CLAUDE_PLUGIN_ROOT}/hooks/...`
- JSON syntax validated
- Follows Claude Code plugin path resolution conventions

**Bug 2 Fix (branch detection)**:
- New `get_file_repo_branch()` correctly uses file's directory, not CWD
- Parent directory walk-up handles new file creation edge case
- Returns empty string for non-git directories (correctly allows operation)
- Original `is_protected_branch()` and `get_current_branch()` preserved for backward compatibility

**Edge Cases Tested**:
1. Existing file in git repo - returns correct branch
2. Non-existent file in existing directory - returns correct branch
3. Non-existent file in non-existent directory (parent exists) - walks up, returns correct branch
4. File outside git repo - returns empty (allows operation)
5. Path with `..` components - handles correctly
6. Deep non-existent nested path - walks up to repo root
7. Completely non-existent path (e.g., `/nonexistent/...`) - returns empty

## Code Quality

- Bash syntax validated (bash -n passes)
- Follows existing code patterns in the file
- Clear comments explaining the fix and function behavior
- Functions are additive, not replacing existing ones
- Debug logging maintained

## Approval Decision
APPROVED

## Rationale

The implementation correctly fixes both identified bugs:
1. Hook loading now uses `${CLAUDE_PLUGIN_ROOT}` for absolute path resolution
2. Protected branch detection now uses the file's directory, not CWD, correctly handling worktree scenarios

The code is:
- Secure (no injection vectors, proper quoting)
- Correct (all edge cases handled appropriately)
- Backward compatible (original functions preserved)
- Well-documented (clear comments)
- Tested (syntax valid, manual function testing passed)

The only note is pre-existing shellcheck warnings that should be addressed in a future cleanup ticket, but these are not blockers.

**Status Update**: 2025-12-02 18:25 - Changed status to `expediter_review`

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
