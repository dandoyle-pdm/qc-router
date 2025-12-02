# Ticket System

Complete guide to the ticket-based workflow tracking system for quality cycles.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

The ticket system provides structured tracking for Creator → Critic → Expediter quality cycles. Each ticket is a single markdown file that evolves as work progresses through phases, maintaining complete history and enabling asynchronous collaboration.

## Ticket Lifecycle

```
1. Ticket created from TEMPLATE.md with requirements
2. Creator reads ticket, implements, updates Creator Section → status: critic_review
3. Critic reads ticket, audits, updates Critic Section → status: expediter_review
4. Expediter reads ticket, validates, updates Expediter Section → status: approved OR new rework ticket
5. If rework needed: New ticket created, cycle repeats
6. If approved: Integration proceeds
```

## Ticket Structure

### Metadata (Frontmatter)

```yaml
---
ticket_id: TICKET-{session-id}-{sequence}
session_id: {descriptive-session-id}  # e.g., "myapi-auth", "docs-refactor"
sequence: {001, 002, etc}
parent_ticket: {null or TICKET-session-id-###}
title: {Brief description of work}
cycle_type: {development|documentation|architecture|product|design}
status: {open|in_progress|critic_review|expediter_review|approved|blocked}
created: {YYYY-MM-DD HH:MM}
worktree_path: {/path/to/worktree or null}
---
```

**Key Fields**:
- `ticket_id`: Unique identifier following naming convention
- `status`: Tracks current phase (drives routing logic)
- `parent_ticket`: Links rework tickets to original work
- `worktree_path`: Location of code being worked on

### Requirements Section

**Purpose**: Define what needs to be done and acceptance criteria

**Contents**:
- Clear description of work required
- Bullet list of acceptance criteria (checkboxes)
- Success conditions

**Updated by**: Creator (initial), Expediter (if creating rework ticket)

### Context Section

**Purpose**: Provide background and rationale

**Contents**:
- Why this work matters
- Business value or technical motivation
- Related tickets, PRs, issues
- Links to documentation

**Updated by**: Creator (initial), anyone adding context

### Creator Section

**Purpose**: Document implementation approach and results

**Contents**:
- **Implementation Notes**: What was built, decisions made, approach taken
- **Questions/Concerns**: Anything unclear or requiring discussion
- **Changes Made**: File changes and commit SHAs
- **Status Update**: Timestamp and status change to `critic_review`

**Updated by**: code-developer agent

### Critic Section

**Purpose**: Document quality audit findings

**Contents**:
- **Audit Findings**: Issues organized by severity (CRITICAL, HIGH, MEDIUM)
- **Approval Decision**: APPROVED or NEEDS_CHANGES
- **Rationale**: Explanation for decision
- **Status Update**: Timestamp and status change to `expediter_review`

**Updated by**: code-reviewer agent

### Expediter Section

**Purpose**: Document validation results and routing decision

**Contents**:
- **Validation Results**: Test results, build status, linting, coverage, security scans
- **Quality Gate Decision**: APPROVE | CREATE_REWORK_TICKET | ESCALATE
- **Next Steps**: Instructions for what happens next
- **Status Update**: Timestamp and status change (approved or new ticket reference)

**Updated by**: code-tester agent

### Changelog

**Purpose**: Maintain timeline of ticket evolution

**Format**:
```markdown
## [YYYY-MM-DD HH:MM] - {Role}
- Event description
- Decision made
```

**Updated by**: All phases add entries chronologically

## Ticket Naming Convention

**Pattern**: `TICKET-{session-id}-{sequence}.md`

**Examples**:
- `TICKET-myapi-auth-001.md` - First ticket for authentication work
- `TICKET-myapi-auth-002.md` - Rework ticket addressing issues from 001
- `TICKET-docs-refactor-001.md` - First ticket for documentation refactor

**Session ID Guidelines**:
- Use lowercase with hyphens
- Keep under 20 characters
- Descriptive but concise (project-feature format)
- Consistent across related tickets

## Ticket Status Flow

| Status | Meaning | Next Phase |
|--------|---------|------------|
| `open` | Ticket created, not yet started | code-developer reads and begins |
| `in_progress` | Creator actively working | Creator completes → `critic_review` |
| `critic_review` | Ready for review | code-reviewer audits → `expediter_review` |
| `expediter_review` | Review complete, awaiting validation | code-tester validates → `approved` or new ticket |
| `approved` | Quality gate passed, ready for integration | Merge/integration workflow |
| `blocked` | Cannot proceed (awaiting external dependency) | Unblock → resume from current phase |

