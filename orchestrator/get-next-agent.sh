#!/usr/bin/env bash
# get-next-agent.sh - Maps cycle_type and role to agent name
#
# Usage: get-next-agent.sh <cycle_type> <role>
#   cycle_type: R1, R2, R5, development, documentation, plugin
#   role: creator, critic, judge
#
# Returns: agent name for the specified role in the cycle

set -euo pipefail

cycle_type="${1:-}"
role="${2:-}"

if [[ -z "$cycle_type" || -z "$role" ]]; then
    echo "ERROR: Usage: get-next-agent.sh <cycle_type> <role>" >&2
    exit 1
fi

# Normalize cycle_type aliases
case "$cycle_type" in
    R1|development|code)
        cycle_type="R1"
        ;;
    R2|documentation|docs)
        cycle_type="R2"
        ;;
    R5|plugin)
        cycle_type="R5"
        ;;
    *)
        echo "ERROR: Unknown cycle_type: $cycle_type" >&2
        echo "Valid: R1, R2, R5 (or aliases: development, documentation, plugin)" >&2
        exit 1
        ;;
esac

# Normalize role
case "$role" in
    creator|critic|judge)
        # Valid roles
        ;;
    *)
        echo "ERROR: Unknown role: $role" >&2
        echo "Valid: creator, critic, judge" >&2
        exit 1
        ;;
esac

# Map cycle_type + role to agent name
case "$cycle_type:$role" in
    R1:creator)
        echo "code-developer"
        ;;
    R1:critic)
        echo "code-reviewer"
        ;;
    R1:judge)
        echo "code-tester"
        ;;
    R2:creator)
        echo "tech-writer"
        ;;
    R2:critic)
        echo "tech-editor"
        ;;
    R2:judge)
        echo "tech-publisher"
        ;;
    R5:creator)
        echo "plugin-engineer"
        ;;
    R5:critic)
        echo "plugin-reviewer"
        ;;
    R5:judge)
        echo "plugin-tester"
        ;;
    *)
        echo "ERROR: No agent mapping for $cycle_type:$role" >&2
        exit 1
        ;;
esac
