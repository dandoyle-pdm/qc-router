# Session Handoff: Workflow-Guard Hook Development

## Context

Two plugins work as a pair:
- **qc-router** (`~/.claude/plugins/qc-router/`) - Quality agents, quality cycle context
- **workflow-guard** (`~/.claude/plugins/workflow-guard/`) - Enforcement hooks, branch protection, ticket lifecycle

**Key insight from this session:** Blocking/enforcement hooks belong in workflow-guard, NOT qc-router.

## Current State

### qc-router (this repo)
```bash
cd ~/.claude/plugins/qc-router
git log --oneline -3
# 6ff6805 chore: ticket housekeeping  ← HEAD (main, synced with origin)
# 82bb8b7 fix: correct agent count in README (9 -> 12)
# edbefb2 docs: approve TICKET-workflow-guard-integration-001
```

**Preserved branch:** `ticket-naming-hook` has implementation that needs to MOVE to workflow-guard:
```bash
git log --oneline ticket-naming-hook -3
# a06337e review: approve ticket naming validation hook
# 84713e4 docs: update ticket with implementation notes
# ae68900 feat: add ticket naming validation hook  ← Implementation here
```

**Active ticket:** `tickets/queue/TICKET-ticket-naming-hook-001.md`

### workflow-guard
Explore before starting - use Explore agent with thoroughness="very thorough" to review current state.

## Tasks (Priority Order)

### Task 1: Move Ticket-Naming Hook to workflow-guard

The implementation in commit `ae68900` was built for qc-router but belongs in workflow-guard.

**Steps:**
1. Create ticket in workflow-guard for this work
2. Create worktree in workflow-guard
3. Adapt the hook for workflow-guard patterns:
   - File: `hooks/validate-ticket-naming.sh`
   - Register in `hooks/hooks.json` under Edit|Write matcher
4. Quality cycle in workflow-guard
5. PR to merge

**Spec (from this session):**

Pattern: `^TICKET-[a-z0-9]+(-[a-z0-9]+)*-[0-9]{3}\.md$`

| Valid | Invalid | Problem |
|-------|---------|---------|
| `TICKET-mwaa-go-rewrite-001.md` | `TICKET-MWAA-002-go-rewrite.md` | Uppercase, sequence wrong position |
| `TICKET-qc-hook-fix-002.md` | `ticket-foo-001.md` | Lowercase prefix |
| | `TICKET-foo_bar-001.md` | Underscore |
| | `TICKET-foo-1.md` | Sequence not 3 digits |

Error message format:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Invalid ticket name: {filename}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Required format: TICKET-{session-id}-{sequence}.md
  • session-id: lowercase kebab-case (e.g., mwaa-go-rewrite)
  • sequence: 3 digits (e.g., 001)

Example: TICKET-mwaa-go-rewrite-001.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Task 2: Root Document Protection Hook

Create hook to protect root-level .md files from unauthorized writes.

**Location:** workflow-guard `hooks/protect-root-docs.sh`

**Behavior:**
- Intercepts Edit|Write to `/*.md` at project root
- Whitelist approved docs (README.md? others TBD)
- Block unapproved root doc modifications
- Changes to protected docs require PR workflow

**Discovery task:** Use Explore agent to inventory root docs in both plugins and categorize as PROTECTED vs ALLOWED.

### Task 3: Update qc-router Documentation

**Needs quality cycle (R5 - single reviewer):**
- Update CLAUDE.md to document workflow-guard partnership
- Clarify which hooks belong where
- Add cross-reference to workflow-guard

### Task 4: Clean Up qc-router

After Task 1 completes:
- Delete `ticket-naming-hook` branch (implementation moved)
- Close/archive `TICKET-ticket-naming-hook-001.md`
- Remove any obsolete hook references

## Workflow-Guard Hook Patterns

From exploration this session, workflow-guard hooks follow these patterns:

**Exit codes:**
- `exit 0` - Allow operation
- `exit 1` - Block, requires user confirmation
- `exit 2` - Block with error message

**JSON parsing:**
```bash
# Primary: jq
tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""')

# Fallback: sed
tool_name=$(printf '%s\n' "${json_input}" | sed -n 's/.*"tool_name"\s*:\s*"\([^"]*\)".*/\1/p')
```

**Existing hooks in workflow-guard:**
| Hook | Matcher | Purpose |
|------|---------|---------|
| `block-main-commits.sh` | Bash | Blocks commits on protected branches (except ticket lifecycle) |
| `enforce-pr-workflow.sh` | Bash | Blocks direct merges to protected branches |
| `enforce-ticket-completion.sh` | Bash | Ensures ticket in completed/ before PR |
| `block-mcp-git-commits.sh` | mcp__git__* | Blocks MCP git tools on protected branches |
| `confirm-code-edits.sh` | Edit\|Write | Requires confirmation for code edits |

**Ticket exception on main:** `block-main-commits.sh` has `is_ticket_lifecycle_only()` that allows commits on main for:
- Files in `tickets/(queue|active|completed|archive)/`
- Files matching `TICKET-*.md` or `HANDOFF-*.md`

## Two-Commit Model for Tickets

Tickets on main are allowed (for visibility). Expected commits:
1. **Create ticket** in `queue/` → commit → push immediately
2. **Activate ticket** (remove from `queue/`) → commit → push immediately

Then all work happens on branch via worktree. This is not a bug - it's the intended model.

## Session Lessons Learned

1. **Never implement directly on main** - Always use worktree workflow
2. **Blocking hooks belong in workflow-guard** - qc-router provides agents only
3. **All changes need quality cycle** - Even "quick" doc updates
4. **Push immediately after ticket commits** - Visibility for coordination
5. **Two plugins, one system** - qc-router + workflow-guard work together

## Commands to Start

```bash
# Verify qc-router state
cd ~/.claude/plugins/qc-router
git status
git log --oneline -3
git branch -v

# Explore workflow-guard before starting
cd ~/.claude/plugins/workflow-guard
git status
git log --oneline -5
ls hooks/
```

## Process Reminder

1. Create ticket in target project's `tickets/queue/`
2. Commit and push ticket immediately
3. Activate with worktree (creates branch, moves ticket to active/)
4. Work in worktree - quality cycle: Creator → Critic → Judge
5. Complete ticket (move to completed/)
6. PR to merge
