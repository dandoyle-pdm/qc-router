---
# Metadata
ticket_id: TICKET-protected-branches-001
session_id: protected-branches
sequence: 001
parent_ticket: null
title: Add production and staging to protected branches
cycle_type: development
status: open
created: 2025-12-02 18:15
worktree_path: null
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
[To be filled by code-developer]

## Changes Made
- File changes:
- Commits:

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

## [2025-12-02 18:15] - Created
- Ticket created for adding production/staging branch handling
