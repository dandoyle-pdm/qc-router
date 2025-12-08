# Claude-Mem Architecture Analysis

**Purpose:** Understand how claude-mem triggers observer behavior to improve our QC Observer implementation.

---

## Executive Summary

Claude-mem uses a **6-layer pipeline** with an **external worker service** and **separate Claude subprocess** for observation extraction. Key insight: hooks DON'T call agents directly - they queue data to a worker service that spawns a separate Claude instance.

---

## The 5 Hooks

| Hook | Trigger | What It Does |
|------|---------|--------------|
| SessionStart | startup, clear, compact | Injects previous observations into context via `additionalContext` |
| UserPromptSubmit | User sends message | Creates session in DB, saves prompt, notifies worker |
| PostToolUse | After EVERY tool (matcher: `*`) | Captures tool I/O, POSTs to worker service |
| Stop | User stops session | Extracts last messages, triggers summary generation |
| SessionEnd | Session ends | Marks session complete, cleanup |

---

## Hook Input Schema

All hooks receive JSON via stdin:

```json
{
  "session_id": "abc123",        // Claude Code assigns this - SINGLE SOURCE OF TRUTH
  "cwd": "/path/to/project",
  "tool_name": "Bash",           // PostToolUse only
  "tool_input": {...},           // PostToolUse only
  "tool_response": {...}         // PostToolUse only - THIS IS THE OUTPUT
}
```

**Critical:** `session_id` is assigned by Claude Code and shared across ALL hooks in a conversation. Never generate your own.

---

## PostToolUse - The Core Capture Mechanism

```typescript
// save-hook.ts pseudocode
async function main() {
  const input = JSON.parse(stdin);

  // Skip low-signal tools
  const SKIP = ['ListMcpResourcesTool', 'SlashCommand', 'Skill', 'TodoWrite', 'AskUserQuestion'];
  if (SKIP.includes(input.tool_name)) return;

  // Get/create session (idempotent)
  const sessionId = db.createSDKSession(input.session_id, project, '');

  // Privacy check - skip if entire prompt was <private>
  if (isAllPrivate(input)) return;

  // Strip memory tags from I/O
  const cleanInput = stripTags(input.tool_input);
  const cleanOutput = stripTags(input.tool_response);

  // POST to worker (async, non-blocking)
  await fetch(`http://localhost:37777/sessions/${sessionId}/observations`, {
    method: 'POST',
    body: JSON.stringify({
      tool_name: input.tool_name,
      tool_input: cleanInput,
      tool_response: cleanOutput,
      prompt_number: promptNumber,
      cwd: input.cwd
    })
  });
}
```

**Key points:**
- Fires for EVERY tool (matcher: `*`)
- Skips noisy tools (TodoWrite, etc.)
- POSTs to worker - doesn't process inline
- Non-blocking - hook returns immediately

---

## Worker Service Architecture

**Port:** 37777 (configurable)

**Endpoints:**
```
POST /sessions/:id/init          - Initialize session
POST /sessions/:id/observations  - Queue observation for processing
POST /sessions/:id/summarize     - Generate session summary
POST /sessions/:id/complete      - Mark session done
GET  /api/search                 - Query observations
```

**Event-Driven Queue (Zero Polling):**
```typescript
// When observation arrives
queueObservation(sessionId, data) {
  session.pendingMessages.push(data);
  emitter.emit('message');  // Wake up the iterator
}

