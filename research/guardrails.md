# Claude Code: Controlling AI Behavior with Hooks and Sandboxing

Claude Code can be reliably constrained through **PreToolUse hooks** for real-time interception, **permission rules** for allowlist/denylist control, **subagents** for read-only modes, and **OS-level sandboxing** for comprehensive bypass prevention. This report documents working implementations with actual code you can deploy.

---

## 1. PreToolUse Hooks: Blocking and Confirmation Workflows

Claude Code's hook system intercepts tool calls before execution through PreToolUse events, enabling blocking, user confirmation, or auto-approval based on custom logic. The hook receives JSON on stdin with full context including tool name, input parameters, and session metadata.

### Basic Hook Configuration

Place this in `~/.claude/settings.json` (user-level) or `.claude/settings.json` (project-level):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/pre_tool_use.py"
          }
        ]
      }
    ]
  }
}
```

The `matcher` field accepts tool names or regex patterns. Common tools to intercept include `Bash`, `Edit`, `Write`, `MultiEdit`, and `NotebookEdit`.

### Hook Communication Protocol

Hooks communicate via **exit codes** and **JSON output**:

| Exit Code | Behavior                                              |
| --------- | ----------------------------------------------------- |
| 0         | Continue normally (show standard permission prompt)   |
| 2         | Block execution; stderr feeds back to Claude as error |

JSON output on stdout can override behavior:

```json
{"permissionDecision": "deny"}   // Block without prompting
{"permissionDecision": "allow"}  // Auto-approve, bypass UI
{"permissionDecision": "ask"}    // Force user confirmation prompt
```

### Comprehensive Dangerous Command Blocking

This Python hook blocks file-modifying Bash patterns including redirects, in-place edits, and indirect write methods:

```python
#!/usr/bin/env python3
"""
PreToolUse hook that blocks dangerous Bash commands.
Save to: ~/.claude/hooks/block_dangerous.py
Make executable: chmod +x ~/.claude/hooks/block_dangerous.py
"""
import json
import sys
import re

# Patterns that indicate file modification via Bash
DANGEROUS_PATTERNS = [
    r'>\s*[^|]',              # Output redirection (but not pipes)
    r'>>\s*',                 # Append redirection
    r'rm\s+.*-[rf]',          # rm with force/recursive flags
    r'rm\s+[^-]',             # rm without flags (still deletes)
    r'\bcat\b.*>\s*',         # cat > file
    r'\becho\b.*>\s*',        # echo > file
    r'\btee\b',               # tee writes to files
    r'\bsed\b.*-i',           # in-place sed edits
    r'\bperl\b.*-i',          # in-place perl edits
    r'\bmv\b',                # move/rename files
    r'\bcp\b',                # copy files (creates new files)
    r'\bchmod\b',             # change permissions
    r'\bchown\b',             # change ownership
    r'\bdd\b',                # low-level copy
    r'\btruncate\b',          # truncate files
    r'\binstall\b',           # install command writes files
    r'\bpatch\b',             # patch modifies files
    r'python.*-c.*open\(',    # Python one-liner file writes
    r'node.*-e.*fs\.',        # Node one-liner file operations
]

def main():
    # Read hook input from stdin
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)  # Continue if we can't parse input

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    # Only check Bash commands
    if tool_name != "Bash":
        sys.exit(0)

    command = tool_input.get("command", "")

    # Check each dangerous pattern
    for pattern in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            # Exit code 2 blocks execution and sends stderr to Claude
            print(f"BLOCKED: Command matches dangerous pattern '{pattern}'",
                  file=sys.stderr)
            print(f"Command was: {command}", file=sys.stderr)
            print("Use the Edit tool for file modifications instead.",
                  file=sys.stderr)
            sys.exit(2)

    # Command appears safe, continue normally
    sys.exit(0)

if __name__ == "__main__":
    main()
```

### Confirmation Workflow Hook

This hook requires explicit user confirmation for any file modification:

```python
#!/usr/bin/env python3
"""
PreToolUse hook that requires confirmation for all writes.
Outputs JSON to force the "ask" permission decision.
"""
import json
import sys

WRITE_TOOLS = ["Edit", "Write", "MultiEdit", "NotebookEdit"]

