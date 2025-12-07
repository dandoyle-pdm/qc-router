#!/usr/bin/env python3
"""
Claude Hooks Engine - Dispatcher

This is the single entry point that Claude Code calls for all hooks.
It loads the declarative YAML rules and evaluates them against incoming events.

Usage in ~/.claude/settings.json:
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "python3 ~/.claude-hooks/dispatcher.py"}]
    }],
    "PostToolUse": [{
      "matcher": "",
      "hooks": [{"type": "command", "command": "python3 ~/.claude-hooks/dispatcher.py"}]
    }]
  }
}
"""

import json
import sys
import os
import re
import fnmatch
import hashlib
import subprocess
from pathlib import Path
from dataclasses import dataclass, field
from typing import Any, Optional
from functools import lru_cache
import yaml  # pip install pyyaml

# =============================================================================
# Configuration
# =============================================================================

# Where to look for configuration files (in order of precedence, later wins)
CONFIG_PATHS = [
    Path.home() / ".claude-hooks",           # Global config (git-synced)
    Path.home() / ".claude-hooks" / "machines" / os.uname().nodename,  # Machine-specific
    Path.home() / ".claude",                 # User-level
    Path(os.environ.get("CLAUDE_PROJECT_DIR", ".")) / ".claude",  # Project-level
]

# Cache directory for parsed configs
CACHE_DIR = Path.home() / ".cache" / "claude-hooks"

# =============================================================================
# Data Structures
# =============================================================================

@dataclass
class HookEvent:
    """Represents an incoming hook event from Claude Code."""
    hook_type: str           # PreToolUse, PostToolUse, Stop, etc.
    tool_name: str           # Bash, Edit, Write, etc.
    tool_input: dict         # Tool-specific parameters
    session_id: str
    raw: dict                # Original JSON for script access
    
    @classmethod
    def from_stdin(cls) -> "HookEvent":
        """Parse hook event from stdin JSON."""
        try:
            raw = json.load(sys.stdin)
        except json.JSONDecodeError:
            raw = {}
        
        return cls(
            hook_type=os.environ.get("CLAUDE_HOOK_TYPE", raw.get("hook_type", "Unknown")),
            tool_name=raw.get("tool_name", ""),
            tool_input=raw.get("tool_input", {}),
            session_id=raw.get("session_id", ""),
            raw=raw
        )


@dataclass
class HookResponse:
    """Response to return to Claude Code."""
    exit_code: int = 0
    stdout: Optional[str] = None
    stderr: Optional[str] = None
    decision: Optional[str] = None  # allow, deny, ask
    
    def emit(self):
        """Output the response and exit."""
        if self.stdout:
            # If we have a decision, output as JSON
            if self.decision:
                output = {"permissionDecision": self.decision}
                if self.stderr:
                    output["message"] = self.stderr
                print(json.dumps(output))
            else:
                print(self.stdout)
        
        if self.stderr and not self.decision:
            print(self.stderr, file=sys.stderr)
        
        sys.exit(self.exit_code)
    
    @classmethod
    def continue_(cls) -> "HookResponse":
        """Continue normally (exit 0, no output)."""
        return cls(exit_code=0)
    
    @classmethod
    def block(cls, message: str) -> "HookResponse":
        """Block the operation (exit 2, message to stderr)."""
        return cls(exit_code=2, stderr=message, decision="deny")
    
    @classmethod
    def allow(cls) -> "HookResponse":
        """Allow without prompting."""
        return cls(exit_code=0, decision="allow")
    
    @classmethod
    def ask(cls, message: str) -> "HookResponse":
        """Prompt user for confirmation."""
        return cls(exit_code=0, decision="ask", stderr=message)


@dataclass
class Rule:
    """A single rule definition."""
    id: str
    name: str
    description: str = ""
    enabled: bool = True
    priority: int = 50
    tags: list = field(default_factory=list)
    trigger: dict = field(default_factory=dict)
    conditions: dict = field(default_factory=dict)
    actions: list = field(default_factory=list)
    
    def matches_event(self, event: HookEvent) -> bool:
        """Check if this rule's trigger matches the event."""
        # Check event type
        if self.trigger.get("event") != event.hook_type:
            return False
        
        # Check tool matcher (regex)
        matcher = self.trigger.get("matcher", "")
        if matcher:
            if not re.match(matcher, event.tool_name, re.IGNORECASE):
                return False
        
        return True


