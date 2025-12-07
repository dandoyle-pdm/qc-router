# Quality Transformer Plugin Framework

## Specification Document v0.1

---

## Executive Summary

This document specifies a plugin framework for quality-focused multi-agent workflows within Claude Code. The framework introduces the concept of a "Quality Transformer"—a declarative plugin that defines agents (puppets), their coordination patterns, and quality criteria. A host-provided orchestration harness (the Puppet Master runtime) loads these declarations and executes the workflow, providing context services, lifecycle management, and override capabilities.

The key architectural insight is that the orchestrator itself is not special. It is a runtime that interprets declarations. The intelligence lives in the agents and in the declarations that coordinate them. This separation allows transformers to be portable, composable, and independently testable while the harness handles cross-cutting infrastructure concerns.

---

## Design Philosophy

The framework adheres to these principles:

**Declaration over implementation.** Transformers declare what should happen, not how to make it happen. The harness provides the execution engine. This mirrors how CI pipelines declare steps while the CI system provides the runner.

**Agents are specialists.** Each agent (puppet) has a focused responsibility. Creators produce artifacts. Critics evaluate artifacts along specific dimensions. The Puppet Master coordinates but does not perform specialized work itself.

**Quality is measurable.** Quality criteria are explicit, scored, and aggregated according to declared rules. This makes quality gates objective and auditable rather than subjective judgments buried in agent reasoning.

**The harness is a decorator.** The harness wraps transformer execution, providing context injection, lifecycle management, observability, and failure handling. Transformers receive these services without implementing them.

**Overrides are governed.** The coding agent may need to adjust behavior at runtime (lowering thresholds for hotfixes, forcing serial execution for debugging). The declaration explicitly governs which overrides are permitted.

**Methodology is configurable.** Different workflows benefit from different coordination patterns. The framework supports a spectrum from rigid sequential chains to fully adaptive LLM-driven orchestration, selected per-transformer.

---

## Core Concepts

### Transformer

A transformer is a plugin that defines a quality-focused workflow. It declares the agents it needs, how they coordinate, and what quality criteria apply. A transformer does not bring its own orchestrator—it brings a declaration that the harness interprets.

Transformers are the unit of reuse. A "code quality factory" transformer can be shared across projects. A "documentation review" transformer encapsulates a different workflow. Each is self-contained and version-controlled.

### Puppet Master (Harness)

The Puppet Master is the orchestration runtime provided by the Claude Code host. It loads transformer declarations, instantiates agents, executes the coordination loop, and manages the workflow lifecycle. The harness is the same across all transformers; only the declaration varies.

The harness provides services that transformers consume: context about the current task, access to files and git state, quality score aggregation, ticket lifecycle management, and observability.

### Puppets (Agents)

Puppets are the specialized agents that perform work. They come in two primary categories.

Creators produce artifacts. A code-developer puppet writes code. A tech-writer puppet produces documentation. Creators receive task context and feedback from previous iterations, then produce or modify artifacts.

Critics evaluate artifacts. A security-critic puppet examines code for vulnerabilities. A correctness-critic puppet checks for logic errors. Critics receive the current artifact state and produce structured feedback with severity ratings and dimension scores.

Agents are defined by prompt templates and tool access. They are instantiated by the harness when the transformer runs.

### Quality Dimensions

Quality is not a single number but a multi-dimensional assessment. Each dimension (security, correctness, style, completeness, etc.) has its own score, weight, and threshold. Some dimensions are blocking (the workflow cannot pass if below threshold regardless of overall score). The declaration defines these dimensions; critics produce scores for them; the harness aggregates them.

### Methodology

