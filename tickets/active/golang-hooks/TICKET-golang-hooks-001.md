---
# Metadata
ticket_id: TICKET-golang-hooks-001
session_id: golang-hooks
sequence: 001
parent_ticket: null
title: Convert hook shell scripts to Golang
cycle_type: development
status: in_progress
created: 2025-12-07 23:30
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/golang-hooks
---

# Requirements

## What Needs to Be Done
Convert the 4 hook shell scripts in `hooks/` to compiled Golang binaries for better performance, testability, and maintainability.

## Acceptance Criteria
- [ ] `enforce-quality-cycle.go` - Replaces enforce-quality-cycle.sh (21KB)
- [x] `set-quality-cycle-context.go` - Replaces set-quality-cycle-context.sh (9KB) ✓ COMPLETE
- [x] `validate-config.go` - Replaces validate-config.sh (10KB) ✓ COMPLETE
- [x] `validate-ticket.go` - Replaces validate-ticket.sh (3KB) ✓ COMPLETE
- [ ] All hooks pass existing test scenarios
- [ ] Compiled binaries work with hooks.json registration
- [ ] Shell scripts removed after Go versions validated

# Context

## Why Golang
1. **Performance** - Compiled binaries vs interpreted shell
2. **Testability** - Unit tests, mocking, coverage
3. **Maintainability** - Type safety, better error handling
4. **Portability** - Single binary, no shell dependencies
5. **Consistency** - Match workflow-guard patterns

## Current Scripts

| Script | Size | Complexity |
|--------|------|------------|
| enforce-quality-cycle.sh | 21KB | HIGH - Core enforcement logic |
| validate-config.sh | 10KB | MEDIUM - Config validation |
| set-quality-cycle-context.sh | 9KB | MEDIUM - Context injection |
| validate-ticket.sh | 3KB | LOW - Ticket validation |

## Hook Input/Output

Hooks receive JSON via stdin:
```json
{
  "session_id": "abc123",
  "cwd": "/path/to/project",
  "tool_name": "Bash",
  "tool_input": {...},
  "tool_response": {...}
}
```

Output JSON to stdout for Claude Code to process.

## Migration Strategy
1. Implement Go version alongside shell script
2. Test Go version matches shell behavior
3. Update hooks.json to use Go binary
4. Remove shell script after validation

# Implementation Notes

## Creator Section
_To be filled during implementation_

## Critic Section
_To be filled during review_

## Expediter Section
_To be filled during validation_

## Changelog
### [2025-12-08 18:45] - SessionStart Hook Complete
- Implemented `cmd/set-quality-cycle-context/main.go` (339 lines)
- All agent type patterns working: code, docs, prompt, plugin cycles
- Worktree and ticket detection patterns working
- Security validations: path validation, session ID format
- Atomic file operations with temp file + rename
- Debug logging integrated
- Tested: All scenarios passing
- Committed: bd9fdca

### [2025-12-08 18:41] - Validation Hooks Complete
- Implemented `cmd/validate-config/main.go` (393 lines)
- Implemented `cmd/validate-ticket/main.go` (150 lines)
- Both hooks tested and working
- Committed: Previous commits

### [2025-12-07 23:30] - Ticket Created
- Initial ticket for Golang conversion
- 4 shell scripts identified for conversion

**Progress: 3/4 hooks complete (75%). Only enforce-quality-cycle.go remaining.**

# References
- hooks/hooks.json - Hook registration
- workflow-guard patterns for Go hook implementation
