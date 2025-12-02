# Code Workflow Procedures

Detailed step-by-step procedures for executing Creator, Reviewer, and Judge phases in code quality cycles.

**Part of**: [Git Worktree Management](../SKILL.md)

## Purpose

This guide provides complete procedural details for running each phase of the code quality workflow. Use this for implementation guidance after understanding the workflow overview.

**See**: [Code Quality Workflows](code-quality-workflows.md) for overview, role definitions, and when to use quality cycles.

## Creator Phase

**Step 1: Create feature worktree**
```bash
git worktree add /home/ddoyle/workspace/worktrees/<project>/<feature-name> <feature-name>
cd /home/ddoyle/workspace/worktrees/<project>/<feature-name>
```

**Step 2: Implement based on context**

**For Greenfield**:
1. Define patterns and abstractions needed
2. Write tests first (TDD) or alongside implementation
3. Implement clean, well-documented code
4. Document design decisions

**For Maintenance**:
1. Study existing patterns in codebase
2. Identify potential breaking changes
3. Implement following existing patterns
4. Add backwards compatibility or migration paths if needed
5. Update existing tests, add new tests

**Step 3: Commit after every todo completion**
```bash
git add .
git commit -m "Implement [specific todo item]"
git push origin <feature-name>
```

**Step 4: Self-review before handoff**
- Run all tests locally
- Check code against code-review-checklists.md yourself
- Fix obvious issues

**Step 5: Update ticket**

Update the ticket's Creator Section (in `tickets/active/{branch}/TICKET-{id}.md`):
- **Implementation Notes**: Summary of what was implemented, design decisions, trade-offs
- **Questions/Concerns**: Any questions or concerns for Reviewer
- **Changes Made**: List files changed and commit SHAs
- **Status Update**: Change status to `critic_review`
- **Changelog**: Add entry documenting completion

**Step 6: Signal completion**

After updating the ticket:
```bash
git push origin <feature-name>
```

Signal: "Implementation complete. Ticket updated. Ready for code-reviewer."

## Reviewer Phase

**Step 1: Access the code**

**Option A**: Review in same worktree (if Creator is done)
```bash
cd /home/ddoyle/workspace/worktrees/<project>/<feature-name>
git pull origin <feature-name>
```

**Option B**: Create read-only review worktree
```bash
git worktree add --detach /home/ddoyle/workspace/worktrees/<project>/review-<feature-name> <feature-name>
cd /home/ddoyle/workspace/worktrees/<project>/review-<feature-name>
```

**Step 2: Review using checklists**

Use code-review-checklists.md systematically:
- Security vulnerabilities
- Test coverage
- Error handling
- Performance implications
- Pattern consistency
- Backwards compatibility
- Edge cases

**Step 3: Document audit findings**

Update the ticket's Critic Section with structured audit:
- **Audit Findings**: Organize by severity (CRITICAL, HIGH, MEDIUM)
  - For each issue: location, category, analysis, recommendation
- **Approval Decision**: APPROVED or NEEDS_CHANGES
- **Rationale**: Explanation for the decision
- **Status Update**: Change status to `expediter_review`
- **Changelog**: Add entry documenting review completion

**Step 4: Signal completion**

After updating the ticket:
```bash
git push origin <feature-name>
```

Signal: "Code review complete. Ticket updated. Audit ready for code-tester."

## Judge Phase

**Step 1: Access the worktree**
```bash
cd /home/ddoyle/workspace/worktrees/<project>/<feature-name>
git pull origin <feature-name>
```

**Step 2: Run automated validation**

Use code-review-checklists.md Judge section:
```bash
# Run tests
npm test  # or pytest, cargo test, etc.

# Run linting
npm run lint

# Run type checking
npm run typecheck

# Run security scans (if applicable)
npm audit

# Run build
npm run build
```

**Step 3: Review ticket audit**

Read ticket's Critic Section to see code-reviewer's audit and decision

**Step 4: Make routing decision and update ticket**

Update the ticket's Expediter Section with:
- **Validation Results**: Test pass/fail, build status, linting, coverage
- **Quality Gate Decision**: APPROVE | CREATE_REWORK_TICKET | ESCALATE
- **Next Steps**: Instructions for integration or rework
- **Status Update**: Change status to `approved` or reference new rework ticket
- **Changelog**: Add entry documenting validation completion

**If routing back for rework**:
- Create new ticket from TEMPLATE.md with specific issues to address
- Reference new ticket ID in original ticket's Expediter Section

**If approved**:
- Update ticket status to `approved`
- Proceed with integration workflow (see integration-workflows.md)

## Iteration Pattern

When Reviewer or Judge requires changes, Creator addresses feedback and re-submits for review.

**See**: [Iteration Limits and Escalation](code-quality-workflows.md#iteration-limits-and-escalation) for maximum iterations (3 cycles), escalation triggers, and bail-out procedures.

## Related Concepts

- [Code Quality Workflows](code-quality-workflows.md) - Workflow overview, role definitions, triggering criteria
- [Code Review Checklists](code-review-checklists.md) - Detailed checklists used in Reviewer and Judge phases
- [Integration Workflows](integration-workflows.md) - PR and merge procedures after Judge approval
- [Worktree Operations](worktree-operations.md) - Basic worktree commands

## See Also

**Back to**: [Git Worktree Management](../SKILL.md)
