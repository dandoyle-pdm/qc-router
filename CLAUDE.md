# CLAUDE.md

## Project Identity

You are working on the **QC Router Plugin** - a Claude Code plugin that provides Creator/Critic/Judge quality cycles for code, documentation, and prompt engineering workflows.

**This is infrastructure code.** Changes to hooks, agents, or skills affect ALL projects using this plugin. Test thoroughly and follow quality cycles strictly.

## Essential Context

**Plugin Structure:**
```
~/.claude/plugins/qc-router/
├── .claude-plugin/plugin.json  # Plugin manifest
├── agents/                     # 9 specialized agents (3 cycles)
│   ├── code-developer/        # Code cycle: Creator
│   ├── code-reviewer/         # Code cycle: Critic
│   ├── code-tester/           # Code cycle: Judge
│   ├── tech-writer/           # Docs cycle: Creator
│   ├── tech-editor/           # Docs cycle: Critic
│   ├── tech-publisher/        # Docs cycle: Judge
│   ├── prompt-engineer/       # Prompt cycle: Creator
│   ├── prompt-reviewer/       # Prompt cycle: Critic
│   ├── prompt-tester/         # Prompt cycle: Judge
│   ├── plugin-engineer/       # Plugin cycle: Creator
│   ├── plugin-reviewer/       # Plugin cycle: Critic
│   └── plugin-tester/         # Plugin cycle: Judge
├── hooks/                     # Quality enforcement hooks
│   ├── hooks.json            # Hook registration
│   ├── enforce-quality-cycle.sh         # PreToolUse enforcement
│   ├── set-quality-cycle-context.sh     # SessionStart context
│   └── validate-config.sh    # Configuration validation
├── skills/
│   └── agentic-quality-workflow/  # Git worktree + quality cycle procedures
├── tickets/                  # Ticket infrastructure
│   ├── queue/
│   ├── active/
│   ├── completed/
│   └── TEMPLATE.md
└── README.md                # Plugin overview
```

**Key Directories:**
- `agents/` - Agent definitions (AGENT.md files)
- `hooks/` - Session hooks that enforce quality cycles
- `skills/` - Claude Code skills with reference documentation
- `tickets/` - Ticket system for tracked work

## Quality Recipes

Select recipe based on work type:

| Recipe | Work Type | Cycle |
|--------|-----------|-------|
| **R1** | Production code | code-developer → code-reviewer → code-tester |
| **R2** | Documentation (100+ lines) | tech-writer → tech-editor → tech-publisher |
| **R3** | Handoff prompts | tech-editor (quick check) |
| **R4** | Read-only queries | None (fast path) |
| **R5** | Config/minor changes | Single reviewer |

**Plugin Changes:** Use **plugin-engineer → plugin-reviewer → plugin-tester** for all plugin modifications OR standard R1 chain.

## Ticket Workflow

1. Create from `tickets/TEMPLATE.md`
2. Place in `tickets/queue/`
3. Activate with worktree scripts
4. Work completes → move to `tickets/completed/{branch}/`

Ticket status flow: `open` → `in_progress` → `critic_review` → `expediter_review` → `approved`

## Development Rules

**CRITICAL - These Rules Protect All Projects:**

1. **All plugin changes go through quality cycles** - Use plugin-engineer chain or R1
2. **Test hooks manually before committing** - Hook bugs affect every session
3. **Hooks require Claude Code restart** - Content changes need restart, not reinstall
4. **Security-first for hooks** - Path validation, no command injection, atomic operations
5. **Never bypass enforcement hook** - It protects quality in all projects
6. **Semantic commits** - Use `feat:`, `fix:`, `refactor:`, `docs:` prefixes
7. **Agent changes are high-risk** - Test agent behavior across multiple scenarios

**Testing Hooks:**
```bash
# Test set-quality-cycle-context.sh
bash ~/.claude/plugins/qc-router/hooks/set-quality-cycle-context.sh

# Test enforce-quality-cycle.sh
QC_ENFORCEMENT_MODE=enabled \
QC_CYCLE_TYPE=development \
QC_CYCLE_PHASE=creator \
bash ~/.claude/plugins/qc-router/hooks/enforce-quality-cycle.sh Bash "cd /tmp"
```

**What NOT to Do:**
- Do NOT modify hooks without plugin quality cycle
- Do NOT commit untested hook changes
- Do NOT break backward compatibility for agents
- Do NOT hardcode paths (use environment variables)
- Do NOT skip security validation in hooks

## Quick Reference

| Need | Location |
|------|----------|
| Plugin overview | README.md |
| Agent definitions | agents/{agent-name}/AGENT.md |
| Hook configuration | hooks/hooks.json |
| Enforcement hook | hooks/enforce-quality-cycle.sh |
| Context hook | hooks/set-quality-cycle-context.sh |
| Ticket template | tickets/TEMPLATE.md |
| Quality procedures | skills/agentic-quality-workflow/SKILL.md |
| Worktree operations | skills/agentic-quality-workflow/references/worktree-operations.md |
| Emergency recovery | skills/agentic-quality-workflow/references/emergency-recovery.md |

## Installation & Updates

```bash
# Install (first time)
/plugin marketplace add ~/.claude/plugins
/plugin install qc-router@local-plugins

# Update after content changes
# Restart Claude Code (no reinstall needed)
```

**Session State:**
- State directory: `~/.claude/.session-state/`
- Debug logs: `~/.claude/logs/hooks-debug.log`

## Commit Conventions

Semantic commits with appropriate prefix:

```
feat: add prompt engineering quality cycle agents
fix: correct path validation in enforce-quality-cycle hook
refactor: simplify worktree creation in activation script
docs: update README with plugin lifecycle details
```