The methodology defines how agents coordinate. The framework supports several modes along a spectrum from rigid to adaptive. Sequential chains follow a fixed order. Orchestrator-driven workflows follow declared rules about routing. Adaptive workflows allow the harness to reason freely (as an LLM) about what to do next. The transformer declaration selects the appropriate mode.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     CLAUDE CODE HOST                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                 PUPPET MASTER HARNESS                       │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │   Loader    │  │  Executor   │  │  Context Services   │ │ │
│  │  │             │  │             │  │                     │ │ │
│  │  │ - Parse     │  │ - Run loop  │  │ - File access       │ │ │
│  │  │   decl.     │  │ - Routing   │  │ - Git state         │ │ │
│  │  │ - Validate  │  │ - Lifecycle │  │ - Task context      │ │ │
│  │  │ - Resolve   │  │ - Scoring   │  │ - Previous feedback │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  │                                                             │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │ │
│  │  │  Override   │  │   Error     │  │   Observability     │ │ │
│  │  │  Manager    │  │   Handler   │  │                     │ │ │
│  │  │             │  │             │  │ - Invocation logs   │ │ │
│  │  │ - Validate  │  │ - Retry     │  │ - Score history     │ │ │
│  │  │ - Apply     │  │ - Fallback  │  │ - Decision trace    │ │ │
│  │  │ - Deny      │  │ - Escalate  │  │ - Audit trail       │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                              │                                   │
│                              │ loads                             │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              QUALITY TRANSFORMER (Plugin)                   │ │
│  │                                                             │ │
│  │  transformer.yaml                                           │ │
│  │  prompts/                                                   │ │
│  │    code-developer.md                                        │ │
│  │    security-critic.md                                       │ │
│  │    correctness-critic.md                                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

The transformer is a directory containing a declaration file and prompt templates. The harness loads the declaration, validates it, and executes the workflow by instantiating agents from the prompt templates and coordinating their execution according to the declared methodology.

---

## Declaration Schema

The transformer declaration is a YAML file (transformer.yaml) with the following structure.

### Top-Level Fields

```yaml
transformer:
  name: string # Required. Human-readable identifier.
  type: quality # Required. Currently only "quality" is defined.
  version: string # Required. Semantic version of this transformer.
  description: string # Optional. What this transformer does.

resources:
  creators: [Agent] # Required. At least one creator.
  critics: [Agent] # Required. At least one critic.

methodology:
  mode:
    string # Required. One of: sequential-chain,
    #   orchestrator-driven, adaptive
  critic-execution: string # Required. One of: parallel, serial
  iteration: Iteration # Required. Iteration limits and termination.

quality:
  dimensions: { Dimension } # Required. Map of dimension name to config.
  aggregation:
    string # Required. One of: weighted-average,
    #   minimum, maximum
  thresholds: Thresholds # Required. Overall quality thresholds.

overrides:
  allow: [string] # Optional. List of paths that can be overridden.
  deny: [string] # Optional. List of paths that cannot be overridden.
```

### Agent Definition

```yaml
# Agent definition used in resources.creators and resources.critics
id: string # Required. Unique identifier within transformer.
prompt: string # Required. Path to prompt template file.
tools:
  [string] # Optional. Tools this agent can access.
  # Creators typically need: file-edit, terminal, git
  # Critics typically need: file-read only
focus:
  [string] # Optional. For critics, what aspects they examine.
  # Used for documentation and routing hints.
```

### Iteration Configuration

```yaml
iteration:
  max-cycles:
    integer # Required. Maximum creator-critic cycles before
    #   escalation. Recommended: 3-5.
  early-termination:
    boolean # Required. Can workflow end before max cycles
    #   if quality is sufficient?
  termination-condition:
    string # Required if early-termination is true.
    # Expression evaluated against quality state.
    # Example: "quality.overall >= thresholds.pass"
```

### Dimension Configuration

```yaml
# Each entry in quality.dimensions
dimension-name:
  weight:
    float # Required. Weight in aggregation (0.0 to 1.0).
    # All weights should sum to 1.0.
  threshold: float # Required. Minimum acceptable score (0-10 scale).
  blocking:
    boolean # Required. If true, below-threshold fails workflow
    #   regardless of overall score.
  critic:
    string # Optional. Which critic produces this score.
    # If omitted, harness infers from critic focus.
```

