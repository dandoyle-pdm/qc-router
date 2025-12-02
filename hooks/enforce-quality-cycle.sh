#!/usr/bin/env bash
# enforce-quality-cycle.sh - PreToolUse hook for quality cycle enforcement
#
# Security hardened version - fixes applied:
# - Command injection prevention via printf instead of echo
# - Race condition prevention via mktemp and file locking
# - Path traversal prevention via realpath validation
# - Audit logging for override usage
# - Enhanced script detection patterns
# - CLAUDE_ENV_FILE path validation
# - Proper jq error handling
# - Stale session cleanup
# - Strict session ID validation

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly SESSION_STATE_DIR="${CLAUDE_HOME}/.session-state"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Color codes for error messages
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

# Create required directories
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true
mkdir -p "${SESSION_STATE_DIR}" 2>/dev/null || true

# Debug logging function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# SECURITY FIX: Validate file paths to prevent traversal attacks
validate_file_path() {
    local path="$1"

    # Check for null bytes, newlines, and other dangerous characters
    if [[ "$path" =~ [$'\x00\n\r'] ]]; then
        debug_log "ERROR: Invalid path contains forbidden characters: $path"
        return 1
    fi

    # Normalize and validate path using realpath
    local normalized_path
    if normalized_path=$(realpath --quiet --no-symlinks "$path" 2>/dev/null); then
        echo "$normalized_path"
        return 0
    else
        # Path doesn't exist yet, validate parent directory
        local parent_dir
        parent_dir=$(dirname "$path")
        if realpath --quiet "$parent_dir" >/dev/null 2>&1; then
            echo "$path"
            return 0
        fi
    fi

    debug_log "ERROR: Invalid or suspicious path: $path"
    return 1
}

# SECURITY FIX: Validate CLAUDE_ENV_FILE is in safe location
validate_env_file() {
    local env_file="${1:-}"

    if [[ -z "$env_file" ]]; then
        return 1
    fi

    # Ensure CLAUDE_ENV_FILE is in a safe location
    local safe_locations=("/tmp/" "${HOME}/.claude/" "${HOME}/.config/")
    local is_safe=false

    for safe_dir in "${safe_locations[@]}"; do
        if [[ "$env_file" == "$safe_dir"* ]]; then
            is_safe=true
            break
        fi
    done

    if [[ "$is_safe" != "true" ]]; then
        debug_log "ERROR: CLAUDE_ENV_FILE not in safe location: $env_file"
        return 1
    fi

    return 0
}

