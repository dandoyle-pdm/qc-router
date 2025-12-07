# Gap Analysis: confirm-code-edits.sh vs. guardrails.md Research

**Date:** 2025-12-03
**Current Implementation:** `/home/ddoyle/.claude/plugins/workflow-guard/hooks/confirm-code-edits.sh`
**Research Reference:** `/home/ddoyle/.claude/plugins/qc-router/research/guardrails.md`

---

## Executive Summary

Our current hook provides **narrow protection** (Edit/Write tools on code files) while the research reveals **comprehensive bypass patterns** via Bash tool and alternative file modification techniques. We have a solid foundation but need significant expansion to achieve defense-in-depth.

**Key Findings:**
- ✅ Current hook handles Edit/Write tools effectively
- ❌ Current hook has **zero coverage** for Bash tool bypass patterns
- ❌ Missing JSON permissionDecision output protocol
- ❌ Missing allowlist-based architecture (currently blocklist-only for extensions)
- ⚠️ Exit code handling differs from research (exit 1 vs exit 2)

---

## 1. Current Implementation Coverage

### What We Catch Successfully

| Pattern | Detection Method | Status |
|---------|------------------|--------|
| Direct Edit tool calls | Tool name matching | ✅ Working |
| Direct Write tool calls | Tool name matching | ✅ Working |
| Code file extensions | Extension-based filter | ✅ Working |
| Test file exclusions | Regex pattern matching | ✅ Working |
| Ticket path exclusions | Path-based filter | ✅ Working |
| Skip flag support | SKIP_EDIT_CONFIRMATION env var | ✅ Working |

### Our Strengths

1. **Security-hardened implementation** - Command injection prevention, proper jq error handling, input validation
2. **Audit logging** - Comprehensive debug logging to ~/.claude/logs/hooks-debug.log
3. **Fallback parsing** - Both jq and sed-based JSON parsing for portability
4. **Clear user messaging** - Well-formatted confirmation prompts
5. **Extensibility** - Configurable via CODE_FILE_EXTENSIONS env var

---

## 2. Critical Gaps: Bash Tool Bypass Patterns

### Dangerous Patterns We Miss Entirely

The research identifies **18 file-modification patterns** via Bash that bypass our Edit/Write checks:

| Pattern | Example | Current Status |
|---------|---------|----------------|
| Output redirection | `echo "code" > file.sh` | ❌ Not detected |
| Append redirection | `cat data >> file.py` | ❌ Not detected |
| `rm` with force flags | `rm -rf src/main.go` | ❌ Not detected |
| `rm` without flags | `rm file.py` | ❌ Not detected |
| `cat` redirection | `cat template > config.js` | ❌ Not detected |
| `tee` writes | `echo "x" \| tee file.sh` | ❌ Not detected |
| In-place `sed` | `sed -i 's/old/new/' file.py` | ❌ Not detected |
| In-place `perl` | `perl -i -pe 's/old/new/' file.go` | ❌ Not detected |
| `mv` operations | `mv old.sh new.sh` | ❌ Not detected |
| `cp` operations | `cp template.js new.js` | ❌ Not detected |
| `chmod` changes | `chmod +x script.sh` | ❌ Not detected |
| `chown` changes | `chown user file.py` | ❌ Not detected |
| `dd` operations | `dd if=/dev/zero of=file bs=1M` | ❌ Not detected |
| `truncate` operations | `truncate -s 0 file.go` | ❌ Not detected |
| `install` command | `install -m 755 script /usr/local/bin/` | ❌ Not detected |
| `patch` operations | `patch < changes.diff` | ❌ Not detected |
| Python one-liners | `python -c "open('f.py','w').write('x')"` | ❌ Not detected |
| Node one-liners | `node -e "fs.writeFileSync('f.js','x')"` | ❌ Not detected |

**Risk Level:** HIGH - An agent can trivially bypass our hook by using Bash instead of Edit/Write.

### Specific Research Patterns to Integrate