@dataclass
class Config:
    """Complete loaded configuration."""
    rules: list = field(default_factory=list)
    conditions: dict = field(default_factory=dict)
    actions: dict = field(default_factory=dict)
    scripts_dir: Path = None

# =============================================================================
# Configuration Loading
# =============================================================================

def load_yaml_file(path: Path) -> dict:
    """Load a YAML file, returning empty dict if not found."""
    if not path.exists():
        return {}
    try:
        with open(path) as f:
            return yaml.safe_load(f) or {}
    except Exception as e:
        print(f"Warning: Failed to load {path}: {e}", file=sys.stderr)
        return {}


def get_config_hash() -> str:
    """Get hash of all config files for cache invalidation."""
    hasher = hashlib.md5()
    for base_path in CONFIG_PATHS:
        for yaml_file in ["rules.yaml", "conditions.yaml", "actions.yaml", "hooks.yaml"]:
            path = base_path / yaml_file
            if path.exists():
                hasher.update(str(path.stat().st_mtime).encode())
    return hasher.hexdigest()


@lru_cache(maxsize=1)
def load_config() -> Config:
    """
    Load and merge configuration from all config paths.
    Results are cached for performance.
    """
    config = Config()
    all_rules = {}      # id -> Rule (for deduplication)
    all_conditions = {} # id -> condition definition
    all_actions = {}    # id -> action definition
    
    for base_path in CONFIG_PATHS:
        if not base_path.exists():
            continue
        
        # Load rules
        rules_data = load_yaml_file(base_path / "rules.yaml")
        if not rules_data:
            rules_data = load_yaml_file(base_path / "hooks.yaml")  # Alternative name
        
        for rule_def in rules_data.get("rules", []):
            rule = Rule(
                id=rule_def.get("id", ""),
                name=rule_def.get("name", ""),
                description=rule_def.get("description", ""),
                enabled=rule_def.get("enabled", True),
                priority=rule_def.get("priority", 50),
                tags=rule_def.get("tags", []),
                trigger=rule_def.get("trigger", {}),
                conditions=rule_def.get("conditions", {}),
                actions=rule_def.get("actions", [])
            )
            if rule.id:
                all_rules[rule.id] = rule
        
        # Load conditions
        cond_data = load_yaml_file(base_path / "conditions.yaml")
        all_conditions.update(cond_data.get("conditions", {}))
        
        # Load actions
        action_data = load_yaml_file(base_path / "actions.yaml")
        all_actions.update(action_data.get("actions", {}))
        
        # Track scripts directory
        scripts_dir = base_path / "scripts"
        if scripts_dir.exists():
            config.scripts_dir = scripts_dir
    
    # Convert rules dict to sorted list
    config.rules = sorted(
        [r for r in all_rules.values() if r.enabled],
        key=lambda r: r.priority,
        reverse=True  # Higher priority first
    )
    config.conditions = all_conditions
    config.actions = all_actions
    
    return config

# =============================================================================
# Condition Evaluation
# =============================================================================

def get_field_value(obj: dict, field_path: str) -> Any:
    """Get a nested field value using dot notation (e.g., 'tool_input.command')."""
    parts = field_path.split(".")
    value = obj
    for part in parts:
        if isinstance(value, dict):
            value = value.get(part)
        else:
            return None
    return value