def main():
    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool_name = input_data.get("tool_name", "")

    if tool_name in WRITE_TOOLS:
        # Force user confirmation prompt
        output = {
            "permissionDecision": "ask",
            "message": f"Tool '{tool_name}' wants to modify files. Approve?"
        }
        print(json.dumps(output))

    sys.exit(0)

if __name__ == "__main__":
    main()
```

### Community Hook Libraries

Several open-source libraries extend Claude Code hooks functionality:

**[johnlindquist/claude-hooks](https://github.com/johnlindquist/claude-hooks)** - TypeScript-based hooks with a cleaner API and built-in patterns for common use cases.

**[gabriel-dehan/claude_hooks](https://github.com/gabriel-dehan/claude_hooks)** - Ruby DSL for writing hooks, useful if your team prefers Ruby over Python/TypeScript.

**[decider/claude-hooks](https://github.com/decider/claude-hooks)** - Comprehensive hooks for enforcing clean code practices with hierarchical configuration support.

---

## 2. Permission System: Allow/Deny Rules

Beyond hooks, Claude Code has a built-in permission system using allow/deny rules with glob patterns. These go in your settings.json:

```json
{
  "permissions": {
    "allow": [
      "Edit(./src/**)",
      "Edit(./tests/**)",
      "Bash(npm test)",
      "Bash(npm run lint)",
      "Read(**)"
    ],
    "deny": [
      "Edit(.env*)",
      "Edit(**/secrets/**)",
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "Bash(*>*)",
      "Bash(*>>*)"
    ]
  }
}
```

The pattern format is `ToolName(glob_pattern)` or `ToolName(command_prefix:args)` for Bash. Deny rules take precedence over allow rules.

### Blocking Bash Redirects via Permissions

To block file writes through Bash redirection without a custom hook:

```json
{
  "permissions": {
    "deny": [
      "Bash(echo:*>*)",
      "Bash(cat:*>*)",
      "Bash(printf:*>*)",
      "Bash(tee:*)",
      "Bash(sed:-i*)",
      "Bash(perl:-i*)",
      "Bash(dd:*)",
      "Bash(truncate:*)"
    ]
  }
}
```

Note that permission rules use simple glob matching, not full regex, so complex patterns still require hooks.

---

## 3. Read-Only "Report Don't Fix" Mode via Subagents

Claude Code's Agent SDK supports dedicated subagents with restricted tool access. The built-in **Explore subagent** operates in strict read-only mode by default.

### Configuring a Read-Only Analysis Subagent

```typescript
// In your Claude Code agent configuration
const result = await query({
  prompt: "Analyze this codebase for security vulnerabilities",
  options: {
    agents: {
      "security-auditor": {
        description: "Security analysis specialist - observation only",
        prompt: `You are a security auditor. Analyze code for vulnerabilities 
                 and report findings. NEVER modify any files. Only observe 
                 and document issues with specific file:line references.`,
        tools: ["Read", "Grep", "Glob", "LS"], // Read-only tools only
        model: "sonnet",
      },
    },
  },
});
```

### Built-in Explore Subagent Restrictions

The Explore subagent is pre-configured with read-only commands:

- **Permitted**: `ls`, `cat`, `head`, `tail`, `find`, `grep`, `git log`, `git show`, `git diff`
- **Blocked**: Any command that modifies filesystem state

You can invoke it in your prompts with patterns like "use the explore agent to investigate..." to ensure read-only analysis.

### Enforcing Report-Only via System Prompt

For simpler enforcement without subagent configuration, include explicit instructions in your CLAUDE.md or system prompt:

```markdown
## Operating Mode: AUDIT ONLY

You are operating in audit/observation mode. Your responsibilities:

1. ANALYZE code for issues (bugs, security, performance, style)
2. REPORT findings with specific file paths and line numbers
3. SUGGEST fixes as code snippets the user can apply
4. NEVER use Edit, Write, or file-modifying Bash commands

When you find an issue, format your report as:

- **File**: path/to/file.py
- **Line**: 42-45
- **Issue**: Description of the problem
- **Suggested Fix**: Code snippet showing the correction