From guardrails.md lines 68-88, these are the exact regex patterns we should implement:

```python
DANGEROUS_PATTERNS = [
    r'>\s*[^|]',              # Output redirection (but not pipes)
    r'>>\s*',                 # Append redirection
    r'rm\s+.*-[rf]',          # rm with force/recursive flags
    r'rm\s+[^-]',             # rm without flags
    r'\bcat\b.*>\s*',         # cat > file
    r'\becho\b.*>\s*',        # echo > file
    r'\btee\b',               # tee writes to files
    r'\bsed\b.*-i',           # in-place sed edits
    r'\bperl\b.*-i',          # in-place perl edits
    r'\bmv\b',                # move/rename files
    r'\bcp\b',                # copy files
    r'\bchmod\b',             # change permissions
    r'\bchown\b',             # change ownership
    r'\bdd\b',                # low-level copy
    r'\btruncate\b',          # truncate files
    r'\binstall\b',           # install command writes files
    r'\bpatch\b',             # patch modifies files
    r'python.*-c.*open\(',    # Python one-liner file writes
    r'node.*-e.*fs\.',        # Node one-liner file operations
]
```

---

## 3. Protocol and Architecture Gaps

### Exit Code Handling

| Aspect | Current Implementation | Research Recommendation | Gap |
|--------|----------------------|------------------------|-----|
| Block with message | `exit 1` | `exit 2` | ⚠️ Minor - both work, but exit 2 is preferred |
| Continue normally | `exit 0` | `exit 0` | ✅ Aligned |
| stderr feedback | Used for messages | Feeds back to Claude | ✅ Aligned |

**Impact:** Low - Exit code 1 works but research suggests exit 2 is the correct protocol for blocking with feedback.

### JSON Output Protocol (Missing)

**Current:** We only use exit codes and stderr messages.

**Research (lines 44-50):** Hooks can output JSON to stdout for fine-grained control:

```json
{"permissionDecision": "deny"}   // Block without prompting
{"permissionDecision": "allow"}  // Auto-approve, bypass UI
{"permissionDecision": "ask"}    // Force user confirmation prompt
```

**Gap:** We don't use this protocol. Our confirmations are achieved through blocking (exit 1) and user messages (stderr), which forces the user to retry with SKIP_EDIT_CONFIRMATION=true. The research shows we could use `"permissionDecision": "ask"` to trigger a native confirmation UI.

**Impact:** Medium - We work around this with our own messaging, but we're not leveraging the full hook protocol.

### Allowlist vs. Blocklist Architecture

**Current Approach:**
- Blocklist for tools (only Edit/Write are blocked)
- Blocklist for paths (tickets/ and test files are excluded)
- Blocklist for extensions (only code extensions are blocked)

**Research Recommendation (lines 390-392):**
> "Allowlists beat blocklists. Blocklists fail open (unknown commands pass through); allowlists fail closed (only explicitly permitted operations work)."

**Gap:** Our architecture is fundamentally blocklist-based. The research argues for allowlist architecture with explicit permission rules.

**Impact:** Medium-High - Our current approach is easier to implement but theoretically less secure. However, for the specific use case (code edit confirmation), blocklist may be pragmatic.

---

## 4. Integration with Permission System

**Research Finding (lines 173-224):** Claude Code has a built-in permission system using glob patterns:

```json
{
  "permissions": {
    "deny": [
      "Bash(echo:*>*)",
      "Bash(cat:*>*)",
      "Bash(sed:-i*)",
      "Bash(perl:-i*)",
      "Bash(dd:*)",
      "Bash(truncate:*)"
    ]
  }
}
```

**Current Implementation:** We don't use the permission system at all - only custom hooks.

**Gap:** We could potentially handle Bash patterns via permission rules instead of a hook, which would be simpler and more performant.

**Limitation:** Permission rules use "simple glob matching, not full regex" (line 224), so complex patterns still require hooks.

---

## 5. Defense in Depth Gaps

### Research Recommendation (lines 327-384)

