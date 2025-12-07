# Claude Hooks Engine: A Declarative Rule Engine for Claude Code

## Vision

Transform Claude Code hooks from scattered Python scripts into a **centralized, declarative rule engine** where behaviors are defined in YAML and logic is encapsulated in reusable, testable components.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         BEFORE (Current State)                       │
│                                                                      │
│   settings.json → hook1.py                                          │
│                 → hook2.py    (Each script is standalone,           │
│                 → hook3.py     duplicated across machines,          │
│                 → ...          hard to manage and introspect)       │
└─────────────────────────────────────────────────────────────────────┘

                              ⬇️ TRANSFORMATION ⬇️

┌─────────────────────────────────────────────────────────────────────┐
│                         AFTER (This System)                          │
│                                                                      │
│   settings.json → dispatcher.py → Rule Engine                       │
│                                         │                            │
│                          ┌──────────────┼──────────────┐            │
│                          ▼              ▼              ▼            │
│                      rules.yaml   conditions.yaml  actions.yaml     │
│                          │              │              │            │
│                          └──────────────┼──────────────┘            │
│                                         ▼                           │
│                              Reusable Scripts Library               │
│                                                                      │
│   - Single entry point (dispatcher)                                 │
│   - Declarative YAML rules                                          │
│   - Centralized across machines (git-synced)                        │
│   - Introspectable via CLI/UX                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Concepts

### 1. The Rule

A rule is the fundamental unit: **"When X happens, if Y is true, do Z."**

```yaml
rules:
  - id: block-file-redirects
    name: Block Bash File Redirects
    description: Prevent file writes via shell redirection
    enabled: true
    priority: 100
    
    trigger:                    # WHEN: What event activates this rule?
      event: PreToolUse
      matcher: Bash
    
    conditions:                 # IF: What must be true?
      any:
        - ref: is-file-redirect
        - ref: is-append-redirect
    
    actions:                    # DO: What actions to take?
      - ref: block
        params:
          message: "Use Edit tool instead of shell redirection"
```

### 2. Conditions (The "If" Logic)

Conditions are reusable tests that evaluate to true/false. They can be:

| Type | Description | Example |
|------|-------------|---------|
| `regex` | Pattern match against a field | Check if command contains `>` |
| `glob` | Glob pattern match | Check if file matches `*.env` |
| `script` | External script returns exit code | Complex validation logic |
| `compound` | Combine other conditions | `all`, `any`, `not` |
| `builtin` | Pre-defined common checks | `is-sensitive-file`, `is-git-dir` |

### 3. Actions (The "Do" Logic)

Actions are what happens when conditions match:

| Type | Description | Example |
|------|-------------|---------|
| `decision` | Return allow/deny/ask to Claude Code | Block the operation |
| `script` | Run an external script | Log to file, send notification |
| `transform` | Modify the tool input | Add `--dry-run` flag |
| `chain` | Run multiple actions in sequence | Log then block |

### 4. Layered Configuration

Configuration cascades from global to local, with each layer able to override or extend:

```
~/.claude-hooks/                      # GLOBAL (synced via git)
    ├── config.yaml                   # Global settings
    ├── conditions.yaml               # Reusable conditions
    ├── actions.yaml                  # Reusable actions
    ├── rules.yaml                    # Base rules
    └── scripts/                      # Shared scripts
        ├── conditions/
        └── actions/

~/.claude-hooks/machines/{hostname}/  # MACHINE-SPECIFIC
    └── rules.yaml                    # Machine overrides

~/.claude/hooks/                      # USER-LEVEL
    └── rules.yaml                    # Personal rules

{project}/.claude/                    # PROJECT-LEVEL
    └── hooks.yaml                    # Project-specific rules
```

**Merge Strategy:**
- Rules with same `id` are overridden (later wins)
- New rules are added
- `enabled: false` disables inherited rules
- Conditions/actions are merged by `id`

---

## YAML Schema Reference

### rules.yaml

```yaml
# Version for schema evolution
version: "1.0"

# Metadata
metadata:
  name: "My Hook Rules"
  description: "Central rules for all my Claude Code instances"
  author: "your-name"

# Rule definitions
rules:
  - id: unique-rule-id
    name: Human-Readable Name
    description: What this rule does
    enabled: true                    # Can disable without deleting
    priority: 100                    # Higher = evaluated first (default: 50)
    tags: [security, bash]           # For filtering/organization
    
    trigger:
      event: PreToolUse              # PreToolUse | PostToolUse | Stop | UserPromptSubmit | ...
      matcher: "Bash|Edit"           # Regex for tool name (or empty for all)
    
    conditions:                      # Optional - if omitted, always matches
      # Single condition reference
      ref: condition-id
      
      # Or compound conditions
      all:                           # AND logic
        - ref: condition-1
        - ref: condition-2
      
      any:                           # OR logic
        - ref: condition-1
        - ref: condition-2
      
      not:                           # Negation
        ref: condition-id
    
    actions:                         # What to do when triggered
      - ref: action-id
        params:                      # Override action parameters
          key: value
      
      - type: decision               # Inline action
        decision: block
        message: "Blocked!"
```