def evaluate_condition(condition: dict, event: HookEvent, config: Config) -> bool:
    """
    Evaluate a single condition against an event.
    
    Condition types:
    - ref: Reference to a named condition
    - regex: Match field against regex pattern
    - glob: Match field against glob pattern
    - equals: Compare field to value
    - exists: Check if field exists
    - script: Run external script
    - compound (all/any/not): Combine conditions
    """
    # Handle condition reference
    if "ref" in condition:
        ref_name = condition["ref"]
        if ref_name not in config.conditions:
            print(f"Warning: Unknown condition reference: {ref_name}", file=sys.stderr)
            return False
        # Merge referenced condition with any overrides
        resolved = {**config.conditions[ref_name], **{k: v for k, v in condition.items() if k != "ref"}}
        return evaluate_condition(resolved, event, config)
    
    cond_type = condition.get("type", "")
    
    # Compound conditions
    if "all" in condition:
        return all(evaluate_condition(c, event, config) for c in condition["all"])
    
    if "any" in condition:
        return any(evaluate_condition(c, event, config) for c in condition["any"])
    
    if "not" in condition:
        return not evaluate_condition(condition["not"], event, config)
    
    # Get field value for field-based conditions
    field_path = condition.get("field", "")
    field_value = get_field_value(event.raw, field_path) if field_path else None
    
    # Regex condition
    if cond_type == "regex":
        if field_value is None:
            return False
        pattern = condition.get("pattern", "")
        flags = 0
        if "ignorecase" in condition.get("flags", []):
            flags |= re.IGNORECASE
        try:
            return bool(re.search(pattern, str(field_value), flags))
        except re.error:
            return False
    
    # Glob condition
    if cond_type == "glob":
        if field_value is None:
            return False
        pattern = condition.get("pattern", "")
        return fnmatch.fnmatch(str(field_value), pattern)
    
    # Equals condition
    if cond_type == "equals":
        if field_value is None:
            return False
        value = condition.get("value", "")
        operator = condition.get("operator", "equals")
        field_str = str(field_value)
        value_str = str(value)
        
        if operator == "equals":
            return field_str == value_str
        elif operator == "startswith":
            return field_str.startswith(value_str)
        elif operator == "endswith":
            return field_str.endswith(value_str)
        elif operator == "contains":
            return value_str in field_str
        return False
    
    # Exists condition
    if cond_type == "exists":
        return field_value is not None
    
    # Script condition
    if cond_type == "script":
        script_path = condition.get("script", "")
        if config.scripts_dir:
            full_path = config.scripts_dir / script_path
        else:
            full_path = Path(script_path).expanduser()
        
        if not full_path.exists():
            print(f"Warning: Condition script not found: {full_path}", file=sys.stderr)
            return False
        
        try:
            result = subprocess.run(
                [str(full_path)],
                input=json.dumps(event.raw),
                capture_output=True,
                text=True,
                timeout=condition.get("timeout", 5)
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Warning: Condition script failed: {e}", file=sys.stderr)
            return False
    
    # Builtin conditions
    if cond_type == "builtin":
        builtin_name = condition.get("builtin", "")
        return evaluate_builtin_condition(builtin_name, condition.get("params", {}), event)
    
    # Empty or unknown condition type - default to true (match all)
    if not cond_type and not condition:
        return True
    
    return False


def evaluate_builtin_condition(name: str, params: dict, event: HookEvent) -> bool:
    """Evaluate a built-in condition."""
    
    if name == "sensitive-file":
        # Check if file path matches sensitive patterns
        file_path = event.tool_input.get("file_path", "")
        patterns = params.get("patterns", [
            "**/.env*",
            "**/*.pem",
            "**/*.key",
            "**/*secret*",
            "**/credentials*",
            "**/.ssh/*",
            "**/.aws/*"
        ])
        return any(fnmatch.fnmatch(file_path, p) for p in patterns)
    
    if name == "dangerous-command":
        # Check for dangerous bash command patterns
        command = event.tool_input.get("command", "")
        dangerous_patterns = params.get("patterns", [
            r'rm\s+.*-[rf]',
            r'>\s*/',
            r'sudo\s',
            r'chmod\s+777',
            r'curl.*\|\s*bash',
            r'wget.*\|\s*bash',
        ])
        return any(re.search(p, command, re.IGNORECASE) for p in dangerous_patterns)
    
    return False

# =============================================================================
# Action Execution
# =============================================================================

def render_template(template: str, context: dict) -> str:
    """Simple template rendering with {{variable}} syntax."""
    result = template
    for key, value in context.items():
        result = result.replace(f"{{{{{key}}}}}", str(value))
    return result


def execute_action(action: dict, event: HookEvent, config: Config) -> Optional[HookResponse]:
    """
    Execute a single action and return a response if terminal.
    
    Action types:
    - decision: Return allow/deny/ask to Claude Code
    - script: Run external script
    - transform: Modify tool input
    - chain: Run multiple actions
    - conditional: Action with embedded condition
    """
    # Handle action reference
    if "ref" in action:
        ref_name = action["ref"]
        if ref_name not in config.actions:
            print(f"Warning: Unknown action reference: {ref_name}", file=sys.stderr)
            return None
        # Merge referenced action with params overrides
        resolved = {**config.actions[ref_name]}
        if "params" in action:
            resolved["params"] = {**resolved.get("params", {}), **action["params"]}
        return execute_action(resolved, event, config)
    
    action_type = action.get("type", "")
    params = action.get("params", {})
    
    # Create template context
    context = {
        "tool_name": event.tool_name,
        "tool_input": json.dumps(event.tool_input),
        **params,
        **event.tool_input  # Allow access to tool_input fields directly
    }
    
    # Decision action - terminal, returns response
    if action_type == "decision":
        decision = action.get("decision", "block")
        message = render_template(action.get("message", params.get("message", "")), context)
        
        if decision == "block" or decision == "deny":
            return HookResponse.block(message)
        elif decision == "allow":
            return HookResponse.allow()
        elif decision == "ask":
            return HookResponse.ask(message)
    
    # Script action - runs external script
    if action_type == "script":
        script_path = action.get("script", "")
        if config.scripts_dir:
            full_path = config.scripts_dir / script_path
        else:
            full_path = Path(script_path).expanduser()
        
        if not full_path.exists():
            print(f"Warning: Action script not found: {full_path}", file=sys.stderr)
            return None
        
        try:
            # Pass params as environment variables
            env = os.environ.copy()
            for key, value in params.items():
                env[f"HOOK_{key.upper()}"] = str(value)
            
            if action.get("async", False):
                # Fire and forget
                subprocess.Popen(
                    [str(full_path)],
                    stdin=subprocess.PIPE,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    env=env
                )
            else:
                result = subprocess.run(
                    [str(full_path)],
                    input=json.dumps(event.raw),
                    capture_output=True,
                    text=True,
                    timeout=action.get("timeout", 30),
                    env=env
                )
                # Script can return a decision via exit code
                if result.returncode == 2:
                    return HookResponse.block(result.stderr or "Blocked by script")
        except Exception as e:
            print(f"Warning: Action script failed: {e}", file=sys.stderr)
        
        return None
    
    # Chain action - runs multiple actions
    if action_type == "chain":
        for sub_action in action.get("actions", []):
            response = execute_action(sub_action, event, config)
            if response:
                return response
        return None
    
    # Conditional action
    if action_type == "conditional":
        condition = action.get("condition", {})
        if evaluate_condition(condition, event, config):
            return execute_action(action.get("then", {}), event, config)
        elif "else" in action:
            return execute_action(action["else"], event, config)
        return None
    
    # Log action (convenience built-in)
    if action_type == "log":
        log_file = Path(params.get("log_file", "~/.claude/logs/hooks.jsonl")).expanduser()
        log_file.parent.mkdir(parents=True, exist_ok=True)
        
        log_entry = {
            "timestamp": __import__("datetime").datetime.now().isoformat(),
            "event_type": event.hook_type,
            "tool_name": event.tool_name,
            "tool_input": event.tool_input,
            "session_id": event.session_id,
        }
        
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry) + "\n")
        
        return None
    
    return None

# =============================================================================
# Main Dispatcher
# =============================================================================

def dispatch(event: HookEvent) -> HookResponse:
    """
    Main dispatch logic:
    1. Load configuration
    2. Find matching rules
    3. Evaluate conditions
    4. Execute actions
    5. Return response
    """
    config = load_config()
    
    # Find rules that match this event
    matching_rules = [r for r in config.rules if r.matches_event(event)]
    
    # Evaluate each rule in priority order
    for rule in matching_rules:
        # Check conditions (empty conditions = always match)
        if rule.conditions:
            if not evaluate_condition(rule.conditions, event, config):
                continue
        
        # Execute actions
        for action in rule.actions:
            response = execute_action(action, event, config)
            if response:
                return response
    
    # No terminal action executed - continue normally
    return HookResponse.continue_()


def main():
    """Entry point."""
    try:
        event = HookEvent.from_stdin()
        response = dispatch(event)
        response.emit()
    except Exception as e:
        # On error, continue normally (fail-safe)
        print(f"Hook engine error: {e}", file=sys.stderr)
        sys.exit(0)


if __name__ == "__main__":
    main()