The research proposes a **layered approach**:
1. Permission rules for broad deny patterns
2. Hooks for complex pattern matching
3. OS-level sandboxing for bypass prevention

**Current Implementation:** We only have the hook layer.

**Missing Layers:**
- ❌ No permission rules configured
- ❌ No sandbox configuration
- ❌ No defense against encoded payloads (base64, etc.)
- ❌ No defense against download-and-execute patterns

**Impact:** High - A sophisticated agent could bypass our hook through multiple avenues.

---

## 6. Recommendations

### Option A: Expand Existing Hook to Handle Bash ✅ RECOMMENDED

**Pros:**
- Single unified hook for all file modifications
- Consistent audit logging
- Reuse existing security hardening
- Centralized configuration

**Cons:**
- More complex logic in one hook
- Bash pattern matching requires regex (add to existing sed/jq approach)
- Larger maintenance surface

**Implementation:**
1. Add Bash tool handling to existing hook
2. Integrate DANGEROUS_PATTERNS from research
3. Keep same confirmation workflow
4. Extend audit logging

**Effort:** Medium (2-3 hours to implement and test)

---

### Option B: Create Separate Hook for Bash Patterns

**Pros:**
- Separation of concerns
- Independent testing and debugging
- Can be enabled/disabled separately

**Cons:**
- Duplicate infrastructure (logging, parsing, etc.)
- Two hooks to maintain
- Potential inconsistencies in behavior

**Implementation:**
1. Create new `block-dangerous-bash.sh` hook
2. Implement DANGEROUS_PATTERNS matching
3. Register in hooks.json with Bash matcher
4. Document interaction with existing hook

**Effort:** Medium (2-3 hours to implement and test)

---

### Option C: Use Permission System for Bash Patterns

**Pros:**
- Simplest implementation (declarative JSON)
- Better performance (no hook execution overhead)
- Native to Claude Code

**Cons:**
- Limited to glob patterns, not full regex
- May miss complex bypass patterns
- Less flexibility than custom hooks
- No custom messaging for blocked commands

**Implementation:**
```json
{
  "permissions": {
    "deny": [
      "Bash(*>*)",
      "Bash(*>>*)",
      "Bash(rm:*)",
      "Bash(sed:-i*)",
      "Bash(perl:-i*)",
      "Bash(mv:*)",
      "Bash(cp:*)",
      "Bash(chmod:*)",
      "Bash(chown:*)",
      "Bash(dd:*)",
      "Bash(truncate:*)",
      "Bash(tee:*)",
      "Bash(patch:*)",
      "Bash(python:-c*)",
      "Bash(node:-e*)"
    ]
  }
}
```

**Effort:** Low (30 minutes to configure)

---

### Option D: Defense in Depth (Hybrid Approach) ⭐ BEST PRACTICE

**Approach:**
1. **Permission rules** for simple/common patterns (Option C)
2. **Expanded hook** for complex regex patterns (Option A)
3. **Sandbox configuration** for bypass prevention
4. **JSON permissionDecision** output for native UI

**Pros:**
- Maximum security coverage
- Layered defense against bypass attempts
- Best practice alignment with research
- Graceful degradation if one layer fails

**Cons:**
- Most complex to implement
- Requires testing all layers
- May over-restrict legitimate workflows

**Implementation:**
1. Add permission rules to workflow-guard settings
2. Expand confirm-code-edits.sh to handle Bash
3. Add JSON output protocol support
4. Document sandbox configuration
5. Test bypass scenarios

**Effort:** High (4-6 hours to implement and test thoroughly)

---

## 7. Specific Implementation Todos

### Quick Wins (Do These First)

1. **Change exit code from 1 to 2** (5 minutes)
   - Line 234: `exit 1` → `exit 2`
   - Aligns with research best practices

2. **Add JSON permissionDecision output** (30 minutes)
   - Create `generate_permission_decision()` function
   - Output JSON to stdout before exiting
   - Enables native confirmation UI