### Thresholds Configuration

```yaml
thresholds:
  pass: float # Required. Minimum overall score to pass (0-10).
  excellent:
    float # Optional. Score that triggers early termination
    #   without further iteration.
  escalate:
    float # Optional. Score below which escalation triggers
    #   instead of further iteration.
```

### Example Complete Declaration

```yaml
transformer:
  name: code-quality-factory
  type: quality
  version: 1.0.0
  description: >
    Production code quality workflow with security, correctness,
    and style review. Enforces security as a blocking gate.

resources:
  creators:
    - id: code-developer
      prompt: prompts/code-developer.md
      tools:
        - file-edit
        - terminal
        - git

  critics:
    - id: security-critic
      prompt: prompts/security-critic.md
      tools:
        - file-read
      focus:
        - authentication
        - authorization
        - injection
        - secrets
        - cryptography

    - id: correctness-critic
      prompt: prompts/correctness-critic.md
      tools:
        - file-read
        - terminal # Can run tests
      focus:
        - logic-errors
        - edge-cases
        - error-handling
        - test-coverage

    - id: style-critic
      prompt: prompts/style-critic.md
      tools:
        - file-read
      focus:
        - naming
        - idioms
        - structure
        - documentation

methodology:
  mode: orchestrator-driven
  critic-execution: parallel
  iteration:
    max-cycles: 3
    early-termination: true
    termination-condition: "quality.overall >= thresholds.pass"

quality:
  dimensions:
    security:
      weight: 0.4
      threshold: 8.0
      blocking: true
      critic: security-critic
    correctness:
      weight: 0.4
      threshold: 7.0
      blocking: true
      critic: correctness-critic
    style:
      weight: 0.2
      threshold: 5.0
      blocking: false
      critic: style-critic

  aggregation: weighted-average

  thresholds:
    pass: 7.5
    excellent: 9.0
    escalate: 4.0

overrides:
  allow:
    - thresholds.pass
    - iteration.max-cycles
    - methodology.critic-execution
  deny:
    - quality.dimensions.security.blocking
    - quality.dimensions.security.threshold
```

---

## Methodology Modes

### Sequential Chain

In sequential-chain mode, agents execute in a fixed order determined by declaration order. Each agent completes before the next begins. The harness does not make routing decisions; it simply advances through the sequence.

Flow: creator → critic-1 → critic-2 → ... → creator (with feedback) → repeat

This mode is appropriate when the workflow is predictable and critics' feedback does not need synthesis. It is the simplest to debug and audit.

### Orchestrator-Driven

In orchestrator-driven mode, the harness follows declared rules for routing but makes decisions based on critic output. The harness evaluates quality scores and severity levels, then routes according to the declaration.

The harness implements these routing rules:

1. If any critic reports CRITICAL severity, route back to creator with that feedback immediately (do not wait for other critics if running in parallel).
   Doyle: nope. if running in parallel, then all feedback should be collected else you will be pulling the rug out from under other critics.
2. If overall quality meets termination-condition, complete the workflow.
3. If overall quality is below escalate threshold, escalate to human.
4. Otherwise, synthesize feedback and route back to creator.

This mode provides predictable behavior while allowing response to critic output. It is the recommended default for production workflows.

### Adaptive

In adaptive mode, the harness itself is an LLM that reasons about what to do next. The declaration provides hints (available agents, quality criteria, iteration limits) but the harness decides routing, whether to re-run specific critics, whether to interleave feedback, etc.

The harness receives the full context (task, artifact state, all critic feedback, quality scores, iteration count) and produces a routing decision with reasoning.

This mode is appropriate for complex workflows where the optimal path depends on nuanced judgment. It is harder to predict and audit but can achieve better outcomes for variable tasks.
Doyle: and we can inform the orchestrator how to reason with the agents.

