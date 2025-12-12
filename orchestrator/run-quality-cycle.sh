#!/usr/bin/env bash
# run-quality-cycle.sh - Autonomous quality cycle orchestrator
#
# Usage:
#   run-quality-cycle.sh --check-status <ticket_path>
#     Returns single-line structured status for autonomous operation
#
#   run-quality-cycle.sh --dispatch <ticket_path>
#     Dispatches the appropriate agent for the current phase
#
#   run-quality-cycle.sh (no args)
#     Shows this help message
#
# Autonomous operation pattern:
#   1. status=$(bash run-quality-cycle.sh --check-status ticket.md)
#   2. If status != approved/escalated:
#        prompt=$(bash run-quality-cycle.sh --dispatch ticket.md)
#        Task tool with prompt
#        goto 1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
mode="${1:-help}"
ticket_path="${2:-}"

# Show help if no arguments or help requested
if [[ "$mode" == "help" || "$mode" == "--help" || "$mode" == "-h" ]]; then
    cat << 'EOF'
Quality Cycle Orchestrator - Autonomous Operation

MODES:

  --check-status <ticket_path>
    Returns structured single-line status for autonomous operation.
    Output format: STATUS=<value>
    Possible values:
      - pending_creator   (ticket needs creator work)
      - pending_critic    (ticket needs critic review)
      - pending_judge     (ticket needs judge review)
      - approved          (ticket approved, cycle complete)
      - escalated         (ticket escalated, coordinator needed)
      - route_back        (ticket routed back to creator)

  --dispatch <ticket_path>
    Dispatches the appropriate agent for the current phase.
    Outputs the agent invocation prompt for use with Task tool.

AUTONOMOUS OPERATION PATTERN:

  1. status=$(bash run-quality-cycle.sh --check-status ticket.md)
  2. If status != approved/escalated:
       prompt=$(bash run-quality-cycle.sh --dispatch ticket.md)
       Task tool with prompt
       goto 1

EXAMPLES:

  # Check ticket status
  bash run-quality-cycle.sh --check-status tickets/active/my-branch/ticket.md

  # Dispatch next agent
  bash run-quality-cycle.sh --dispatch tickets/active/my-branch/ticket.md

EOF
    exit 0
fi

# Validate ticket path provided
if [[ -z "$ticket_path" ]]; then
    echo "ERROR: Usage: run-quality-cycle.sh <mode> <ticket_path>" >&2
    echo "Run with --help for usage information" >&2
    exit 1
fi

# Validate ticket exists
if [[ ! -f "$ticket_path" ]]; then
    echo "ERROR: Ticket file not found: $ticket_path" >&2
    exit 1
fi

# Extract ticket metadata
current_status=$(grep "^status:" "$ticket_path" | cut -d' ' -f2)

if [[ -z "$current_status" ]]; then
    echo "ERROR: Could not extract status from ticket: $ticket_path" >&2
    exit 1
fi

# --check-status mode: return structured status
if [[ "$mode" == "--check-status" ]]; then
    case "$current_status" in
        pending|open)
            echo "STATUS=pending_creator"
            ;;
        critic_review)
            echo "STATUS=pending_critic"
            ;;
        expediter_review)
            echo "STATUS=pending_judge"
            ;;
        approved)
            echo "STATUS=approved"
            ;;
        escalated)
            echo "STATUS=escalated"
            ;;
        needs_changes|route_back)
            echo "STATUS=route_back"
            ;;
        *)
            echo "ERROR: Unknown status: $current_status" >&2
            exit 1
            ;;
    esac
    exit 0
fi

# --dispatch mode: dispatch agent for current phase
if [[ "$mode" == "--dispatch" ]]; then
    # Extract cycle_type for agent lookup
    cycle_type=$(grep "^cycle_type:" "$ticket_path" | cut -d' ' -f2)

    if [[ -z "$cycle_type" ]]; then
        echo "ERROR: Could not extract cycle_type from ticket: $ticket_path" >&2
        exit 1
    fi

    # Determine which agent to dispatch based on status
    get_agent_for_role() {
        local role="$1"
        bash "$SCRIPT_DIR/get-next-agent.sh" "$cycle_type" "$role"
    }

    case "$current_status" in
        pending|open)
            creator_agent=$(get_agent_for_role "creator")
            bash "$SCRIPT_DIR/dispatch-agent.sh" "$creator_agent" "$ticket_path"
            ;;
        critic_review)
            critic_agent=$(get_agent_for_role "critic")
            bash "$SCRIPT_DIR/dispatch-agent.sh" "$critic_agent" "$ticket_path"
            ;;
        expediter_review)
            judge_agent=$(get_agent_for_role "judge")
            bash "$SCRIPT_DIR/dispatch-agent.sh" "$judge_agent" "$ticket_path"
            ;;
        approved)
            echo "ERROR: Ticket is already approved. No dispatch needed." >&2
            exit 1
            ;;
        escalated)
            echo "ERROR: Ticket is escalated. Coordinator intervention required." >&2
            exit 1
            ;;
        needs_changes|route_back)
            # Route back means return to creator
            creator_agent=$(get_agent_for_role "creator")
            bash "$SCRIPT_DIR/dispatch-agent.sh" "$creator_agent" "$ticket_path"
            ;;
        *)
            echo "ERROR: Unknown status: $current_status" >&2
            exit 1
            ;;
    esac
    exit 0
fi

# Unknown mode
echo "ERROR: Unknown mode: $mode" >&2
echo "Valid modes: --check-status, --dispatch" >&2
echo "Run with --help for usage information" >&2
exit 1