3. **Document permission rules alternative** (15 minutes)
   - Add section to README about permission system
   - Provide example deny rules for Bash patterns

### Medium Priority

4. **Extend hook to handle Bash tool** (2-3 hours)
   - Add Bash tool parsing
   - Implement DANGEROUS_PATTERNS matching
   - Add command-specific messaging
   - Test with various bypass attempts

5. **Add allowlist architecture option** (2 hours)
   - Create ALLOWED_OPERATIONS env var
   - Invert logic to fail-closed by default
   - Document migration path

### Long Term

6. **Create defense-in-depth configuration** (4-6 hours)
   - Permission rules for simple patterns
   - Hook for complex patterns
   - Sandbox configuration documentation
   - Bypass testing suite

7. **Add encoded payload detection** (3-4 hours)
   - Detect base64 decoding patterns
   - Detect curl/wget piped to bash
   - Detect heredocs creating executable files

---

## 8. Testing Checklist

Before considering this gap closed, test these bypass scenarios:

### Direct Bypass Attempts
- [ ] `echo "malicious code" > important.sh`
- [ ] `cat /dev/null > config.py`
- [ ] `rm -rf src/`
- [ ] `sed -i 's/old/new/' critical.go`
- [ ] `mv important.js deleted.js`

### Obfuscation Attempts
- [ ] `echo "code" | tee file.py >/dev/null`
- [ ] `python -c "open('hack.py','w').write('code')"`
- [ ] `node -e "require('fs').writeFileSync('hack.js','code')"`
- [ ] Base64-encoded echo to file
- [ ] Heredoc creating executable script

### Legitimate Operations (Should Pass)
- [ ] `ls -la src/`
- [ ] `git status`
- [ ] `npm test`
- [ ] `grep -r "pattern" src/`
- [ ] Edit tool on code files (with confirmation)
- [ ] Edit tool on test files (auto-approved)

---

## 9. Final Recommendation

**Implement Option D (Defense in Depth) in phases:**

**Phase 1 (Immediate - 1 hour):**
- Change exit code to 2
- Add JSON permissionDecision output
- Document permission rules alternative

**Phase 2 (This Sprint - 3 hours):**
- Extend hook to handle Bash tool
- Implement all DANGEROUS_PATTERNS from research
- Comprehensive bypass testing

**Phase 3 (Next Sprint - 2 hours):**
- Configure permission rules as first layer
- Document sandbox configuration
- Create bypass testing suite

**Phase 4 (Future Enhancement):**
- Allowlist architecture option
- Encoded payload detection
- Integration with Claude Code permission system

---

## 10. Open Questions

1. **Should we block ALL Bash modifications or just code files?**
   - Current hook only blocks code file extensions
   - Research blocks all file writes via Bash
   - Recommendation: Match current scope (code files only) for consistency

2. **How do we handle legitimate Bash writes to test files?**
   - Current hook allows test file edits
   - Should we allow `echo "test output" > test.log`?
   - Recommendation: Same exemption rules as Edit/Write tools

3. **Should permission rules be project-specific or global?**
   - Workflow-guard is installed per-project
   - Permission rules can be in project .claude/settings.json
   - Recommendation: Provide both global defaults and project overrides

4. **Do we need to handle NotebookEdit and MultiEdit tools?**
   - Research mentions these tools
   - We don't currently handle them
   - Recommendation: Add them to the same confirmation workflow

---

## Appendix: Research Key Quotes

> "Exit code 2 blocks execution and sends stderr to Claude" (line 109)

> "Allowlists beat blocklists. Blocklists fail open (unknown commands pass through); allowlists fail closed" (lines 390-391)

> "Layer your defenses. Hooks catch specific patterns, permissions provide broad rules, and sandboxing prevents bypass" (lines 393-394)

> "Test bypass attempts. After configuring restrictions, actively try to bypass them." (lines 397-398)

> "Permission rules use simple glob matching, not full regex, so complex patterns still require hooks" (line 224)
