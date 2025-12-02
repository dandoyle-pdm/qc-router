# QC Router Plugin

Quality Cycle Router plugin for Claude Code - enables Creator/Critic/Judge quality cycles for code and documentation workflows.

## Overview

This plugin provides:

- **9 Quality Cycle Agents**: code-developer, code-reviewer, code-tester, prompt-engineer, prompt-reviewer, prompt-tester, tech-writer, tech-editor, tech-publisher
- **Quality Cycle Hooks**: Enforce quality cycle requirements on file modifications and script execution
- **Agentic Quality Workflow Skill**: Comprehensive guide for git worktree-based quality workflows

## Installation

1. Copy this plugin directory to `~/.claude/plugins/qc-router/`
2. Enable the plugin in Claude Code settings
3. Manually copy hook scripts (see Manual Steps below)

## Components

### Agents

Located in `./agents/`:

| Agent | Role | Purpose |
|-------|------|---------|
| code-developer | Creator | Implements code based on tickets |
| code-reviewer | Critic | Reviews code, generates audit reports |
| code-tester | Judge | Runs tests, makes routing decisions |
| prompt-engineer | Creator | Designs prompts and recipes |
| prompt-reviewer | Critic | Reviews prompt effectiveness |
| prompt-tester | Judge | Validates prompts with sample inputs |
| tech-writer | Creator | Writes documentation |
| tech-editor | Critic | Reviews documentation quality |
| tech-publisher | Judge | Approves documentation for publication |

### Hooks

Located in `./hooks/`:

- `hooks.json` - Hook configuration
- `enforce-quality-cycle.sh` - Blocks protected operations outside quality cycles
- `set-quality-cycle-context.sh` - Detects and sets quality cycle context
- `validate-config.sh` - Validates hook configuration

### Skills

Located in `./skills/agentic-quality-workflow/`:

- `SKILL.md` - Main skill guide for worktree-based quality workflows
- `references/` - 12 detailed reference documents covering:
  - Worktree fundamentals and operations
  - Integration workflows
  - Code quality workflows and procedures
  - Code review checklists
  - Best practices and troubleshooting

## Quality Cycle Flow

```
Creator -> Critic(s) -> Judge -> [routing]
```

1. **Creator** implements work, updates ticket -> status: `critic_review`
2. **Critic(s)** review, provide findings -> status: `expediter_review`
3. **Judge** validates, makes routing decision:
   - APPROVE -> ticket moves to `completed/{branch}/`
   - ROUTE_BACK -> Creator addresses findings, cycle restarts
   - ESCALATE -> coordinator intervention needed

## Recipe Selection

| Recipe | Work Type | Agents |
|--------|-----------|--------|
| R1 | Production code | code-developer -> code-reviewer -> code-tester |
| R2 | Documentation (100+ lines) | tech-writer -> tech-editor -> tech-publisher |
| R3 | Handoff prompts | tech-editor (quick check) |
| R4 | Read-only queries | None (fast path) |
| R5 | Config/minor changes | Single reviewer |

## Manual Steps Required

Due to hook protection, shell scripts must be copied manually:

```bash
# Copy qc-router hook scripts
cp ~/.claude/hooks/enforce-quality-cycle.sh ~/.claude/plugins/qc-router/hooks/
cp ~/.claude/hooks/set-quality-cycle-context.sh ~/.claude/plugins/qc-router/hooks/
cp ~/.claude/hooks/validate-config.sh ~/.claude/plugins/qc-router/hooks/

# Make scripts executable
chmod +x ~/.claude/plugins/qc-router/hooks/*.sh
```

## Configuration

The `hooks.json` file configures:

- **SessionStart**: Runs `set-quality-cycle-context.sh` to detect agent context
- **PreToolUse**: Runs `enforce-quality-cycle.sh` on Bash/Edit/Write tools

Hooks use `${CLAUDE_PLUGIN_ROOT}` to reference script paths relative to the plugin root.

## Author

Dan Doyle

## Version

1.0.0
