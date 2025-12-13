---
# Metadata
ticket_id: TICKET-policy-enforcement-001
session_id: policy-enforcement
sequence: 001
parent_ticket: null
title: Add hard policy enforcement to creator agents
cycle_type: development
status: open
created: 2025-12-13 10:00
worktree_path: null
---

# Requirements

## What Needs to Be Done
Creator agents (code-developer, tech-writer, plugin-engineer, prompt-engineer) currently treat documentation policies as suggestions rather than hard constraints. This allows violations like:
- AGENT.md files exceeding line limits (current files are 208-412 lines)
- Section length violations (policy: 50-100 lines per section)
- No enforcement mechanism - policies can be "escaped" or ignored

### Phase 1: Investigation
1. Identify authoritative policy sources (DOCUMENTS.md, DEVELOPER.md)
2. Extract all quantitative constraints (line counts, section limits)
3. Audit creator agents for enforcement gaps
4. Count lines/sections in existing AGENT.md files
5. Document all violations

### Phase 2: Implementation
1. Add "POLICY ENFORCEMENT" sections to creator agents
2. Define validation checkpoints (before commit, before completion)
3. Add self-check requirements with explicit constraints
4. Add failure modes (STOP and DECOMPOSE on violations)
5. Create remediation tickets for existing violations

## Acceptance Criteria
- [ ] Policy audit document identifies all quantitative constraints
- [ ] All creator agents have explicit POLICY ENFORCEMENT sections
- [ ] Validation checkpoints defined for pre-commit and pre-completion
- [ ] Self-check requirements list specific line/section limits
- [ ] Failure modes documented (agents must STOP on violations)
- [ ] Violation inventory created for existing AGENT.md files
- [ ] Remediation tickets created for existing violations
- [ ] Updated agents comply with the policies they enforce (no self-violations)

# Context

## Why This Work Matters
Without hard enforcement, policies become suggestions that agents routinely violate. The existing AGENT.md files (208-412 lines) prove this - they violate the very policies they should enforce. This creates:
1. Technical debt as files grow unbounded
2. Inconsistent behavior (some agents follow policies, others don't)
3. Loss of trust in the quality system

Enforcement must be embedded in agent definitions, not just documented elsewhere.

## References
- Policy source: /home/ddoyle/docs/DOCUMENTS.md
- Developer standards: /home/ddoyle/docs/DEVELOPER.md
- Creator agents: /home/ddoyle/.claude/plugins/qc-router/agents/
- Related issue: Reverted handoff changes due to quality bypass

# Creator Section

## Implementation Notes
[To be filled by plugin-engineer]

## Questions/Concerns
[To be filled by plugin-engineer]

## Changes Made
- File changes:
- Commits:

**Status Update**: [pending]

# Critic Section

## Audit Findings

### CRITICAL Issues
- [ ] [To be filled by plugin-reviewer]

### HIGH Issues
- [ ] [To be filled by plugin-reviewer]

### MEDIUM Issues
- [ ] [To be filled by plugin-reviewer]

## Approval Decision
[APPROVED | NEEDS_CHANGES]

## Rationale
[To be filled by plugin-reviewer]

**Status Update**: [pending]

# Expediter Section

## Validation Results
- Policy compliance: [PASS/FAIL]
- Self-consistency: [PASS/FAIL - agents comply with enforced policies]
- Line counts verified: [PASS/FAIL]
- Section limits verified: [PASS/FAIL]

## Quality Gate Decision
[APPROVE | CREATE_REWORK_TICKET | ESCALATE]

## Next Steps
[To be filled by plugin-tester]

**Status Update**: [pending]

# Changelog

## [2025-12-13 10:00] - Coordinator
- Ticket created from kickoff prompt
- Investigation phase to be executed via Explore agents
- Implementation phase to use plugin quality chain