### conditions.yaml

```yaml
version: "1.0"

conditions:
  # Regex condition - matches a field against a pattern
  is-file-redirect:
    type: regex
    field: tool_input.command        # Dot notation for nested fields
    pattern: '>\s*[^|]'
    flags: [ignorecase]              # Optional regex flags
  
  # Glob condition - matches file paths
  is-env-file:
    type: glob
    field: tool_input.file_path
    pattern: "**/.env*"
  
  # Script condition - runs external script
  is-in-protected-dir:
    type: script
    script: conditions/check-protected-dir.py
    timeout: 5                       # Seconds
    cache: session                   # none | session | permanent
  
  # Compound condition - combines others
  is-dangerous-bash:
    type: compound
    any:
      - ref: is-file-redirect
      - ref: is-rm-rf
      - ref: is-sudo
  
  # Builtin conditions (pre-defined)
  is-sensitive-file:
    type: builtin
    builtin: sensitive-file          # Pre-defined check
    params:
      patterns:
        - "**/.env*"
        - "**/*.pem"
        - "**/*secret*"
  
  # Field existence check
  has-file-path:
    type: exists
    field: tool_input.file_path
  
  # Value comparison
  is-rm-command:
    type: equals
    field: tool_input.command
    value: "rm"
    operator: startswith             # equals | startswith | endswith | contains
```

### actions.yaml

```yaml
version: "1.0"

actions:
  # Decision action - returns control to Claude Code
  block:
    type: decision
    decision: block                  # block | allow | ask
    message: "{{message}}"           # Template with params
  
  allow-silently:
    type: decision
    decision: allow
  
  require-confirmation:
    type: decision
    decision: ask
    message: "{{message}}"
  
  # Script action - runs external script
  log-to-file:
    type: script
    script: actions/log-event.py
    params:
      log_file: "~/.claude/logs/hooks.jsonl"
    async: true                      # Don't wait for completion
  
  notify-desktop:
    type: script
    script: actions/desktop-notify.py
    params:
      title: "Claude Code Hook"
  
  # Transform action - modifies tool input (PreToolUse only)
  add-dry-run:
    type: transform
    transforms:
      - field: tool_input.command
        operation: append
        value: " --dry-run"
  
  # Chain action - runs multiple actions in sequence
  block-and-log:
    type: chain
    actions:
      - ref: log-to-file
        params:
          log_file: "~/.claude/logs/blocked.jsonl"
      - ref: block
        params:
          message: "{{message}}"
  
  # Conditional action - action with embedded condition
  block-if-not-test:
    type: conditional
    condition:
      not:
        ref: is-test-file
    then:
      ref: block
    else:
      ref: allow-silently
```

---

## Example Configurations

### Security Rules

```yaml
# ~/.claude-hooks/rules.yaml
rules:
  # Block dangerous Bash patterns
  - id: block-dangerous-bash
    name: Block Dangerous Bash Commands
    priority: 100
    trigger:
      event: PreToolUse
      matcher: Bash
    conditions:
      any:
        - ref: is-file-redirect
        - ref: is-rm-rf
        - ref: is-sudo
        - ref: is-curl-pipe-bash
    actions:
      - ref: block
        params:
          message: "Dangerous command pattern detected"
  
  # Protect sensitive files
  - id: protect-sensitive-files
    name: Protect Sensitive Files
    priority: 90
    trigger:
      event: PreToolUse
      matcher: "Edit|Write|MultiEdit"
    conditions:
      ref: is-sensitive-file
    actions:
      - ref: require-confirmation
        params:
          message: "This file contains sensitive data. Are you sure?"
  
  # Require confirmation for all file writes in production dirs
  - id: confirm-production-writes
    name: Confirm Production Directory Writes
    priority: 80
    trigger:
      event: PreToolUse
      matcher: "Edit|Write"
    conditions:
      ref: is-production-path
    actions:
      - ref: require-confirmation
        params:
          message: "Writing to production directory. Confirm?"
```

### Audit/Report-Only Mode