Doyle: i would have each critic report criticals, highs, etc. however, the plugin declaration can say how many of any 1 particular type of issue is allowed in order to be considered appropriate to move forward. for instance, 0 critical, and 0 highm but medium and low will be added to a new ticket in the queue to be worked.

---

## Critic Execution Patterns

### Parallel Execution

All critics receive the current artifact state simultaneously. They execute concurrently (or as concurrently as the host permits). The harness collects all feedback before proceeding.

Advantages: Lower wall-clock time. Full picture of all issues in one batch.

Disadvantages: Critics review the same artifact version, so later critics cannot benefit from improvements triggered by earlier critics' feedback. The harness must synthesize potentially redundant or conflicting feedback.

### Serial Execution

Critics execute one at a time in declaration order. Each critic sees the artifact as it exists after any changes the creator made in response to previous critics.

Advantages: Each critic sees improved artifact. Tight feedback loop. Less synthesis required.

Disadvantages: Higher wall-clock time. Earlier critics' priorities may not match task needs.

### Hybrid Pattern (Future Extension)

A future enhancement could allow the declaration to specify critic groups that run in parallel, with groups running in sequence. For example, security and correctness run in parallel (both high priority), then style runs afterward.

---

## Agent Contracts

### Creator Contract

Creators receive a structured input and produce a structured output.

**Input:**

```yaml
task:
  description: string # What to accomplish
  context: string # Relevant background

artifact:
  current_state: string # Path or content of current artifact
  history: [Change] # Previous changes in this workflow

feedback:
  items: [FeedbackItem] # Synthesized feedback from critics
  iteration: integer # Current iteration number (1-indexed)

environment:
  files: [FilePath] # Relevant files in scope
  git_state: GitState # Current branch, uncommitted changes, etc.
```

**Output:**

```yaml
changes:
  files_modified: [FilePath]
  description: string # What was changed and why

status:
  complete: boolean # Does creator believe work is done?
  blockers: [string] # Any issues preventing completion
  notes: string # Information for the orchestrator
```

### Critic Contract

Critics receive the artifact and produce structured feedback.

**Input:**

```yaml
artifact:
  content: string # The artifact to review
  context: string # Background about the task

focus:
  dimensions: [string] # Which dimensions this critic evaluates

previous:
  feedback: [FeedbackItem] # This critic's feedback from previous cycles
  addressed: [boolean] # Which items were addressed
```

**Output:**

```yaml
feedback:
  items:
    - finding: string # What was found
      severity: string # CRITICAL, HIGH, MEDIUM, LOW, INFO
      dimension: string # Which quality dimension
      location: string # Where in artifact (file:line or section)
      suggestion: string # How to address

scores:
  dimension-name: float # Score for each dimension this critic covers (0-10)
  confidence: float # Critic's confidence in assessment (0-1)

summary: string # Brief overall assessment
```

### Severity Definitions

CRITICAL: Blocks deployment. Security vulnerabilities, data loss risks, fundamental correctness issues. Must be addressed before workflow can pass.

HIGH: Significant issues that should be addressed. Likely bugs, missing error handling, meaningful security concerns below critical threshold.

MEDIUM: Issues worth addressing but not blocking. Code quality concerns, suboptimal patterns, minor edge cases.

LOW: Minor suggestions. Style preferences, documentation improvements, refactoring opportunities.

INFO: Observations without action required. Positive feedback, context for understanding.

---

## Quality Scoring

### Score Scale

All scores use a 0-10 scale where:

- 10: Exceptional, exceeds requirements
- 8-9: Good, meets all requirements with quality
- 6-7: Acceptable, meets requirements with minor issues
- 4-5: Below expectations, significant issues but functional
- 2-3: Poor, major issues affecting functionality
- 0-1: Failing, fundamental problems

### Score Aggregation

The harness computes overall quality by aggregating dimension scores according to the declared aggregation method.

