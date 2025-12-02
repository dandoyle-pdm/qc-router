#!/usr/bin/env bash
# set-quality-cycle-context.sh - SessionStart hook for quality cycle context detection
#
# Security hardened version - fixes applied:
# - mktemp for atomic temp file creation
# - CLAUDE_ENV_FILE path validation
# - Proper error propagation
# - Session ID validation
# - Command injection prevention

set -euo pipefail

# Absolute paths for reliability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_HOME="${HOME}/.claude"
readonly DEBUG_LOG="${CLAUDE_HOME}/logs/hooks-debug.log"

# Create debug log directory if it doesn't exist
mkdir -p "$(dirname "${DEBUG_LOG}")" 2>/dev/null || true

# Debug logging function
debug_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SessionStart] $*" >> "${DEBUG_LOG}" 2>/dev/null || true
}

# SECURITY FIX: Validate CLAUDE_ENV_FILE path
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

# Function to detect subagent context
detect_subagent_context() {
    local session_id="${1:-}"
    local cwd="${2:-}"

    # SECURITY FIX: Validate session ID format
    if [[ ! "${session_id}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        debug_log "Invalid session ID format: ${session_id}"
        return 1
    fi

    # Check session ID patterns for known agents - more specific patterns
    if [[ "${session_id}" =~ ^(code-developer|code-reviewer|code-tester|tech-writer)-[a-zA-Z0-9_-]+$ ]]; then
        debug_log "Detected subagent via session ID: ${session_id}"
        echo "${BASH_REMATCH[1]}"
        return 0
    fi

    # Check if we're in a worktree (indicates quality cycle work)
    if [[ "${cwd}" =~ /workspace/worktrees/([^/]+)/([^/]+) ]]; then
        debug_log "Detected worktree context: ${cwd}"
        echo "worktree"
        return 0
    fi

    # Check for ticket-based work indicators - stricter pattern
    if [[ "${session_id}" =~ ^TICKET-[a-zA-Z0-9]+-[0-9]+$ ]]; then
        debug_log "Detected ticket-based work: ${session_id}"
        echo "ticket"
        return 0
    fi

    # Check environment for explicit quality cycle indicators
    if [[ "${QUALITY_CYCLE_MODE:-}" == "true" ]]; then
        debug_log "Detected explicit quality cycle mode"
        echo "explicit"
        return 0
    fi

    return 1
}

# Function to set quality cycle context
set_quality_cycle_context() {
    local agent_type="${1:-unknown}"
    local session_id="${2:-}"

    # Ensure CLAUDE_ENV_FILE is set and valid
    if [[ -z "${CLAUDE_ENV_FILE:-}" ]]; then
        debug_log "Warning: CLAUDE_ENV_FILE not set, cannot persist context"
        return 1
    fi

    # SECURITY FIX: Validate CLAUDE_ENV_FILE path
    if ! validate_env_file "${CLAUDE_ENV_FILE}"; then
        debug_log "ERROR: CLAUDE_ENV_FILE path validation failed"
        return 1
    fi

    # Create env file if it doesn't exist
    if [[ ! -f "${CLAUDE_ENV_FILE}" ]]; then
        touch "${CLAUDE_ENV_FILE}"
        debug_log "Created CLAUDE_ENV_FILE: ${CLAUDE_ENV_FILE}"
    fi

    # SECURITY FIX: Use atomic temp file creation with mktemp
    local temp_file
    temp_file=$(mktemp "${CLAUDE_ENV_FILE}.XXXXXX") || {
        debug_log "ERROR: Failed to create temp file"
        return 1
    }

    # Copy existing content if any (excluding old quality cycle markers)
    if [[ -f "${CLAUDE_ENV_FILE}" ]]; then
        grep -v "^QUALITY_CYCLE_" "${CLAUDE_ENV_FILE}" > "${temp_file}" 2>/dev/null || true
    fi

    # Add new quality cycle markers
    {
        echo "# Quality Cycle Context - Set by SessionStart hook"
        echo "QUALITY_CYCLE_ACTIVE=true"
        echo "QUALITY_CYCLE_AGENT=${agent_type}"
        echo "QUALITY_CYCLE_SESSION=${session_id}"
        echo "QUALITY_CYCLE_STARTED=$(date '+%Y-%m-%d %H:%M:%S')"
    } >> "${temp_file}"

    # Atomically replace the env file
    mv "${temp_file}" "${CLAUDE_ENV_FILE}"

    debug_log "Set quality cycle context: agent=${agent_type}, session=${session_id}"
    return 0
}

# Function to detect if we're likely in main thread
is_main_thread() {
    local session_id="${1:-}"
    local cwd="${2:-}"

    # Main thread indicators
    if [[ "${cwd}" == "${HOME}" ]] || [[ "${cwd}" == "${HOME}/docs" ]] || [[ "${cwd}" == "${HOME}/.claude" ]]; then
        # SECURITY FIX: Better validation of non-subagent sessions
        if [[ ! "${session_id}" =~ ^(code-developer|code-reviewer|code-tester|tech-writer)-[a-zA-Z0-9_-]+$ ]]; then
            return 0
        fi
    fi

    return 1
}

# Function to clear stale quality cycle state
clear_stale_context() {
    if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && [[ -f "${CLAUDE_ENV_FILE}" ]]; then
        # SECURITY FIX: Validate env file path
        if ! validate_env_file "${CLAUDE_ENV_FILE}"; then
            return 1
        fi

        # Remove quality cycle markers
        if grep -q "^QUALITY_CYCLE_ACTIVE=" "${CLAUDE_ENV_FILE}" 2>/dev/null; then
            # SECURITY FIX: Use mktemp for atomic operations
            local temp_file
            temp_file=$(mktemp "${CLAUDE_ENV_FILE}.XXXXXX") || {
                debug_log "ERROR: Failed to create temp file for clearing context"
                return 1
            }

            grep -v "^QUALITY_CYCLE_" "${CLAUDE_ENV_FILE}" > "${temp_file}" 2>/dev/null || true
            mv "${temp_file}" "${CLAUDE_ENV_FILE}"
            debug_log "Cleared stale quality cycle context"
        fi
    fi
}

# Main execution
main() {
    # Read JSON input from stdin
    local json_input
    json_input=$(cat)

    # Parse JSON fields
    local session_id cwd
    if command -v jq >/dev/null 2>&1; then
        # SECURITY FIX: Check jq parsing success
        if ! session_id=$(printf '%s\n' "${json_input}" | jq -r '.session_id // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse session_id from JSON"
            exit 0
        fi

        if ! cwd=$(printf '%s\n' "${json_input}" | jq -r '.cwd // ""' 2>/dev/null); then
            debug_log "ERROR: Failed to parse cwd from JSON"
            exit 0
        fi
    else
        # SECURITY FIX: Use printf instead of echo to prevent command injection
        session_id=$(printf '%s\n' "${json_input}" | grep -oP '"session_id"\s*:\s*"\K[^"]+' || echo "")
        cwd=$(printf '%s\n' "${json_input}" | grep -oP '"cwd"\s*:\s*"\K[^"]+' || echo "")
    fi

    debug_log "SessionStart hook invoked: session=${session_id}, cwd=${cwd}"

    # Check if this is main thread (clear any stale context)
    if is_main_thread "${session_id}" "${cwd}"; then
        debug_log "Main thread detected - clearing any stale context"
        clear_stale_context
        exit 0
    fi

    # Try to detect subagent context
    local agent_type
    if agent_type=$(detect_subagent_context "${session_id}" "${cwd}"); then
        debug_log "Subagent context detected: ${agent_type}"

        # Set the quality cycle context
        if set_quality_cycle_context "${agent_type}" "${session_id}"; then
            debug_log "Successfully set quality cycle context"

            # Output success message to stdout (informational)
            cat <<EOFMSG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Quality Cycle Context Activated
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Agent Type: ${agent_type}
Session ID: ${session_id}
Working Directory: ${cwd}

Quality cycle operations are now permitted in this session.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOFMSG
        else
            debug_log "Warning: Failed to set quality cycle context"
            # SECURITY FIX: Return proper error code but don't block
            exit 1
        fi
    else
        debug_log "No subagent context detected - normal session"
    fi

    # Exit successfully to not block session
    exit 0
}

# Execute main with error handling
# SECURITY FIX: Properly propagate errors while not blocking session
main_exit_code=0
if ! main "$@"; then
    main_exit_code=$?
    debug_log "Error in SessionStart hook: $main_exit_code"
fi

# Always exit 0 for SessionStart to not block session, but log the error
exit 0
