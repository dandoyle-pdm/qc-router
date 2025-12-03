---
# Metadata
ticket_id: TICKET-protected-branches-001
session_id: protected-branches
sequence: 001
parent_ticket: null
title: Add production and staging to protected branches
cycle_type: development
status: critic_review
created: 2025-12-02 18:15
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/protected-branches
---

# Requirements

## What Needs to Be Done

Update `enforce-quality-cycle.sh` to handle additional protected branches:

1. **production** - Fully protected (block like main/master/develop)
2. **staging** - Warning only (log warning encouraging branch creation, but allow)

### Implementation Details

1. Add `production` to the fully protected branch list in `is_file_on_protected_branch()`

2. Create new return code for "warning" state:
   - Return 0 = protected (block)
   - Return 1 = not protected (allow)
   - Return 2 = warning (allow with warning)

3. Add `generate_staging_warning_message()` function that:
   - Warns user they're editing on staging
   - Encourages creating a branch from staging
   - Logs to debug log for audit

4. Update main logic to handle return code 2 from branch check

## Acceptance Criteria

- [ ] `production` branch is fully blocked (same as main)
- [ ] `staging` branch shows warning but allows operation
- [ ] Warning message encourages creating branches from staging
- [ ] Warning is logged to debug log
- [ ] Existing protected branches unchanged (main, master, develop, release/*)
- [ ] Manual test confirms both behaviors

# Context

## Why This Work Matters

Team workflow prefers branches created from staging. Production should never have direct edits.

# Creator Section

## Implementation Notes

### Approach
Updated `enforce-quality-cycle.sh` to support three-tier branch protection:
- **Tier 1 (Block)**: main, master, develop, production, release/* - returns 0
- **Tier 2 (Warn)**: staging - returns 2
- **Tier 3 (Allow)**: all other branches - returns 1

### Key Changes

1. **`is_file_on_protected_branch()` (lines 162-186)**
   - Added documentation comment for return codes
   - Added `production` to the fully protected case (return 0)
   - Added `staging` as new case returning 2 (warning)

2. **`generate_staging_warning_message()` (lines 423-448)**
   - New function with yellow warning box styling
   - Informs user they're on staging branch
   - Suggests: `git checkout -b feature/your-feature staging`
   - Lists benefits of branching from staging
   - Ends with "Proceeding with operation..."

3. **`main()` branch check logic (lines 505-551)**
   - Refactored to capture return code from `is_file_on_protected_branch()`
   - Uses case statement to handle all three return codes
   - Code 0: Block (existing behavior)
   - Code 2: Log warning + show warning message + allow
   - Code 1: Allow silently (existing behavior)

### Testing Notes for Reviewer
- Syntax check passes: `bash -n enforce-quality-cycle.sh`
- Warning is output to stderr (non-blocking)
- Debug log receives warning entry for audit trail

## Changes Made
- File changes: `hooks/enforce-quality-cycle.sh` (+62/-16 lines)
- Commits: `6569295` feat: add production and staging branch protection

# Critic Section

## Audit Findings
[To be filled by code-reviewer]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

# Expediter Section

## Validation Results
[To be filled by code-tester]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

# Changelog

## [2025-12-02 18:30] - Creator Phase Complete
- Implementation complete, ready for critic review
- Commit: 6569295

## [2025-12-02 18:15] - Created
- Ticket created for adding production/staging branch handling
