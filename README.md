# QC Router

Quality Cycle Router - Creator/Critic/Judge quality cycles for code and documentation workflows.

## Overview

QC Router provides a structured quality assurance framework for Claude Code that enforces Creator/Critic/Judge patterns across different types of work. It includes specialized agents for code development, documentation, and prompt engineering, along with hooks that enforce quality cycles during sessions.

## Features

- **9 Specialized Agents** covering code, documentation, and prompt engineering workflows
- **Session Hooks** for automatic quality cycle context detection and enforcement
- **Git Worktree Integration** for isolated development environments
- **Ticket-Based Workflow** with structured handoffs between agents

## Installation

```bash
# Add local marketplace (first time only)
/plugin marketplace add ~/.claude/plugins

# Install plugin
/plugin install qc-router@local-plugins
```

**Restart Claude Code after installation to load the plugin.**

### Updating the Plugin

Content changes (hooks, agents, skills) only require a **restart** - no reinstall needed. The plugin installation registers the plugin location; contents are loaded fresh each session.

## What's Included

### Agents

QC Router provides three complete quality cycles, each with Creator, Critic, and Judge agents:

#### Code Quality Cycle (R1)

| Agent              | Role    | Description                                                               |
| ------------------ | ------- | ------------------------------------------------------------------------- |
| **code-developer** | Creator | Writes initial code implementations and iterates based on review feedback |
| **code-reviewer**  | Critic  | Performs adversarial review with CRITICAL/HIGH/MEDIUM severity levels     |
| **code-tester**    | Judge   | Runs tests, evaluates audits, and makes final routing decisions           |

#### Documentation Quality Cycle (R2)

| Agent              | Role    | Description                                                          |
| ------------------ | ------- | -------------------------------------------------------------------- |
| **tech-writer**    | Creator | Creates clear documentation and iterates based on editorial feedback |
| **tech-editor**    | Critic  | Performs editorial review with prioritized quality findings          |
| **tech-publisher** | Judge   | Validates readability and coherency, approves for publication        |

#### Prompt Engineering Quality Cycle

| Agent               | Role    | Description                                                      |
| ------------------- | ------- | ---------------------------------------------------------------- |
| **prompt-engineer** | Creator | Designs prompts using pillar-based methodology                   |
| **prompt-reviewer** | Critic  | Reviews prompts for clarity, specificity, and edge case coverage |
| **prompt-tester**   | Judge   | Tests prompt effectiveness and makes approval decisions          |

### Hooks

The plugin registers two hooks that integrate with Claude Code sessions:

| Hook                             | Trigger                        | Purpose                                                              |
| -------------------------------- | ------------------------------ | -------------------------------------------------------------------- |
| **set-quality-cycle-context.sh** | SessionStart                   | Detects working context and sets quality cycle environment variables |
| **enforce-quality-cycle.sh**     | PreToolUse (Bash, Edit, Write) | Enforces quality cycle compliance before file modifications          |

Both hooks are security-hardened with:

- Path validation to prevent traversal attacks
- Command injection prevention
- Atomic file operations
- Session state management

### Skills

| Skill                        | Description                                                                                                                                                                                                 |
| ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **agentic-quality-workflow** | Comprehensive procedures for git worktree management and quality cycle workflows. Includes 12 reference documents covering ticket systems, code review checklists, troubleshooting, and emergency recovery. |

## Quality Recipes

Select the appropriate recipe based on work type:

| Recipe | Work Type                  | Cycle                                          |
| ------ | -------------------------- | ---------------------------------------------- |
| **R1** | Production code            | code-developer -> code-reviewer -> code-tester |
| **R2** | Documentation (100+ lines) | tech-writer -> tech-editor -> tech-publisher   |
| **R3** | Handoff prompts            | tech-editor (quick check)                      |
| **R4** | Read-only queries          | None (fast path)                               |
| **R5** | Config/minor changes       | Single reviewer                                |

## Workflow Pattern

All work follows the Creator/Critic/Judge pattern:

```
Creator completes work -> updates ticket -> status: critic_review
    |
Critic(s) review -> provide findings -> status: expediter_review
    |
Judge validates -> makes routing decision:
    - APPROVE -> ticket moves to completed/{branch}/
    - ROUTE_BACK -> Creator addresses findings, cycle restarts
    - ESCALATE -> coordinator intervention needed
```

## Integration with workflow-guard

The workflow-guard plugin (`~/.claude/plugins/workflow-guard/`) uses qc-router agent identities to enforce quality cycle requirements.

### How It Works

1. workflow-guard blocks file modifications (Edit/Write/NotebookEdit) unless a quality agent is detected
2. When you dispatch a quality agent via Task tool, the AGENT.md content appears in the subagent's transcript
3. workflow-guard reads the transcript and looks for agent identity markers
4. If a recognized quality agent is found, the modification is allowed

### Agent Identity Markers

Each AGENT.md contains an identity string in its invocation template:

```
working as the {agent-name} agent
```

Example from plugin-engineer:

```
You are a pragmatic plugin developer working as the plugin-engineer agent in a quality cycle workflow.
```

### Recognized Quality Agents

workflow-guard recognizes these agents:

**Code Quality Cycle:**
- code-developer, code-reviewer, code-tester

**Documentation Quality Cycle:**
- tech-writer, tech-editor, tech-publisher

**Prompt Engineering Quality Cycle:**
- prompt-engineer, prompt-reviewer, prompt-tester

**Plugin Quality Cycle:**
- plugin-engineer, plugin-reviewer, plugin-tester

### Maintaining Compatibility

When creating or modifying agent AGENT.md files:

1. Keep the identity string pattern: "working as the {name} agent"
2. Place it early in the invocation template
3. Ensure it's part of the prompt that gets sent to the subagent

## Configuration

The plugin uses environment-based configuration through session state:

- **Session State Directory**: `~/.claude/.session-state/`
- **Debug Logs**: `~/.claude/logs/hooks-debug.log`

No additional configuration is required after installation.

## Contributing

See [DEVELOPER.md](DEVELOPER.md) for technical documentation on:

- Adding/modifying agents, hooks, and skills
- Hook development patterns and security hardening
- Testing procedures (hooks require restart)
- Contribution workflow and ticket system

For Claude Code sessions working on this plugin, see [CLAUDE.md](CLAUDE.md) for project context and development rules.

## License
