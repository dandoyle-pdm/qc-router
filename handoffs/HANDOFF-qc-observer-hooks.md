# Handoff: QC Observer Hooks Implementation

## Context

We've completed use case documentation for a QC Observer system in qc-router. The observer needs 4 hooks implemented in **workflow-guard** (this repo).

**Source ticket:** `~/.claude/plugins/qc-router/tickets/queue/TICKET-qc-observer-003.md`
**Use case doc:** `~/.claude/plugins/qc-router/docs/QC-OBSERVER-USE-CASES.md`

## What QC Observer Is

Optional improvement tooling (NOT integral infrastructure like claude-mem). Can be added/removed. Improves global resources (qc-router, workflow-guard, ~/workspace/docs) by tracking quality patterns across projects.

## 4 Hooks to Implement

| Hook | Trigger | Purpose | Exit Codes |
|------|---------|---------|------------|
| `qc-observe-hook.js` | PreToolUse | Block code edits without quality agent | 0=allow, 2=block |
| `qc-capture-hook.js` | PostToolUse | Capture tool execution, log violations | 0=success |
| `qc-context-hook.js` | SessionStart | Inject violation summary into context | 0=success |
| `qc-summary-hook.js` | SessionEnd | Generate summary, improvement prompts | 0=success |

## Key Architecture Decisions

### Enable/Disable Model
```javascript
// First thing in each hook - short-circuit if disabled
const rules = loadRules(); // ~/.novacloud/observer-rules.json
if (!rules.enabled) process.exit(0);
```

### Session ID Detection (Agent Identity)
```javascript
// Subagents have prefixed session IDs
const sessionId = input.session_id; // e.g., "code-developer-abc123"
const agentMatch = sessionId.match(/^(code-developer|code-reviewer|code-tester|...)-/);
const isInQualityAgent = !!agentMatch;
const agentName = agentMatch ? agentMatch[1] : null;
```

### Storage Location
- Observations: `~/.novacloud/observations/violations.jsonl`
- Rules: `~/.novacloud/observer-rules.json`
- Patterns: `~/.novacloud/observations/patterns.json`

### Violation Types
```javascript
const VIOLATION_TYPES = {
  quality_bypass: 'Code modification without quality agent',
  artifact_standard: 'File exceeds 50 lines or multi-responsibility',
  git_workflow: 'Direct commit to main, skip PR',
  ticket_lifecycle: 'Missing ticket, broken chain',
  agent_behavior: 'Wrong agent for phase, role breach'
};
```

## qc-observe-hook.js (PreToolUse)

**Purpose:** Block unauthorized code modifications

```javascript
// Pseudocode - implement ≤50 lines
async function main() {
  const input = JSON.parse(await readStdin());
  const rules = loadRules();

  // Short-circuit if disabled
  if (!rules.enabled) process.exit(0);

  // Only check Edit/Write tools
  if (!['Edit', 'Write'].includes(input.tool_name)) process.exit(0);

  // Check if in quality agent
  const isInQualityAgent = detectAgent(input.session_id);

  if (!isInQualityAgent && isCodeFile(input.tool_input.file_path)) {
    // Log violation
    logViolation('quality_bypass', input);
    // Block with message
    console.log(JSON.stringify({
      decision: 'block',
      reason: 'Code modifications require quality cycle. Use plugin-engineer or code-developer agent.'
    }));
    process.exit(2);
  }

  process.exit(0);
}
```

## qc-capture-hook.js (PostToolUse)

**Purpose:** Capture what happened, queue for pattern analysis

```javascript
// Fires after every tool - be efficient
async function main() {
  const input = JSON.parse(await readStdin());
  const rules = loadRules();

  if (!rules.enabled) process.exit(0);

  // Only capture significant tools
  const SKIP_TOOLS = ['TodoWrite', 'AskUserQuestion', 'Glob', 'Grep'];
  if (SKIP_TOOLS.includes(input.tool_name)) process.exit(0);

  // Capture observation
  const observation = {
    timestamp: new Date().toISOString(),
    session_id: input.session_id,
    tool_name: input.tool_name,
    agent: detectAgent(input.session_id),
    project: detectProject(input.cwd),
    // Don't store full tool_input - just metadata
  };

  appendToJsonl('~/.novacloud/observations/captures.jsonl', observation);
  process.exit(0);
}
```

## qc-context-hook.js (SessionStart)

**Purpose:** Inject violation summary

```javascript
async function main() {
  const rules = loadRules();
  if (!rules.enabled) process.exit(0);

  const recentViolations = loadRecentViolations(5); // last 5 sessions

  if (recentViolations.length > 0) {
    const summary = `⚠️ ${recentViolations.length} quality violations in last 5 sessions`;
    console.log(JSON.stringify({
      hookSpecificOutput: {
        additionalContext: summary
      }
    }));
  }

  process.exit(0);
}
```

## qc-summary-hook.js (SessionEnd)

**Purpose:** Generate summary, update patterns, create improvement prompts

```javascript
async function main() {
  const input = JSON.parse(await readStdin());
  const rules = loadRules();

  if (!rules.enabled) process.exit(0);

  // Aggregate session observations
  const sessionObs = loadSessionObservations(input.session_id);

  // Update pattern frequency
  updatePatterns(sessionObs);

  // Check if any pattern hit threshold (3x)
  const triggeredPatterns = getTriggeredPatterns(3);

  if (triggeredPatterns.length > 0) {
    // Generate improvement prompt
    const prompt = generateImprovementPrompt(triggeredPatterns);
    saveImprovementPrompt(prompt);
  }

  process.exit(0);
}
```

## Artifact Standard

**All hooks must be ≤50 lines.** Extract shared utilities to a common module if needed:
- `lib/observer-utils.js` - loadRules, detectAgent, detectProject, logViolation, etc.

## hooks.json Registration

Add to workflow-guard's hooks.json:
```json
{
  "PreToolUse": [
    { "command": "node hooks/qc-observe-hook.js", "timeout": 5000 }
  ],
  "PostToolUse": [
    { "command": "node hooks/qc-capture-hook.js", "timeout": 5000 }
  ],
  "SessionStart": [
    { "command": "node hooks/qc-context-hook.js", "timeout": 5000 }
  ],
  "SessionEnd": [
    { "command": "node hooks/qc-summary-hook.js", "timeout": 5000 }
  ]
}
```

## Quality Cycle

This is plugin work in workflow-guard → use plugin-engineer → plugin-reviewer → plugin-tester

## Success Criteria

- [ ] qc-observe-hook blocks code edits without quality agent
- [ ] qc-capture-hook logs tool executions efficiently
- [ ] qc-context-hook injects violation summary at session start
- [ ] qc-summary-hook generates improvement prompts at threshold
- [ ] All hooks ≤50 lines
- [ ] Short-circuit when disabled (no wasted cycles)
