# Claude Hooks Engine

A declarative, YAML-based rule engine for controlling Claude Code behavior. Define your rules once, use them everywhere.

## The Problem

Claude Code hooks are powerful but hard to manage:

- **Scattered scripts** across machines
- **Duplicated logic** in every Python file  
- **No visibility** into what's actually configured
- **No testing** before deployment
- **No centralization** across workstations

## The Solution

A single rule engine that reads declarative YAML configurations:

```yaml
# Instead of writing Python for every hook...
rules:
  - id: block-file-redirects
    name: Block Bash File Redirects
    trigger:
      event: PreToolUse
      matcher: Bash
    conditions:
      ref: is-output-redirect      # ← Reusable condition
    actions:
      - ref: block-and-log         # ← Reusable action
        params:
          message: "Use Edit tool instead"
```

## Quick Start

### 1. Install

```bash
# Clone or copy the engine files
mkdir -p ~/.claude-hooks
cp dispatcher.py ~/.claude-hooks/
cp cli.py ~/.claude-hooks/
cp -r examples/* ~/.claude-hooks/

# Make CLI available
chmod +x ~/.claude-hooks/cli.py
ln -s ~/.claude-hooks/cli.py /usr/local/bin/claude-hooks

# Install dependency
pip install pyyaml
```

### 2. Configure Claude Code

Generate and install the settings:

```bash
claude-hooks generate-settings > ~/.claude/settings.json
```

Or manually add to your existing `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude-hooks/dispatcher.py"
      }]
    }],
    "PostToolUse": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "python3 ~/.claude-hooks/dispatcher.py"
      }]
    }]
  }
}
```

### 3. Customize Rules

Edit `~/.claude-hooks/rules.yaml` to add your own rules. The example rules block dangerous bash commands and protect sensitive files.

### 4. Validate & Test

```bash
# Validate your configuration
claude-hooks config validate

# List active rules
claude-hooks list

# Test against a sample event
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' > test.json
claude-hooks test test.json

# Explain what rules apply
claude-hooks explain --event PreToolUse --tool Bash --input '{"command":"echo foo > bar.txt"}'
```

## Directory Structure

```
~/.claude-hooks/
├── dispatcher.py         # Single entry point (Claude Code calls this)
├── cli.py                # CLI management tool
├── rules.yaml            # Your rule definitions
├── conditions.yaml       # Reusable conditions
├── actions.yaml          # Reusable actions
└── scripts/
    ├── conditions/       # Custom condition scripts
    └── actions/          # Custom action scripts (logging, notifications)
```

## Configuration Cascade

Configuration loads from multiple locations, with later sources overriding earlier ones:

1. `~/.claude-hooks/` — Global (sync via git!)
2. `~/.claude-hooks/machines/{hostname}/` — Machine-specific
3. `~/.claude/` — User-level
4. `{project}/.claude/` — Project-level

This means you can:
- Share base rules across all machines via git
- Override specific rules per machine
- Add project-specific rules in repos

## Writing Rules

### Basic Rule Structure

```yaml
rules:
  - id: unique-id           # Required: Unique identifier
    name: Human Name        # Display name
    description: Details    # What this rule does
    enabled: true           # Can disable without deleting
    priority: 50            # Higher = evaluated first (default: 50)
    tags: [security, bash]  # For filtering
    
    trigger:                # WHEN does this rule apply?
      event: PreToolUse     # PreToolUse, PostToolUse, Stop, etc.
      matcher: Bash         # Regex for tool name
    
    conditions:             # IF these are true...
      ref: some-condition
    
    actions:                # THEN do these actions
      - ref: some-action
```

### Condition Types

**Regex** - Match a field against a pattern:
```yaml
is-file-redirect:
  type: regex
  field: tool_input.command
  pattern: '>\s*[^|]'
```

**Glob** - Match file paths:
```yaml
is-env-file:
  type: glob
  field: tool_input.file_path
  pattern: "**/.env*"
```

**Compound** - Combine conditions:
```yaml
is-dangerous:
  type: compound
  any:
    - ref: is-rm-rf
    - ref: is-sudo
    - ref: is-redirect
```

