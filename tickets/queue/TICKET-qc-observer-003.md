---
# Metadata
ticket_id: TICKET-qc-observer-003
session_id: qc-observer
sequence: 003
parent_ticket: TICKET-qc-observer-001
title: Implement QC Observer Hooks in workflow-guard
cycle_type: development
status: open
created: 2025-12-07 18:00
worktree_path: null
---

# Requirements

## What Needs to Be Done
Implement the 4 observer hooks in workflow-guard plugin. These hooks capture quality cycle observations across all projects using the plugin.

## Acceptance Criteria
- [ ] qc-observe-hook.js - PreToolUse hook that evaluates before action, blocks if not in quality cycle
- [ ] qc-capture-hook.js - PostToolUse hook that captures what happened, queues for pattern analysis
- [ ] qc-context-hook.js - SessionStart hook that injects recent violation summary
- [ ] qc-summary-hook.js - SessionEnd hook that generates violation summary and improvement prompts
- [ ] All hooks ≤50 lines (artifact standard)
- [ ] Hooks registered in workflow-guard hooks.json
- [ ] Storage writes to ~/.novacloud/observations/

# Context

## Architecture Reference
See: /home/ddoyle/.claude/plugins/qc-router/docs/QC-OBSERVER-USE-CASES.md

## Hook Responsibilities

| Hook | Trigger | Responsibility |
|------|---------|----------------|
| qc-observe-hook.js | PreToolUse | Block code edits without quality agent, check artifact standards |
| qc-capture-hook.js | PostToolUse | Capture tool execution, log violations, queue for patterns |
| qc-context-hook.js | SessionStart | Inject violation summary ("3 violations in last 5 sessions") |
| qc-summary-hook.js | SessionEnd | Generate session summary, update pattern frequency, create improvement prompts |

## Enable/Disable Model
- Check `~/.novacloud/observer-rules.json` for enabled state
- Short-circuit immediately if disabled (no processing cycles)
- Per-project overrides via `.qc-observer-rules.json` in project root

## Session ID Detection
- Subagents have prefixed session IDs: `code-developer-abc123`
- Use prefix to identify which quality agent is active
- No agent prefix = main thread (potential violation for code edits)

# Implementation Notes
[To be filled by plugin-engineer in workflow-guard]

# References
- Use case doc: docs/QC-OBSERVER-USE-CASES.md
- Parent tickets: TICKET-qc-observer-001, TICKET-qc-observer-002
- Target repo: ~/.claude/plugins/workflow-guard/
