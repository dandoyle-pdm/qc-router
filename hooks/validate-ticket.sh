#!/usr/bin/env bash
# validate-ticket.sh - Validate ticket is properly activated before work
#
# Usage: validate-ticket.sh <ticket-path>
# Exit codes:
#   0 - Ticket valid, work can proceed
#   1 - Ticket invalid, work should not proceed
#   2 - Ticket file not found or usage error

set -euo pipefail

validate_ticket() {
    local ticket_path="$1"
    local errors=()

    # Parse YAML frontmatter using sed (portable)
    local worktree_path status ticket_id
    worktree_path=$(sed -n 's/^worktree_path:[[:space:]]*//p' "$ticket_path" | head -1 | tr -d ' ')
    status=$(sed -n 's/^status:[[:space:]]*//p' "$ticket_path" | head -1 | tr -d ' ')
    ticket_id=$(sed -n 's/^ticket_id:[[:space:]]*//p' "$ticket_path" | head -1 | tr -d ' ')

    # Check 1: worktree_path is set
    if [[ "$worktree_path" == "null" || -z "$worktree_path" ]]; then
        errors+=("worktree_path is null - ticket not activated")
    fi

    # Check 2: worktree_path exists
    if [[ "$worktree_path" != "null" && -n "$worktree_path" && ! -d "$worktree_path" ]]; then
        errors+=("worktree_path does not exist: $worktree_path")
    fi

    # Check 3: cwd matches worktree_path (exact match or subdirectory)
    if [[ "$worktree_path" != "null" && -n "$worktree_path" ]]; then
        local cwd
        cwd=$(pwd)
        # Require exact match OR subdirectory with trailing slash to prevent prefix collisions
        # e.g., /tmp/test-worktree-other should NOT match /tmp/test-worktree
        if [[ "$cwd" != "$worktree_path" && "$cwd" != "$worktree_path/"* ]]; then
            errors+=("Current directory does not match worktree_path")
            errors+=("  Expected: $worktree_path")
            errors+=("  Actual:   $cwd")
        fi
    fi

    # Check 4: status is in_progress
    if [[ "$status" != "in_progress" ]]; then
        errors+=("Ticket status is '$status', expected 'in_progress'")
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        echo "TICKET VALIDATION FAILED: $ticket_id" >&2
        echo "" >&2
        for error in "${errors[@]}"; do
            echo "  - $error" >&2
        done
        echo "" >&2
        echo "To activate ticket properly:" >&2
        echo "  ./scripts/activate-ticket.sh $ticket_path" >&2
        return 1
    fi

    echo "Ticket validated: $ticket_id"
    return 0
}

main() {
    if [[ $# -lt 1 ]]; then
        echo "Usage: validate-ticket.sh <ticket-path>" >&2
        exit 2
    fi

    local ticket_path="$1"
    if [[ ! -f "$ticket_path" ]]; then
        echo "Ticket file not found: $ticket_path" >&2
        exit 2
    fi

    validate_ticket "$ticket_path"
}

main "$@"
