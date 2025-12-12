---
description: Run autonomous quality cycle for a ticket
---

Run the autonomous quality cycle orchestrator for the specified ticket.

## Usage

```
/qc-router:kickoff <ticket_path>
```

## Arguments

- `ticket_path`: Absolute path to ticket file (e.g., `~/.claude/plugins/qc-router/tickets/active/feature-branch/TICKET-001.md`)

## What It Does

The orchestrator:

1. Reads ticket metadata (`cycle_type`, `status`)
2. Maps `cycle_type` to agent sequence:
   - **R1** (code): code-developer → code-reviewer → code-tester
   - **R2** (docs): tech-writer → tech-editor → tech-publisher
   - **R5** (plugin): plugin-engineer → plugin-reviewer → plugin-tester
3. Runs the current phase based on ticket status:
   - `pending` → Dispatch Creator
   - `critic_review` → Dispatch Critic
   - `expediter_review` → Dispatch Judge
4. Handles Judge routing decisions:
   - **APPROVE**: Cycle complete (status: `approved`)
   - **ROUTE_BACK**: Loop to Creator (status: `pending`)
   - **ESCALATE**: Stop and report (status: `escalated`)

## Workflow

Each phase is autonomous - the orchestrator dispatches the agent and waits for completion. After each agent completes, re-run the command to continue to the next phase.

**Example flow:**

```bash
# Start cycle
/qc-router:kickoff ~/project/tickets/active/feature/TICKET-001.md
# Orchestrator dispatches code-developer
# ... code-developer completes, sets status to 'critic_review' ...

# Continue cycle
/qc-router:kickoff ~/project/tickets/active/feature/TICKET-001.md
# Orchestrator dispatches code-reviewer
# ... code-reviewer completes, sets status to 'expediter_review' ...

# Continue cycle
/qc-router:kickoff ~/project/tickets/active/feature/TICKET-001.md
# Orchestrator dispatches code-tester
# ... code-tester completes, makes routing decision ...

# If ROUTE_BACK:
/qc-router:kickoff ~/project/tickets/active/feature/TICKET-001.md
# Cycle restarts with code-developer addressing findings
```

## Implementation

Run the orchestrator script with the ticket path from arguments:

```bash
TICKET_PATH="$ARGUMENTS"

if [[ -z "$TICKET_PATH" ]]; then
    echo "ERROR: Usage: /qc-router:kickoff <ticket_path>"
    echo ""
    echo "Example:"
    echo "  /qc-router:kickoff ~/project/tickets/active/feature/TICKET-001.md"
    exit 1
fi

# Expand tilde if present
TICKET_PATH="${TICKET_PATH/#\~/$HOME}"

# Run the orchestrator
bash ~/.claude/plugins/qc-router/orchestrator/run-quality-cycle.sh "$TICKET_PATH"
```

## Notes

- The orchestrator outputs agent invocation prompts in a structured format
- The main Claude thread executes these prompts via the Task tool
- Each agent updates the ticket status when complete
- The orchestrator reads the updated status on the next run to determine the next phase
- Maximum 5 iterations before automatic escalation
