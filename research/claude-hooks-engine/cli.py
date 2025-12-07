#!/usr/bin/env python3
"""
Claude Hooks Engine - CLI Tool

Commands for managing, testing, and introspecting hook rules.

Usage:
    claude-hooks list [--event EVENT] [--tag TAG]
    claude-hooks config show
    claude-hooks config validate
    claude-hooks explain --event EVENT --tool TOOL [--input JSON]
    claude-hooks test EVENT_FILE
    claude-hooks logs [--tail] [--blocked]
    claude-hooks generate-settings
    claude-hooks init [--force]
"""

import argparse
import json
import sys
import os
from pathlib import Path
from datetime import datetime
from typing import Optional

import yaml

# Import the dispatcher module (assumes it's in the same directory)
from dispatcher import (
    load_config, 
    HookEvent, 
    dispatch,
    CONFIG_PATHS,
    evaluate_condition,
    Rule
)


def cmd_list(args):
    """List all active rules."""
    config = load_config()
    
    print(f"\n{'='*60}")
    print(f" Active Rules ({len(config.rules)} total)")
    print(f"{'='*60}\n")
    
    for rule in config.rules:
        # Filter by event if specified
        if args.event and rule.trigger.get("event") != args.event:
            continue
        
        # Filter by tag if specified
        if args.tag and args.tag not in rule.tags:
            continue
        
        # Print rule summary
        priority_bar = "█" * min(rule.priority // 10, 10)
        print(f"[{rule.priority:3d}] {priority_bar}")
        print(f"  ID: {rule.id}")
        print(f"  Name: {rule.name}")
        print(f"  Trigger: {rule.trigger.get('event', 'Any')} → {rule.trigger.get('matcher', '*')}")
        if rule.tags:
            print(f"  Tags: {', '.join(rule.tags)}")
        print(f"  Actions: {len(rule.actions)}")
        print()
    
    # Summary
    events = set(r.trigger.get("event", "") for r in config.rules)
    tags = set(t for r in config.rules for t in r.tags)
    print(f"Events covered: {', '.join(sorted(events))}")
    print(f"Tags used: {', '.join(sorted(tags))}")
    print(f"Conditions defined: {len(config.conditions)}")
    print(f"Actions defined: {len(config.actions)}")


def cmd_config_show(args):
    """Show the effective configuration."""
    print(f"\n{'='*60}")
    print(" Configuration Sources (in precedence order)")
    print(f"{'='*60}\n")
    
    for i, path in enumerate(CONFIG_PATHS, 1):
        exists = path.exists()
        status = "✓" if exists else "✗"
        
        print(f"{i}. [{status}] {path}")
        
        if exists:
            for yaml_file in ["rules.yaml", "hooks.yaml", "conditions.yaml", "actions.yaml"]:
                file_path = path / yaml_file
                if file_path.exists():
                    size = file_path.stat().st_size
                    print(f"       └─ {yaml_file} ({size} bytes)")
    
    print()
    
    # Load and show merged config stats
    config = load_config()
    print("Merged Configuration:")
    print(f"  Rules: {len(config.rules)}")
    print(f"  Conditions: {len(config.conditions)}")
    print(f"  Actions: {len(config.actions)}")
    if config.scripts_dir:
        print(f"  Scripts: {config.scripts_dir}")


def cmd_config_validate(args):
    """Validate all configuration files."""
    errors = []
    warnings = []
    
    print(f"\n{'='*60}")
    print(" Validating Configuration")
    print(f"{'='*60}\n")
    
    config = load_config()
    
    # Check for referenced conditions that don't exist
    for rule in config.rules:
        check_condition_refs(rule.conditions, config.conditions, rule.id, errors)
    
    # Check for referenced actions that don't exist
    for rule in config.rules:
        for action in rule.actions:
            if "ref" in action and action["ref"] not in config.actions:
                errors.append(f"Rule '{rule.id}' references unknown action: {action['ref']}")
    
    # Check for duplicate rule IDs (would be overwritten)
    all_rule_ids = []
    for base_path in CONFIG_PATHS:
        rules_data = {}
        for yaml_file in ["rules.yaml", "hooks.yaml"]:
            path = base_path / yaml_file
            if path.exists():
                try:
                    with open(path) as f:
                        rules_data = yaml.safe_load(f) or {}
                except Exception as e:
                    errors.append(f"Failed to parse {path}: {e}")
                    continue
        
        for rule_def in rules_data.get("rules", []):
            rule_id = rule_def.get("id", "")
            if rule_id in [r[0] for r in all_rule_ids]:
                prev_path = next(r[1] for r in all_rule_ids if r[0] == rule_id)
                warnings.append(f"Rule '{rule_id}' defined in {base_path} overrides {prev_path}")
            all_rule_ids.append((rule_id, base_path))
    
    # Print results
    if errors:
        print("ERRORS:")
        for error in errors:
            print(f"  ✗ {error}")
        print()
    
    if warnings:
        print("WARNINGS:")
        for warning in warnings:
            print(f"  ⚠ {warning}")
        print()
    
    if not errors and not warnings:
        print("✓ Configuration is valid!")
    
    return 1 if errors else 0


def check_condition_refs(condition: dict, available: dict, rule_id: str, errors: list):
    """Recursively check condition references."""
    if not condition:
        return
    
    if "ref" in condition:
        if condition["ref"] not in available:
            errors.append(f"Rule '{rule_id}' references unknown condition: {condition['ref']}")
    
    for key in ["all", "any"]:
        if key in condition:
            for sub in condition[key]:
                check_condition_refs(sub, available, rule_id, errors)
    
    if "not" in condition:
        check_condition_refs(condition["not"], available, rule_id, errors)


def cmd_explain(args):
    """Explain what rules would apply to a given scenario."""
    config = load_config()
    
    # Build a synthetic event
    tool_input = {}
    if args.input:
        try:
            tool_input = json.loads(args.input)
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON input: {args.input}")
            return 1
    
    event = HookEvent(
        hook_type=args.event,
        tool_name=args.tool,
        tool_input=tool_input,
        session_id="explain-session",
        raw={
            "hook_type": args.event,
            "tool_name": args.tool,
            "tool_input": tool_input
        }
    )
    
    print(f"\n{'='*60}")
    print(f" Explaining: {args.event} → {args.tool}")
    print(f"{'='*60}\n")
    
    print("Input:")
    print(f"  {json.dumps(tool_input, indent=2)}\n")
    
    # Find matching rules
    matching_rules = [r for r in config.rules if r.matches_event(event)]
    
    print(f"Matching Rules ({len(matching_rules)} of {len(config.rules)}):\n")
    
    for rule in matching_rules:
        # Evaluate conditions
        conditions_match = True
        if rule.conditions:
            conditions_match = evaluate_condition(rule.conditions, event, config)
        
        status = "✓ WOULD FIRE" if conditions_match else "✗ conditions not met"
        print(f"  [{rule.priority:3d}] {rule.id}")
        print(f"        {status}")
        
        if conditions_match and rule.actions:
            print(f"        Actions: {[a.get('ref', a.get('type', 'unknown')) for a in rule.actions]}")
        print()
    
    # Simulate dispatch
    print("Simulated Dispatch Result:")
    response = dispatch(event)
    if response.decision:
        print(f"  Decision: {response.decision}")
    if response.stderr:
        print(f"  Message: {response.stderr}")
    if response.exit_code == 0 and not response.decision:
        print("  Result: Continue normally (no blocking rules matched)")


def cmd_test(args):
    """Test rules against a sample event file."""
    try:
        with open(args.event_file) as f:
            event_data = json.load(f)
    except Exception as e:
        print(f"Error loading event file: {e}")
        return 1
    
    event = HookEvent(
        hook_type=event_data.get("hook_type", "PreToolUse"),
        tool_name=event_data.get("tool_name", ""),
        tool_input=event_data.get("tool_input", {}),
        session_id=event_data.get("session_id", "test"),
        raw=event_data
    )
    
    print(f"\n{'='*60}")
    print(f" Testing: {args.event_file}")
    print(f"{'='*60}\n")
    
    print("Event:")
    print(f"  Type: {event.hook_type}")
    print(f"  Tool: {event.tool_name}")
    print(f"  Input: {json.dumps(event.tool_input)}\n")
    
    response = dispatch(event)
    
    print("Result:")
    print(f"  Exit Code: {response.exit_code}")
    if response.decision:
        print(f"  Decision: {response.decision}")
    if response.stderr:
        print(f"  Message: {response.stderr}")
    
    return response.exit_code


def cmd_logs(args):
    """View hook logs."""
    log_file = Path("~/.claude/logs/hooks.jsonl").expanduser()
    if args.blocked:
        log_file = Path("~/.claude/logs/blocked.jsonl").expanduser()
    
    if not log_file.exists():
        print(f"No log file found at {log_file}")
        return 1
    
    with open(log_file) as f:
        lines = f.readlines()
    
    if args.tail:
        lines = lines[-20:]
    
    for line in lines:
        try:
            entry = json.loads(line)
            ts = entry.get("timestamp", "")[:19]
            tool = entry.get("tool_name", "?")
            event_type = entry.get("event_type", "?")
            print(f"[{ts}] {event_type:12} {tool}")
        except json.JSONDecodeError:
            continue


def cmd_generate_settings(args):
    """Generate settings.json from current rules configuration."""
    dispatcher_path = Path(__file__).parent / "dispatcher.py"
    if not dispatcher_path.exists():
        dispatcher_path = Path("~/.claude-hooks/dispatcher.py").expanduser()
    
    settings = {
        "hooks": {
            "PreToolUse": [{
                "matcher": "",
                "hooks": [{
                    "type": "command",
                    "command": f"python3 {dispatcher_path}"
                }]
            }],
            "PostToolUse": [{
                "matcher": "",
                "hooks": [{
                    "type": "command",
                    "command": f"python3 {dispatcher_path}"
                }]
            }],
            "Stop": [{
                "matcher": "",
                "hooks": [{
                    "type": "command",
                    "command": f"python3 {dispatcher_path}"
                }]
            }],
            "UserPromptSubmit": [{
                "hooks": [{
                    "type": "command",
                    "command": f"python3 {dispatcher_path}"
                }]
            }]
        }
    }
    
    print(json.dumps(settings, indent=2))


def cmd_init(args):
    """Initialize the hooks engine configuration."""
    base_dir = Path("~/.claude-hooks").expanduser()
    
    if base_dir.exists() and not args.force:
        print(f"Configuration directory already exists: {base_dir}")
        print("Use --force to overwrite")
        return 1
    
    # Create directory structure
    base_dir.mkdir(parents=True, exist_ok=True)
    (base_dir / "scripts" / "conditions").mkdir(parents=True, exist_ok=True)
    (base_dir / "scripts" / "actions").mkdir(parents=True, exist_ok=True)
    
    # Copy example files (in a real implementation, these would be embedded)
    print(f"Created: {base_dir}")
    print(f"Created: {base_dir / 'scripts'}")
    
    print("\nNext steps:")
    print(f"  1. Copy dispatcher.py to {base_dir}/")
    print(f"  2. Copy example YAML files to {base_dir}/")
    print(f"  3. Run: claude-hooks generate-settings > ~/.claude/settings.json")
    print(f"  4. Review with: claude-hooks config validate")


def main():
    parser = argparse.ArgumentParser(
        description="Claude Hooks Engine - Manage declarative hook rules",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Available commands")
    
    # list command
    list_parser = subparsers.add_parser("list", help="List all active rules")
    list_parser.add_argument("--event", help="Filter by event type")
    list_parser.add_argument("--tag", help="Filter by tag")
    
    # config command
    config_parser = subparsers.add_parser("config", help="Configuration management")
    config_sub = config_parser.add_subparsers(dest="config_command")
    config_sub.add_parser("show", help="Show configuration sources")
    config_sub.add_parser("validate", help="Validate configuration")
    
    # explain command
    explain_parser = subparsers.add_parser("explain", help="Explain what rules apply to a scenario")
    explain_parser.add_argument("--event", required=True, help="Event type (e.g., PreToolUse)")
    explain_parser.add_argument("--tool", required=True, help="Tool name (e.g., Bash)")
    explain_parser.add_argument("--input", help="Tool input as JSON")
    
    # test command
    test_parser = subparsers.add_parser("test", help="Test rules against sample event")
    test_parser.add_argument("event_file", help="JSON file with event data")
    
    # logs command
    logs_parser = subparsers.add_parser("logs", help="View hook logs")
    logs_parser.add_argument("--tail", action="store_true", help="Show last 20 entries")
    logs_parser.add_argument("--blocked", action="store_true", help="Show blocked operations")
    
    # generate-settings command
    subparsers.add_parser("generate-settings", help="Generate settings.json")
    
    # init command
    init_parser = subparsers.add_parser("init", help="Initialize configuration")
    init_parser.add_argument("--force", action="store_true", help="Overwrite existing config")
    
    args = parser.parse_args()
    
    if args.command == "list":
        cmd_list(args)
    elif args.command == "config":
        if args.config_command == "show":
            cmd_config_show(args)
        elif args.config_command == "validate":
            return cmd_config_validate(args)
        else:
            config_parser.print_help()
    elif args.command == "explain":
        cmd_explain(args)
    elif args.command == "test":
        return cmd_test(args)
    elif args.command == "logs":
        cmd_logs(args)
    elif args.command == "generate-settings":
        cmd_generate_settings(args)
    elif args.command == "init":
        return cmd_init(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    sys.exit(main() or 0)
