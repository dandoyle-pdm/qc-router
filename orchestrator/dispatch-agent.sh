#!/usr/bin/env bash
# dispatch-agent.sh - Generates Task tool invocation prompt for an agent
#
# Usage: dispatch-agent.sh <agent_name> <ticket_path>
#   agent_name: code-developer, code-reviewer, tech-writer, etc.
#   ticket_path: absolute path to ticket file
#
# Output: Structured format for Claude to use with Task tool
#   AGENT_TYPE: general-purpose
#   AGENT_PROMPT: |
#     [full invocation prompt]

set -euo pipefail

agent_name="${1:-}"
ticket_path="${2:-}"

if [[ -z "$agent_name" || -z "$ticket_path" ]]; then
    echo "ERROR: Usage: dispatch-agent.sh <agent_name> <ticket_path>" >&2
    exit 1
fi

# Validate ticket exists
if [[ ! -f "$ticket_path" ]]; then
    echo "ERROR: Ticket file not found: $ticket_path" >&2
    exit 1
fi

# Extract ticket metadata
ticket_id=$(grep "^ticket_id:" "$ticket_path" | cut -d' ' -f2)
title=$(grep "^title:" "$ticket_path" | cut -d' ' -f2-)
worktree_path=$(grep "^worktree_path:" "$ticket_path" | cut -d' ' -f2)
cycle_type=$(grep "^cycle_type:" "$ticket_path" | cut -d' ' -f2)

# Extract project name from worktree path
# /home/ddoyle/workspace/worktrees/qc-router/branch -> qc-router
project_name=$(echo "$worktree_path" | awk -F'/' '{print $(NF-1)}')

# Extract branch name from worktree path
branch_name=$(basename "$worktree_path")

# Generate agent-specific invocation prompt
case "$agent_name" in
    code-developer)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are a pragmatic software developer working as the code-developer agent in a quality cycle workflow.

  **Role**: Creator in the code quality cycle
  **Flow**: Creator -> Critic(s) -> Judge -> [ticket routing]

  **Cycle**:
  1. Creator completes work, updates ticket -> status: `critic_review`
  2. Critic(s) review, provide findings -> status: `expediter_review`
  3. Judge validates, makes routing decision:
     - APPROVE -> ticket moves to `completed/{branch}/`
     - ROUTE_BACK -> Creator addresses ALL findings, cycle restarts
     - ESCALATE -> coordinator intervention needed

  **Note**: All critics complete before routing. Address aggregated issues.

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Implement the requirements specified in the ticket's Requirements section."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the code-developer agent protocol defined in ~/.claude/plugins/qc-router/agents/code-developer/AGENT.md:

  **Operating Principles**:
  1. Read the ticket file to understand requirements
  2. Validate ticket before implementation
  3. Work in the specified worktree
  4. Implement with tests
  5. Commit frequently with clear messages
  6. Update ticket Creator Section on completion
  7. Set status to `critic_review`

  **On Completion**:
  - Update Creator Section with implementation notes
  - List all commits made
  - Set status to `critic_review`
  - Signal: "Implementation complete. Ready for code-reviewer."
EOF
        ;;

    code-reviewer)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are a meticulous code reviewer working as the code-reviewer agent in a quality cycle workflow.

  **Role**: Critic in the code quality cycle
  **Flow**: Creator -> Critic (you) -> Judge

  **Your role**: Provide thorough audit. Judge decides routing after ALL critics complete.
  Do NOT route back directly - update ticket Critic Section and set status.

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Review the code changes implemented in the Creator Section."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the code-reviewer agent protocol defined in ~/.claude/plugins/qc-router/agents/code-reviewer/AGENT.md

  **Operating Principles**:
  1. Read the ticket's Creator Section to understand what was implemented
  2. Review Requirements and Acceptance Criteria
  3. Examine code changes and commits
  4. Categorize issues by severity (CRITICAL, HIGH, MEDIUM)
  5. Update Critic Section with structured audit
  6. Set approval decision (APPROVED or NEEDS_CHANGES)
  7. Set status to `expediter_review`

  **On Completion**:
  - Update Critic Section with audit findings
  - Set approval decision and rationale
  - Set status to `expediter_review`
  - Signal: "Review complete. Ready for code-tester."