// SDKAgent waits on iterator
async *getMessageIterator(sessionId) {
  while (!aborted) {
    if (queue.length === 0) {
      // WAIT for event - no polling
      await new Promise(resolve => emitter.once('message', resolve));
    }
    yield queue.shift();
  }
}
```

---

## SDKAgent - The Observation Extractor

The worker spawns a SEPARATE Claude subprocess via Agent SDK:

```typescript
// SDKAgent.ts
async startSession(session) {
  // Disable ALL tools - observer only
  const disallowedTools = ['Bash', 'Read', 'Write', 'Edit', ...all tools];

  // Create message generator from queue
  const messageGenerator = this.createMessageGenerator(session);

  // Run Agent SDK query
  const queryResult = query({
    prompt: messageGenerator,
    options: {
      model: 'claude-sonnet',
      disallowedTools,
      abortController: session.abortController
    }
  });

  // Process responses
  for await (const message of queryResult) {
    if (message.type === 'assistant') {
      await this.processSDKResponse(session, message.content);
    }
  }
}
```

**The message generator feeds observations to Claude:**
```typescript
async *createMessageGenerator(session) {
  // First: initialization prompt
  yield buildInitPrompt(session.project, session.userPrompt);

  // Then: each observation from queue
  for await (const msg of getMessageIterator(session.id)) {
    if (msg.type === 'observation') {
      yield buildObservationPrompt({
        tool_name: msg.tool_name,
        tool_input: msg.tool_input,
        tool_output: msg.tool_response
      });
    }
  }
}
```

---

## Observation Extraction Prompts

**Init Prompt directives:**
- "Record what was LEARNED/BUILT/FIXED/DEPLOYED/CONFIGURED"
- "Create observations from what you observe - no investigation needed"
- "Focus on deliverables and capabilities"
- Skip routine operations (empty status, package installs)

**Observation Prompt:**
- Receives: tool_name, tool_input, tool_output, cwd
- Claude analyzes: "What happened? Type? Key insights?"
- Responds with XML observation blocks

---

## XML Response Format

Claude responds with structured observations:

```xml
<observation>
  <type>bugfix</type>
  <title>Fixed infinite loop in pagination</title>
  <subtitle>Removed duplicate condition check</subtitle>
  <facts>
    <fact>The loop was checking the same condition twice</fact>
    <fact>Removed the redundant check</fact>
  </facts>
  <narrative>Fixed a critical bug where pagination would loop...</narrative>
  <concepts>
    <concept>pagination</concept>
    <concept>loops</concept>
  </concepts>
  <files_read>
    <file>/src/pagination.ts</file>
  </files_read>
  <files_modified>
    <file>/src/pagination.ts</file>
  </files_modified>
</observation>
```

**Observation Types:**
- decision, bugfix, feature, refactor, discovery, change (fallback)

---

## Storage

**SQLite Tables:**
- `sdk_sessions` - Session metadata
- `observations` - Extracted observations with all fields
- `session_summaries` - Progress checkpoints
- `user_prompts` - Searchable prompts

**ChromaDB:**
- Vector embeddings for semantic search
- Synced async after SQLite write

---

## Context Injection (SessionStart)

The context-hook injects previous observations:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "[markdown with recent observations]"
  }
}
```

**Progressive Disclosure:**
- Default: ~50 observations in INDEX format (titles only)
- Top 5: FULL format (complete narrative)
- Token economics shown (read cost vs work cost)

---

## Search/Retrieval (mem-search skill)

MCP tool exposed for querying:

```typescript
{
  name: 'search',
  parameters: {
    query: string,           // Semantic search
    format: 'index' | 'full',
    type: 'observations' | 'sessions' | 'prompts',
    obs_type: 'bugfix,feature,...',
    concepts: 'pagination,auth,...',
    limit: 20
  }
}
```

**Invocation:** Auto-triggered when user asks about past work.

---

## Complete Flow

```
1. User executes tool (Bash, Edit, etc.)
   ↓
2. [PostToolUse hook] captures tool_name, input, output
   ↓
3. Hook POSTs to worker: /sessions/{id}/observations
   ↓
4. Worker queues observation, emits 'message' event
   ↓
5. SDKAgent iterator wakes up, yields observation prompt
   ↓
6. Agent SDK sends to Claude subprocess
   ↓
7. Claude analyzes, responds with <observation> XML
   ↓
8. Parser extracts fields, stores to SQLite + ChromaDB
   ↓
9. [Next SessionStart] context-hook queries DB, injects summary
```

---

## Key Patterns for QC Observer

| Claude-Mem Pattern | QC Observer Application |
|--------------------|------------------------|
| PostToolUse captures EVERY tool | Observe every quality transformer action |
| Worker service for async processing | Could use simpler inline processing (no SDK) |
| Separate Claude for extraction | We could use the SAME session's Claude |
| XML response format | Structured observation format |
| Session ID threading | Use Claude Code's session_id |
| `additionalContext` injection | Inject violation summary at SessionStart |
| Privacy tags (`<private>`) | Skip sensitive content |
| Progressive disclosure | Index format for summaries |

---

## What Claude-Mem Does NOT Do

- PreToolUse is NOT used (no blocking)
- No threshold-based triggering
- No agent invocation from hooks
- Hooks don't call Claude - they queue to worker
- Worker spawns SEPARATE Claude instance

---

## Implications for Our Design

1. **Hooks queue data, don't process** - Keep hooks fast
2. **Observation happens EVERY time** - Not threshold-based
3. **Analysis is async** - Could be inline for simpler design
4. **SessionStart injects context** - Use `additionalContext`
5. **No PreToolUse for observation** - Only PostToolUse captures
6. **PreToolUse is for blocking** - We use it for quality gates