**Script** - Run external validation:
```yaml
is-in-protected-dir:
  type: script
  script: conditions/check-protected.py
  timeout: 5
```

### Action Types

**Decision** - Return control to Claude Code:
```yaml
block:
  type: decision
  decision: deny  # deny, allow, or ask
  message: "{{message}}"
```

**Script** - Run external script:
```yaml
notify-slack:
  type: script
  script: actions/slack-notify.py
  async: true
  params:
    channel: "#alerts"
```

**Chain** - Multiple actions:
```yaml
block-and-log:
  type: chain
  actions:
    - ref: log-to-file
    - ref: block
```

## CLI Commands

```bash
claude-hooks list                    # Show all rules
claude-hooks list --event PreToolUse # Filter by event
claude-hooks list --tag security     # Filter by tag

claude-hooks config show             # Show configuration sources
claude-hooks config validate         # Check for errors

claude-hooks explain --event PreToolUse --tool Bash --input '{"command":"..."}'
                                     # Explain what would happen

claude-hooks test event.json         # Test against sample

claude-hooks logs                    # View recent logs
claude-hooks logs --blocked          # View blocked operations

claude-hooks generate-settings       # Generate settings.json
```

## Common Use Cases

### 1. Security Hardening

Block dangerous bash patterns to prevent bypass of Edit tool restrictions:

```yaml
# Already included in examples/rules.yaml
- id: block-bash-file-redirects
  trigger: {event: PreToolUse, matcher: Bash}
  conditions:
    any: [ref: is-output-redirect, ref: is-tee-command, ref: is-sed-inplace]
  actions:
    - ref: block
      params: {message: "Use Edit tool for file modifications"}
```

### 2. Audit/Read-Only Mode

Enable observation-only mode where Claude reports but doesn't modify:

```yaml
- id: audit-mode
  enabled: true
  priority: 200  # High priority overrides other rules
  trigger: {event: PreToolUse, matcher: "Edit|Write|MultiEdit|Bash"}
  conditions:
    any: [ref: is-write-tool, ref: is-bash-write-command]
  actions:
    - ref: block
      params:
        message: |
          AUDIT MODE: Report your findings instead of modifying files.
          File: {{file_path}}
```

### 3. Project-Specific Rules

Add rules in `{project}/.claude/hooks.yaml`:

```yaml
# Only allow editing src/ and test/ directories
- id: restrict-edit-paths
  trigger: {event: PreToolUse, matcher: Edit}
  conditions:
    not:
      any:
        - type: glob
          field: tool_input.file_path
          pattern: "src/**"
        - type: glob
          field: tool_input.file_path
          pattern: "test/**"
  actions:
    - ref: block
      params: {message: "Edits restricted to src/ and test/ directories"}
```

### 4. Logging & Observability

Log all operations for audit trail:

```yaml
- id: log-all-operations
  priority: 1  # Low priority = runs after other rules
  trigger: {event: PostToolUse, matcher: ""}
  actions:
    - type: log
      params: {log_file: "~/.claude/logs/all-operations.jsonl"}
```

## Syncing Across Machines

The recommended approach is to version control your `~/.claude-hooks` directory:

```bash
# Initial setup
cd ~/.claude-hooks
git init
git remote add origin git@github.com:you/claude-hooks-config.git
git push -u origin main

# On other machines
git clone git@github.com:you/claude-hooks-config.git ~/.claude-hooks

# Keep in sync
cd ~/.claude-hooks && git pull
```

## Troubleshooting

### Rules not applying?

1. Check hook is configured: Look at `/hooks` in Claude Code
2. Validate config: `claude-hooks config validate`
3. Test the scenario: `claude-hooks explain --event X --tool Y --input '{...}'`

### Performance issues?

- The dispatcher caches parsed YAML (LRU cache)
- Avoid expensive scripts in conditions (use `cache: session`)
- Keep rule count reasonable (<100 for fast evaluation)

### Hook errors?

- The engine fails safe (continues on error)
- Check stderr output in Claude Code
- Enable debug logging: `CLAUDE_HOOKS_DEBUG=1`

## Contributing

See [ARCHITECTURE.md](ARCHITECTURE.md) for design details and future roadmap.