## Creating Tickets

### Initial Ticket Creation

1. Copy `TEMPLATE.md` to new ticket file following naming convention
2. Fill in metadata (ticket_id, session_id, title, cycle_type, worktree_path)
3. Complete Requirements section with acceptance criteria
4. Add Context section with background and rationale
5. Leave Creator, Critic, Expediter sections empty
6. Set status to `open`
7. Save ticket file

**Template location**: `tickets/TEMPLATE.md`

### Rework Ticket Creation

When code-tester routes back for revisions:

1. Copy TEMPLATE.md to new ticket file (increment sequence number)
2. Set `parent_ticket` to original ticket ID
3. Copy Requirements from parent (update as needed)
4. In Requirements, list specific issues from audit that must be addressed
5. Reference original ticket in Context section
6. Set status to `open`
7. Update parent ticket's Expediter Section with reference to new ticket

## Agent Interactions

### code-developer

**Reads**:
- Requirements section for acceptance criteria
- Context section for background
- Critic section (if rework ticket) for issues to address

**Writes**:
- Creator Section with implementation notes and changes
- Status update to `critic_review`
- Changelog entry

### code-reviewer

**Reads**:
- Requirements section to verify completeness
- Context section for background
- Creator Section to understand implementation

**Writes**:
- Critic Section with audit findings and decision
- Status update to `expediter_review`
- Changelog entry

### code-tester

**Reads**:
- Requirements section for acceptance criteria
- Critic Section to see audit findings
- Creator Section for what was implemented

**Writes**:
- Expediter Section with validation results and decision
- Status update to `approved` (or reference to new rework ticket)
- Changelog entry
- New rework ticket file (if routing back)

## Best Practices

### Ticket Granularity

**Too Large**: "Implement entire authentication system"
- Problem: Multiple quality cycles, unclear acceptance criteria
- Better: Split into tickets for login, registration, password reset, etc.

**Too Small**: "Fix typo in variable name"
- Problem: Overhead of full quality cycle not justified
- Better: Group small fixes into single "code cleanup" ticket

**Just Right**: "Implement JWT token authentication and refresh flow"
- Single cohesive feature
- Clear acceptance criteria
- Can be implemented and reviewed in one cycle

### Writing Acceptance Criteria

**Good**:
- ✓ User can log in with email and password
- ✓ Invalid credentials return 401 with error message
- ✓ Successful login returns JWT token with 1-hour expiry
- ✓ All authentication endpoints have integration tests

**Bad**:
- ✗ Authentication works
- ✗ Code is clean
- ✗ Tests exist

### Maintaining Ticket History

- Never delete sections or changelog entries
- Add clarifications as new Context items
- Use Changelog to document all decisions
- Preserve complete audit trail

### Ticket Organization

**Location**: `tickets/`

**File Management**:
- Keep active tickets in main tickets/ directory
- After approval and merge, tickets become historical record
- Can archive to tickets/archive/ subdirectory if desired
- Never delete tickets (they're your audit trail)

## Troubleshooting

### Status Mismatch

**Symptom**: Agent expects ticket in one status, but it's in another

**Solution**: Check last Changelog entry to see what happened. Manually update status if needed (document in Changelog why).

### Missing Section Data

**Symptom**: Critic Section or Expediter Section is empty when expected

**Solution**: Previous phase didn't complete update. Previous agent should re-run and complete section.

### Parent Ticket Reference Lost

**Symptom**: Rework ticket exists but parent_ticket field is null

**Solution**: Find original ticket by session-id and sequence, update parent_ticket field, document fix in Changelog.

### Worktree Path Invalid

**Symptom**: Agent can't find worktree at path specified in ticket

**Solution**:
1. Check if worktree still exists: `git worktree list`
2. If moved: Update worktree_path in ticket metadata
3. If removed: Recreate worktree or note in ticket that work was abandoned

## Related Documentation

- [Code Quality Workflows](code-quality-workflows.md) - Overview of quality cycle roles
- [Code Workflow Procedures](code-workflow-procedures.md) - Step-by-step procedures for each phase
- [TEMPLATE.md](../tickets/TEMPLATE.md) - Ticket template to copy for new tickets
- Agent definitions in `~/.claude/agents/` - Code-developer, code-reviewer, code-tester

## Examples

See existing tickets in `../tickets/` directory:
- `TICKET-docs-ticket-arch-001.md` - Example of completed ticket with all sections
- `TICKET-docs-ticket-arch-002.md` - Example of rework ticket linked to parent