**weighted-average**: Sum of (dimension score × weight) across all dimensions. This is the recommended default.

**minimum**: Overall score equals the lowest dimension score. Use when all dimensions are equally critical.

**maximum**: Overall score equals the highest dimension score. Rarely appropriate; included for completeness.

### Blocking Dimensions

If a dimension is marked as blocking and its score falls below its threshold, the workflow cannot pass regardless of overall score. This allows enforcing hard gates for specific concerns (e.g., security) while allowing flexibility in others (e.g., style).

### Score History

The harness maintains score history across iterations. This enables:

- Detecting improvement or regression between cycles
- Identifying dimensions that are not improving despite feedback
- Providing trend information to adaptive-mode routing decisions

---

## Context Services

The harness provides context services that agents access through a standardized interface.

### File Access

Agents can read files within the task scope. Creators can additionally write files. The harness tracks which files are in scope for the current task and provides sandboxed access.

```yaml
context.files:
  in_scope: [FilePath]     # Files relevant to current task
  read(path): string       # Read file content
  write(path, content)     # Write file (creators only)
  diff(path): string       # Get uncommitted changes
```

### Git State

Agents can query git state for context about the codebase.

```yaml
context.git:
  branch: string # Current branch
  uncommitted: [FilePath] # Files with uncommitted changes
  recent_commits: [Commit] # Recent commit history
  blame(path, line): Commit # Who last modified this line
```

### Task Context

The harness provides context about the current task and workflow state.

```yaml
context.task:
  description: string # Task description
  ticket_id: string # Associated ticket if any
  iteration: integer # Current iteration (1-indexed)
  max_iterations: integer # Declared limit

context.feedback:
  current: [FeedbackItem] # Feedback from this cycle
  history: [[FeedbackItem]] # Feedback from previous cycles

context.quality:
  current: QualityState # Current scores by dimension
  history: [QualityState] # Scores from previous cycles
  thresholds: Thresholds # Effective thresholds (after overrides)
```

### Previous Output Access

Agents can access outputs from previous agents in the current cycle.

```yaml
context.agents:
  outputs: { agent-id: AgentOutput } # Outputs keyed by agent id
```

---

## Override Mechanism

The coding agent may need to adjust transformer behavior at runtime. The override mechanism provides governed flexibility.

### Override Sources

Overrides can come from:

1. Environment variables (TRANSFORMER*OVERRIDE*\*)
2. Task metadata (override field in ticket)
3. Explicit harness API call

### Override Validation

When an override is requested, the harness:

1. Checks if the path is in the allow list → permit if present
2. Checks if the path is in the deny list → reject if present
3. If path is in neither → reject (fail closed)

### Override Application

Permitted overrides are applied to the effective configuration before execution begins. The original declaration is not modified; overrides create an effective configuration for this execution only.

### Override Logging

All override requests (permitted and denied) are logged with:

- Requested path and value
- Source of request
- Outcome (permitted/denied)
- Reason (allow-listed, deny-listed, not-listed)

This supports audit requirements for understanding why a workflow behaved differently than default.

---

## Error Handling

### Agent Errors

If an agent fails to produce valid output (times out, produces malformed response, throws error):

1. Log the failure with full context
2. Retry once with exponential backoff
3. If retry fails, check declaration for fallback behavior
4. If no fallback, escalate to human

### Validation Errors

If critic output fails validation (missing required fields, scores out of range):

1. Log validation failure
2. Attempt to extract partial valid information
3. If sufficient information extracted, continue with warning
4. If insufficient, treat as agent error

### Workflow Errors

If the workflow reaches an unexpected state:

1. Log state snapshot
2. Do not silently continue
3. Escalate with full context

### Escalation

Escalation transfers control to a human. The harness provides:

- Full workflow history (all agent inputs/outputs)
- Quality scores at each iteration
- Reason for escalation
- Suggested actions if determinable

---