The user will apply fixes manually after reviewing your report.
```

---

## 4. Bypass Prevention: OS-Level Sandboxing

Application-level blocking (hooks and permissions) can be bypassed by determined agents. An agent blocked from using Edit might try `echo "content" > file.txt`, `python -c "open('f','w').write('x')"`, or base64-encoded payloads. **Comprehensive bypass prevention requires kernel-level enforcement.**

### Anthropic's sandbox-runtime

Anthropic provides an open-source sandbox runtime at **[@anthropic-ai/sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime)** that enforces filesystem and network restrictions at the OS level:

```json
{
  "network": {
    "allowedDomains": ["github.com", "*.npmjs.org", "pypi.org"],
    "allowLocalBinding": false
  },
  "filesystem": {
    "denyRead": ["~/.ssh", "~/.aws", "~/.config/gh"],
    "allowWrite": [".", "/tmp"],
    "denyWrite": [".env", ".env.*", "**/secrets/**", "**/.git/**"]
  }
}
```

On **macOS**, this generates dynamic Seatbelt profiles for `sandbox-exec`. On **Linux**, it uses `bubblewrap` (bwrap) for namespace isolation with seccomp BPF filtering.

### Enabling Claude Code's Built-in Sandbox

Claude Code has sandboxing built in. Enable it in settings:

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

With `autoAllowBashIfSandboxed: true`, Bash commands run without individual confirmation prompts since the sandbox prevents damage.

### Defense in Depth Configuration

The most robust approach layers all mechanisms. Here's a production-ready `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Edit(./src/**)",
      "Edit(./tests/**)",
      "Read(**)",
      "Bash(npm:*)",
      "Bash(git:status)",
      "Bash(git:diff*)",
      "Bash(git:log*)"
    ],
    "deny": [
      "Read(~/.ssh/**)",
      "Read(~/.aws/**)",
      "Read(.env*)",
      "Edit(.env*)",
      "Edit(**/node_modules/**)",
      "Bash(rm:*)",
      "Bash(sudo:*)",
      "Bash(*>*)",
      "Bash(*>>*)",
      "Bash(curl:*|*)",
      "Bash(wget:*|*)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/block_dangerous.py"
          }
        ]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/hooks/confirm_writes.py"
          }
        ]
      }
    ]
  },
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true
  }
}
```

---

## Key Implementation Principles

**Allowlists beat blocklists.** Blocklists fail open (unknown commands pass through); allowlists fail closed (only explicitly permitted operations work). When possible, define what's allowed rather than trying to enumerate everything dangerous.

**Layer your defenses.** Hooks catch specific patterns, permissions provide broad rules, and sandboxing prevents bypass via alternative tools or encoded payloads.

**Exit code 2 is your friend.** When a hook exits with code 2, stderr content feeds back to Claude as an error message. Use this to explain _why_ something was blocked and suggest alternatives.

**Test bypass attempts.** After configuring restrictions, actively try to bypass them. Can Claude write files via Python one-liners? Via base64 decoding? Via downloading a script and executing it? Each bypass you find is a pattern to add to your hooks.

---

## Quick Reference: Hook Input Schema

The JSON your PreToolUse hook receives on stdin:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "echo 'hello' > output.txt"
  },
  "session_id": "abc123",
  "conversation_id": "def456",
  "tool_call_id": "ghi789"
}
```

For Edit tools:

```json
{
  "tool_name": "Edit",
  "tool_input": {
    "file_path": "./src/main.py",
    "old_string": "original code",
    "new_string": "modified code"
  }
}
```

---

## Sources

- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
- [Claude Code Sandboxing Docs](https://docs.claude.com/en/docs/claude-code/sandboxing)
- [Claude Code Subagents Docs](https://docs.claude.com/en/docs/claude-code/sub-agents)
- [johnlindquist/claude-hooks](https://github.com/johnlindquist/claude-hooks)
- [gabriel-dehan/claude_hooks](https://github.com/gabriel-dehan/claude_hooks)
- [decider/claude-hooks](https://github.com/decider/claude-hooks)
- [anthropic-experimental/sandbox-runtime](https://github.com/anthropic-experimental/sandbox-runtime)