```yaml
# For "report don't fix" mode
rules:
  - id: audit-mode-block-writes
    name: Audit Mode - Block All Writes
    priority: 200
    trigger:
      event: PreToolUse
      matcher: "Edit|Write|MultiEdit|Bash"
    conditions:
      any:
        - ref: is-write-tool
        - ref: is-bash-write
    actions:
      - ref: block
        params:
          message: |
            AUDIT MODE: Write operations are disabled.
            Please report your findings instead of making changes.
            Suggested change: {{tool_input}}
```

### Logging & Observability

```yaml
rules:
  - id: log-all-tool-use
    name: Log All Tool Usage
    priority: 10
    trigger:
      event: PostToolUse
      matcher: ""  # All tools
    actions:
      - ref: log-to-file
        params:
          log_file: "~/.claude/logs/tool-use.jsonl"
          include_output: true
```

---

## The Dispatcher

The dispatcher is the single entry point that Claude Code calls. It:

1. Receives hook event JSON on stdin
2. Loads and caches rule configuration
3. Evaluates rules in priority order
4. Executes matching actions
5. Returns appropriate response

```python
# Simplified dispatcher flow
def dispatch(event: HookEvent) -> HookResponse:
    # 1. Load rules (cached)
    rules = load_rules()
    
    # 2. Filter to applicable rules
    applicable = [r for r in rules 
                  if r.trigger.event == event.hook_type
                  and r.trigger.matches(event.tool_name)]
    
    # 3. Sort by priority (descending)
    applicable.sort(key=lambda r: r.priority, reverse=True)
    
    # 4. Evaluate each rule
    for rule in applicable:
        if evaluate_conditions(rule.conditions, event):
            response = execute_actions(rule.actions, event)
            if response.is_terminal:  # block or allow
                return response
    
    # 5. Default: continue normally
    return HookResponse.continue_()
```

---

## CLI Tool

```bash
# List all active rules
claude-hooks list
claude-hooks list --event PreToolUse
claude-hooks list --tag security

# Show effective configuration
claude-hooks config show
claude-hooks config validate

# Explain what rules apply to a scenario
claude-hooks explain --event PreToolUse --tool Bash --input '{"command": "rm -rf /"}'

# Test rules against sample events
claude-hooks test samples/dangerous-rm.json
claude-hooks test --watch  # Interactive testing

# Debug why something was blocked
claude-hooks logs
claude-hooks logs --tail
claude-hooks why-blocked <log-id>

# Sync configuration from central repo
claude-hooks sync
claude-hooks sync --dry-run

# Generate settings.json from rules
claude-hooks generate-settings > ~/.claude/settings.json
```

---

## UX Dashboard (Future)

A web-based dashboard for:

- **Configuration Browser**: View all rules, conditions, actions hierarchically
- **Event Timeline**: Real-time view of hook events and decisions
- **Rule Editor**: Visual rule builder with validation
- **Analytics**: Which rules fire most, what gets blocked, patterns
- **Machine Overview**: See configuration across all your workstations

---

## Implementation Phases

### Phase 1: Core Engine
- [ ] Dispatcher script (single entry point)
- [ ] YAML schema and parser
- [ ] Basic condition types (regex, glob, compound)
- [ ] Basic action types (decision, script)
- [ ] Configuration loading with caching

### Phase 2: Reusability
- [ ] Conditions library (common patterns)
- [ ] Actions library (log, notify, transform)
- [ ] Layered configuration merging
- [ ] Template variables in messages

### Phase 3: CLI Tool
- [ ] `list`, `config`, `validate` commands
- [ ] `explain` and `test` commands
- [ ] `sync` for central repo
- [ ] `generate-settings` for Claude Code

### Phase 4: Observability
- [ ] Structured logging
- [ ] Event history database
- [ ] `why-blocked` explanations
- [ ] Metrics and analytics

### Phase 5: UX Dashboard
- [ ] Web-based configuration browser
- [ ] Real-time event stream
- [ ] Visual rule editor
- [ ] Multi-machine overview

---

## Design Principles

1. **Declarative over Imperative**: Define *what* you want, not *how* to do it
2. **Composable**: Small, reusable pieces that combine
3. **Fail-Safe**: Invalid config = continue normally (don't break Claude)
4. **Inspectable**: Always know what's configured and why
5. **Testable**: Rules can be validated and tested offline
6. **Cacheable**: Parse YAML once, use many times
7. **Extensible**: Add new condition/action types easily

---

## Why This Approach?

| Problem | Solution |
|---------|----------|
| Scattered scripts across machines | Central git-synced configuration |
| Hard to know what's configured | CLI introspection + dashboard |
| Duplicated logic | Reusable conditions and actions |
| No testing capability | Offline rule testing |
| Changes require editing Python | Edit YAML, reload |
| No audit trail | Structured logging with explanations |
| Can't share configurations | Publishable rule packages |