## Observability

### Invocation Logging

Every agent invocation is logged with:

- Timestamp
- Agent id
- Input summary (truncated for size)
- Output summary
- Duration
- Token usage if available

### Decision Tracing

Every routing decision is logged with:

- Current state summary
- Decision made
- Reasoning (for adaptive mode)
- Alternatives considered (for adaptive mode)

### Quality Tracking

Quality state is logged after each critic execution:

- Dimension scores
- Overall score
- Delta from previous iteration
- Threshold comparisons

### Audit Trail

The complete execution history is persisted as a structured audit trail:

```yaml
audit:
  transformer: string
  version: string
  started: timestamp
  completed: timestamp
  outcome: string # passed, failed, escalated

  iterations:
    - number: integer
      creator_output: summary
      critics:
        - id: string
          scores: { dimension: score }
          findings: [summary]
      quality: QualityState
      routing_decision: string

  overrides_applied: [{ path, value, source }]

  final_quality: QualityState
```

---

## Prompt Template Format

Prompt templates are Markdown files with YAML frontmatter for metadata.

```markdown
---
id: code-developer
role: creator
version: 1.0.0
---

# Code Developer

You are a skilled software developer working within a quality-controlled workflow.
Your role is to implement solutions that meet requirements and address feedback.

## Your Responsibilities

- Implement code changes according to task requirements
- Write tests that verify your implementation
- Address feedback from reviewers systematically
- Commit changes with clear, descriptive messages

## Feedback Handling

When you receive feedback from critics:

1. Address CRITICAL and HIGH severity items first
2. Explain your approach to each piece of feedback
3. If you disagree with feedback, explain why in your notes
4. Do not ignore feedback without explanation

## Completion Criteria

You should mark your work as complete when:

- All requirements from the task are implemented
- All CRITICAL and HIGH feedback is addressed
- Tests pass
- You have self-reviewed your changes

## Output Format

Provide your response in the following format:

{{output_schema}}
```

The `{{output_schema}}` placeholder is replaced by the harness with the appropriate output structure based on the agent contract.

---

## Implementation Phases

### Phase 1: Core Framework

Build the foundational components:

1. Declaration parser and validator
2. Agent instantiation from prompt templates
3. Sequential-chain execution mode
4. Basic quality scoring (single dimension, no aggregation)
5. Simple context services (file access, task context)

**Deliverable**: A working framework that can execute a simple creator→critic→creator chain with quality threshold checking.

### Phase 2: Full Orchestration

Extend to complete orchestration:

1. Orchestrator-driven mode with routing rules
2. Parallel and serial critic execution
3. Multi-dimension quality with aggregation
4. Iteration limits and early termination
5. Override mechanism

**Deliverable**: A production-ready framework supporting the example declaration in this spec.

### Phase 3: Adaptive Mode

Add LLM-driven orchestration:

1. Adaptive mode implementation
2. Reasoning capture and logging
3. Heuristics for common routing patterns
4. Fallback from adaptive to orchestrator-driven on failure

**Deliverable**: Framework supports all three methodology modes with appropriate observability.

### Phase 4: Ecosystem

Build supporting infrastructure:

1. Transformer packaging and distribution
2. Transformer testing framework
3. Quality dashboard for observability data
4. Library of standard critics (security, correctness, style, etc.)

**Deliverable**: A complete ecosystem for developing, testing, and operating quality transformers.

---

## Appendix A: Terminology

**Transformer**: A plugin defining a quality workflow through declaration.

**Puppet Master**: The orchestration harness that executes transformer declarations.

**Puppet**: An agent (creator or critic) that performs specialized work.

**Factory**: The running instance of a transformer processing a task.

**Dimension**: A specific aspect of quality being measured (security, correctness, etc.).

**Blocking**: A dimension that must meet its threshold for the workflow to pass.

**Cycle**: One complete creator→critics iteration.

