---
# Metadata
ticket_id: TICKET-hook-loading-fix-001
session_id: hook-loading-fix
sequence: 001
parent_ticket: null
title: Fix enforcement hook loading and branch detection
cycle_type: development
status: open
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
[To be filled by code-developer]

## Questions/Concerns
[To be filled by code-developer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [Date/time] - Changed status to `critic_review`

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
