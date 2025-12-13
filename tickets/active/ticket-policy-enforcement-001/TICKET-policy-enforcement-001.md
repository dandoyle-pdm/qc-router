---
# Metadata
ticket_id: TICKET-policy-enforcement-001
session_id: policy-enforcement
sequence: 001
parent_ticket: null
title: Add hard policy enforcement to creator agents
cycle_type: development
status: in_progress
created: 2025-12-13 10:00
worktree_path: /home/ddoyle/workspace/worktrees/qc-router/ticket-policy-enforcement-001
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

# Investigation Findings (Phase 1 Complete)

## Policy Constraints Identified (MUST-level)

| Constraint | Value | Source |
|-----------|-------|--------|
| Root document sections | 50-100 lines max | DOCUMENTS.md:45,58,112 |
| README.md | 150-250 (max 300) lines | DOCUMENTS.md:95,128 |
| DEVELOPER.md | 300-500 (max 600) lines | DOCUMENTS.md:96,170 |
| CLAUDE.md | 400-700 (max 800) lines | DOCUMENTS.md:97,220 |
| Procedural/Conceptual howtos | ≤60 lines | DOCUMENTS.md:640 |
| Extraction summary replacement | 20-50 lines | DOCUMENTS.md:121 |

**Note:** AGENT.md files are not explicitly constrained in DOCUMENTS.md but should follow similar principles to root documents.

## Creator Agent Current State

| Agent | Total Lines | Max Section | Enforcement Level |
|-------|-------------|-------------|-------------------|
| code-developer | 340 | 120 (Loop 1 - VIOLATION) | Required but not blocking |
| tech-writer | 290 | ~55 | Required but not blocking |
| plugin-engineer | 332 | 57 | Suggested only |
| prompt-engineer | 333 | 36 | Advisory checklist only |
| plugin-expert | 327 | 55 | Required but not blocking |

## Cross-Agent Enforcement Gaps

1. **Validation hooks not blocking** - All mention validate-ticket.sh but no mechanism prevents proceeding on failure
2. **Checklists are advisory** - prompt-engineer has explicit checklist but checkboxes have no gate mechanism
3. **Quality standards are post-hoc** - Most policies verified only by reviewers, not pre-implementation
4. **Section violations exist** - code-developer Loop 1 section is 120 lines (2.4x limit)
5. **No prevention mechanisms** - Policies caught in review, not prevented at creation
6. **Assertion without verification** - "Test any code snippets" instructions have no proof requirement

## Required Enforcement Additions

Each creator agent needs:
1. **POLICY ENFORCEMENT section** with explicit constraints
2. **Pre-completion checklist** with hard requirements:
   - [ ] No section exceeds 100 lines
   - [ ] Total document within type limits
   - [ ] All referenced files exist
   - [ ] JSON/YAML validated (where applicable)
3. **Failure mode** - On violation: STOP, DECOMPOSE, create child tickets
4. **Evidence requirement** - Must document validation results

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

## [2025-12-13 10:15] - Coordinator (Investigation Phase)
- Parallel Explore agents completed policy constraint audit
- Identified 6 MUST-level constraints from DOCUMENTS.md
- Audited 5 creator agents: code-developer, tech-writer, plugin-engineer, prompt-engineer, plugin-expert
- Found 6 cross-cutting enforcement gaps
- code-developer Loop 1 section has 120-line violation
- All agents have "suggested" rather than "enforced" policies
- Ready for Phase 2: plugin-engineer implementation