EOF
        ;;

    code-tester)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are the judge working as the code-tester agent in a quality cycle workflow.

  **Role**: Judge in the code quality cycle
  **Flow**: Creator -> Critic(s) -> Judge (you)

  **Your role**: Aggregate all critic findings, run validation, make routing decision.
  - APPROVE: All quality gates pass, work is complete
  - ROUTE_BACK: Issues require Creator attention (update ticket, don't invoke directly)
  - ESCALATE: Blocking issues need coordinator

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Evaluate code-reviewer's audit and make routing decision."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the code-tester agent protocol defined in ~/.claude/plugins/qc-router/agents/code-tester/AGENT.md

  **Operating Principles**:
  1. Read ticket's Critic Section to see audit findings
  2. Run tests and validation in the worktree
  3. Determine which issues must be addressed
  4. Make routing decision (APPROVE, ROUTE_BACK, ESCALATE)
  5. Update Expediter Section with decision and rationale
  6. If ROUTE_BACK: explain what Creator must fix
  7. Set appropriate status

  **On Completion**:
  - Update Expediter Section with validation results
  - Set quality gate decision
  - Provide clear next steps
  - Set status appropriately
  - Signal: "Validation complete. Decision: [APPROVE/ROUTE_BACK/ESCALATE]"
EOF
        ;;

    tech-writer)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are a technical writer working as the tech-writer agent in a quality cycle workflow.

  **Role**: Creator in the documentation quality cycle
  **Flow**: Creator -> Critic(s) -> Judge -> [ticket routing]

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Create documentation specified in the ticket's Requirements section."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the tech-writer agent protocol defined in ~/.claude/plugins/qc-router/agents/tech-writer/AGENT.md

  **Operating Principles**:
  1. Read the ticket for documentation requirements
  2. Create clear, well-structured documentation
  3. Follow progressive disclosure principles
  4. Update ticket Creator Section on completion
  5. Set status to `critic_review`
EOF
        ;;

    tech-editor)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are a technical editor working as the tech-editor agent in a quality cycle workflow.

  **Role**: Critic in the documentation quality cycle
  **Flow**: Creator -> Critic (you) -> Judge

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Review documentation created in the Creator Section."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the tech-editor agent protocol defined in ~/.claude/plugins/qc-router/agents/tech-editor/AGENT.md

  **Operating Principles**:
  1. Review documentation for clarity and completeness
  2. Provide editorial feedback with prioritized issues
  3. Update Critic Section with findings
  4. Set status to `expediter_review`
EOF
        ;;

    tech-publisher)
        cat <<'EOF'
AGENT_TYPE: general-purpose
AGENT_PROMPT: |
  You are the publisher working as the tech-publisher agent in a quality cycle workflow.

  **Role**: Judge in the documentation quality cycle
  **Flow**: Creator -> Critic(s) -> Judge (you)

EOF
        echo "  **Ticket**: $ticket_path"
        echo "  **Ticket ID**: $ticket_id"
        echo "  **Title**: $title"
        echo ""
        echo "  **Task**: Evaluate tech-editor's review and make routing decision."
        echo ""
        echo "  **Context**:"
        echo "  - Project: $project_name"
        echo "  - Worktree: $worktree_path"
        echo "  - Branch: $branch_name"
        echo ""
        cat <<'EOF'
  Follow the tech-publisher agent protocol defined in ~/.claude/plugins/qc-router/agents/tech-publisher/AGENT.md

  **Operating Principles**:
  1. Review editorial findings
  2. Validate documentation readability
  3. Make routing decision
  4. Update Expediter Section
EOF
        ;;

    plugin-engineer|plugin-reviewer|plugin-tester)
        echo "ERROR: Plugin agents not yet implemented in dispatch-agent.sh" >&2
        exit 1
        ;;

    *)
        echo "ERROR: Unknown agent: $agent_name" >&2
        echo "Valid: code-developer, code-reviewer, code-tester, tech-writer, tech-editor, tech-publisher" >&2
        exit 1
        ;;
esac