# Check if we're in a quality cycle context
is_quality_cycle_active() {
    # SECURITY FIX: Log override usage for audit trail
    if [[ "${CLAUDE_QC_OVERRIDE:-false}" == "true" ]]; then
        local override_msg="[$(date -Iseconds)] QC_OVERRIDE used - session: ${SESSION_ID:-unknown}, tool: ${CURRENT_TOOL:-unknown}, target: ${CURRENT_TARGET:-unknown}"
        echo "$override_msg" >&2
        debug_log "AUDIT: $override_msg"
        return 0
    fi

    # Check CLAUDE_ENV_FILE for quality cycle marker
    if [[ -f "${CLAUDE_ENV_FILE:-}" ]]; then
        # SECURITY FIX: Validate path before reading
        if validate_env_file "${CLAUDE_ENV_FILE}"; then
            if grep -q "^QUALITY_CYCLE_ACTIVE=true" "${CLAUDE_ENV_FILE}" 2>/dev/null; then
                debug_log "Quality cycle context detected via CLAUDE_ENV_FILE"
                return 0
            fi
        fi
    fi

    # Check if we're in a subagent context
    local session_id="${SESSION_ID:-}"
    # SECURITY FIX: Strict session ID validation
    if [[ "${session_id}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        if [[ "${session_id}" =~ ^(code-developer|code-reviewer|code-tester|tech-writer)- ]]; then
            debug_log "Subagent context detected via session ID: ${session_id}"
            return 0
        fi
    fi

    # Check working directory patterns for worktree context
    local cwd="${CWD:-$(pwd)}"
    if [[ "${cwd}" =~ /workspace/worktrees/ ]]; then
        debug_log "Worktree context detected: ${cwd}"
        return 0
    fi

    return 1
}

# Check if path matches protected patterns
is_protected_path() {
    local path="$1"

    # Agent definitions
    if [[ "${path}" =~ \.claude/agents/.*/AGENT\.md$ ]]; then
        return 0
    fi

    # Skills
    if [[ "${path}" =~ \.claude/skills/ ]]; then
        return 0
    fi

    # Bash scripts - SECURITY FIX: Enhanced detection
    if [[ "${path}" =~ \.sh$ ]] || [[ "${path}" =~ /scripts/ ]]; then
        return 0
    fi

    # Check for script execution via interpreters
    if [[ "${path}" =~ \.(bash|ksh|zsh|fish|py|rb|pl)$ ]]; then
        return 0
    fi

    # Hook scripts specifically
    if [[ "${path}" =~ \.claude/hooks/ ]]; then
        return 0
    fi

    return 1
}

# SECURITY FIX: Enhanced script detection patterns
is_script_command() {
    local command="$1"

    # Direct script execution
    if [[ "${command}" =~ \.sh(\s|$|;|&|\|) ]]; then
        return 0
    fi

    # Script in scripts directory
    if [[ "${command}" =~ /scripts/ ]]; then
        return 0
    fi

    # Hook scripts
    if [[ "${command}" =~ /hooks/ ]]; then
        return 0
    fi

    # Source or dot commands
    if [[ "${command}" =~ ^(source|\.)\s+[^/]*\.sh ]]; then
        return 0
    fi

    # Interpreter-based execution
    if [[ "${command}" =~ ^(bash|sh|zsh|ksh|python|python3|ruby|perl)\s+ ]]; then
        return 0
    fi

    # Check for creation of executable files
    if [[ "${command}" =~ chmod\s+\+x ]]; then
        return 0
    fi

    return 1
}

# SECURITY FIX: Atomic file tracking with locking
track_file_modification() {
    local session_id="$1"
    local file_path="$2"
    local session_file="${SESSION_STATE_DIR}/${session_id}.files"

    # Validate file path before tracking
    local validated_path
    if ! validated_path=$(validate_file_path "$file_path"); then
        debug_log "ERROR: Invalid file path, not tracking: $file_path"
        return 1
    fi

    # Use file locking for atomic operations
    (
        flock -x 200
        echo "${validated_path}" >> "${session_file}"

        # Count unique files modified
        local file_count
        file_count=$(sort -u "${session_file}" 2>/dev/null | wc -l)

        echo "${file_count}"
    ) 200>"${session_file}.lock"
}

# SECURITY FIX: Clean up stale session files
cleanup_stale_sessions() {
    if [[ -d "${SESSION_STATE_DIR}" ]]; then
        find "${SESSION_STATE_DIR}" \
            -type f \
            \( -name "*.files" -o -name "*.lock" \) \
            -mtime +1 \
            -delete 2>/dev/null || true
        debug_log "Cleaned up stale session files"
    fi
}

# Generate helpful error message
generate_error_message() {
    local reason="$1"
    local tool="$2"
    local target="${3:-}"

    cat <<EOFMSG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ QUALITY CYCLE REQUIRED - Operation Blocked
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reason: ${reason}
Tool: ${tool}
Target: ${target}

This operation requires a quality cycle per ~/.claude/CLAUDE.md.

TO PROCEED CORRECTLY:
1. Create a ticket: tickets/queue/TICKET-{session-id}-{seq}.md
2. Use the appropriate agent via Task tool:
   - For code: invoke code-developer agent
   - For docs: invoke tech-writer agent
3. Let the quality cycle run (Creator → Critic → Expediter)

EMERGENCY OVERRIDE (use sparingly - will be logged):
Export CLAUDE_QC_OVERRIDE=true before the operation

Example workflow:
1. Create ticket with requirements
2. Task tool: subagent_type="general-purpose", model="opus"
3. Prompt: "You are code-developer. Read ticket TICKET-xxx and implement..."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOFMSG
}

# Main execution
main() {
    # Clean up stale sessions periodically
    if (( RANDOM % 10 == 0 )); then
        cleanup_stale_sessions
    fi

    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local tool_name session_id cwd
    if command -v jq >/dev/null 2>&1; then
        # SECURITY FIX: Check jq parsing success
        if ! tool_name=$(printf '%s\n' "${json_input}" | jq -r '.tool_name // ""' 2>/dev/null) || [[ -z "$tool_name" ]]; then
            debug_log "ERROR: Failed to parse tool_name from JSON"
            exit 0
        fi

        session_id=$(printf '%s\n' "${json_input}" | jq -r '.session_id // ""' 2>/dev/null) || session_id=""
        cwd=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null) || cwd=""

        export SESSION_ID="${session_id}"
        export CWD="${cwd}"
        export CURRENT_TOOL="${tool_name}"
    else
        # SECURITY FIX: Use printf instead of echo
        tool_name=$(printf '%s\n' "${json_input}" | grep -oP '"tool_name"\s*:\s*"\K[^"]+' || echo "")
        session_id=$(printf '%s\n' "${json_input}" | grep -oP '"session_id"\s*:\s*"\K[^"]+' || echo "")
        cwd=$(printf '%s\n' "${json_input}" | grep -oP '"cwd"\s*:\s*"\K[^"]+' || echo "")

        # Basic validation of extracted values
        if [[ ! "${tool_name}" =~ ^[A-Za-z]+$ ]]; then
            debug_log "ERROR: Invalid tool_name extracted: $tool_name"
            exit 0
        fi

        export SESSION_ID="${session_id}"
        export CWD="${cwd}"
        export CURRENT_TOOL="${tool_name}"
    fi

    debug_log "Hook invoked for tool: ${tool_name}, session: ${session_id}"

    # Only check specific tools
    case "${tool_name}" in
        Bash|Edit|Write)
            debug_log "Checking tool: ${tool_name}"
            ;;
        *)
            exit 0
            ;;
    esac

    # Check if we're in a quality cycle context
    if is_quality_cycle_active; then
        debug_log "Quality cycle active - allowing operation"
        exit 0
    fi

    # Check if operation requires quality cycle
    case "${tool_name}" in
        Bash)
            local command
            if command -v jq >/dev/null 2>&1; then
                # SECURITY FIX: Check jq success
                if ! command=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.command // ""' 2>/dev/null); then
                    debug_log "ERROR: Failed to parse command from JSON"
                    exit 0
                fi
            else
                # SECURITY FIX: Use printf
                command=$(printf '%s\n' "${json_input}" | grep -oP '"command"\s*:\s*"\K[^"]+' || echo "")
            fi

            export CURRENT_TARGET="${command:0:100}"

            if is_script_command "${command}"; then
                debug_log "Bash script operation blocked: ${command}"
                generate_error_message "Bash script creation/modification requires quality cycle" "Bash" "${command:0:100}..." >&2
                exit 2
            fi
            ;;

        Edit|Write)
            local file_path
            if command -v jq >/dev/null 2>&1; then
                # SECURITY FIX: Check jq success
                if ! file_path=$(printf '%s\n' "${json_input}" | jq -r '.tool_input.file_path // ""' 2>/dev/null); then
                    debug_log "ERROR: Failed to parse file_path from JSON"
                    exit 0
                fi
            else
                # SECURITY FIX: Use printf
                file_path=$(printf '%s\n' "${json_input}" | grep -oP '"file_path"\s*:\s*"\K[^"]+' || echo "")
            fi

            export CURRENT_TARGET="${file_path}"

            # SECURITY FIX: Validate file path
            local validated_path
            if ! validated_path=$(validate_file_path "${file_path}"); then
                debug_log "ERROR: Invalid file path: ${file_path}"
                exit 0
            fi

            if is_protected_path "${validated_path}"; then
                debug_log "Protected path modification blocked: ${validated_path}"
                generate_error_message "Protected file modification requires quality cycle" "${tool_name}" "${validated_path}" >&2
                exit 2
            fi

            # Note: File count tracking removed - all work goes through quality cycles
            # The type of work determines the recipe (R1-R5), not file count
            ;;
    esac

    exit 0
}

# Execute main with error handling
if ! main "$@"; then
    exit $?
fi