**Escalation**: Transfer of control to a human due to failure or limit reached.

---

## Appendix B: Future Considerations

These items are out of scope for initial implementation but should be considered in the architecture:

**Critic chaining**: Allow a critic to invoke another critic for specialized sub-review.

**Dynamic agent pools**: Allow the orchestrator to instantiate additional agents at runtime based on task needs.

**Learning from outcomes**: Track which routing patterns lead to better outcomes over time, informing future routing decisions.

**Cross-transformer composition**: Allow one transformer to invoke another as a sub-workflow.

**Human-in-the-loop at checkpoints**: Allow declaration of points where human review is required before proceeding, not just on escalation.

---

## Appendix C: Design Decisions Log

**Why declarative over programmatic?** Declarations are easier to validate, version, and reason about. They prevent transformers from implementing custom orchestration logic that the harness cannot observe or control.

**Why YAML over JSON?** YAML supports comments and multi-line strings, making declarations more readable. JSON is valid YAML, so JSON declarations work if preferred.

**Why 0-10 scale?** Provides sufficient granularity for meaningful thresholds while remaining human-interpretable. Percentage scales (0-100) invite false precision.

**Why blocking dimensions?** Some quality aspects (security, correctness) may be non-negotiable regardless of how well other aspects score. Blocking dimensions enforce this without complex aggregation rules.

**Why three methodology modes?** Sequential-chain is simplest for debugging. Orchestrator-driven handles most production needs. Adaptive handles complex cases. More modes would add complexity without clear benefit.

---

## Appendix D: Example Prompt Templates

### Security Critic

```markdown
---
id: security-critic
role: critic
version: 1.0.0
dimensions:
  - security
---

# Security Critic

You are a security-focused code reviewer. Your role is to identify security
vulnerabilities and risks in the code under review.

## Your Focus Areas

- Authentication and authorization flaws
- Injection vulnerabilities (SQL, command, XSS)
- Secrets and credential handling
- Cryptographic weaknesses
- Access control issues
- Data validation and sanitization

## Severity Guidelines

CRITICAL: Exploitable vulnerabilities that could lead to:

- Unauthorized access to systems or data
- Remote code execution
- Data breach or exfiltration
- Privilege escalation

HIGH: Security weaknesses that:

- Could become critical with additional context
- Require specific conditions to exploit
- Represent significant defense-in-depth failures

MEDIUM: Security concerns that:

- Deviate from best practices
- Could compound with other issues
- Should be addressed but don't pose immediate risk

LOW: Minor security suggestions:

- Defensive coding improvements
- Logging and monitoring recommendations
- Documentation of security assumptions

## Review Approach

1. Identify the security-sensitive components of the code
2. Trace data flows from untrusted sources
3. Check authentication and authorization at boundaries
4. Look for common vulnerability patterns
5. Consider the threat model for this code

## Output Format

{{output_schema}}
```

### Code Developer

```markdown
---
id: code-developer
role: creator
version: 1.0.0
---

# Code Developer

You are a skilled software developer working within a quality-controlled
workflow. Your role is to implement solutions and respond to reviewer feedback.

## Working Style

- Write clean, readable code that follows project conventions
- Include tests that verify your implementation
- Handle errors explicitly rather than silently
- Commit frequently with clear messages

## Responding to Feedback

When you receive critic feedback:

1. Acknowledge each piece of feedback
2. Address CRITICAL items immediately—these block completion
3. Address HIGH items before marking work complete
4. For MEDIUM and LOW items, address if straightforward or explain why deferred
5. If you disagree with feedback, explain your reasoning

## Self-Review Checklist

Before marking complete, verify:

- [ ] All task requirements implemented
- [ ] Tests written and passing
- [ ] CRITICAL and HIGH feedback addressed
- [ ] Error handling in place
- [ ] Code is readable without extensive comments
- [ ] No obvious security issues
- [ ] Changes are committed

## Output Format

{{output_schema}}
```
