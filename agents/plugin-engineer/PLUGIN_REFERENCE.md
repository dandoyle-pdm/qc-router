# Plugin Resource Reference

This document provides reference structures for Claude Code plugin resources.

## plugin.json Structure

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Brief description",
  "author": {
    "name": "Author Name",
    "url": "https://github.com/author"
  },
  "hooks": "hooks/hooks.json",
  "agents": "./agents",
  "skills": "./skills"
}
```

## hooks.json Structure

```json
{
  "SessionStart": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "hooks/script.sh",
          "timeout": 10
        }
      ]
    }
  ],
  "PreToolUse": [
    {
      "matcher": "Bash|Edit|Write",
      "hooks": [
        {
          "type": "command",
          "command": "hooks/guard.sh",
          "timeout": 10
        }
      ]
    }
  ]
}
```

## Hook Events

| Event | Description | Can Block |
|-------|-------------|-----------|
| SessionStart | Runs when Claude Code session begins | No |
| PreToolUse | Runs before a tool is executed | Yes |
| PostToolUse | Runs after a tool completes | No |
| Notification | Runs for notification events | No |

## Hook Script Template

```bash
#!/usr/bin/env bash
set -euo pipefail

# Exit codes:
# 0 = Allow/success - operation proceeds normally
# 1 = Error - script failed unexpectedly (Claude Code logs warning)
# 2 = Block - intentionally block operation with message

# First line of output = reason
# Subsequent lines = detailed guidance

# Your logic here
exit 0
```

## Path Conventions

- Hook paths in hooks.json are RELATIVE to plugin root
- Correct: `hooks/my-script.sh`
- Incorrect: `./hooks/my-script.sh` or absolute paths

## Lifecycle Notes

- Hooks load at session START only
- Changes to hooks require Claude Code restart to take effect
