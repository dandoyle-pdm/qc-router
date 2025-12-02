#!/bin/bash
#
# validate-config.sh - Validate Claude Code hooks configuration
#
# This script validates ~/.claude/settings.json for correct hook structure,
# required fields, and execution errors. Provides color-coded output for
# quick identification of issues.
#
# Usage: ~/.claude/hooks/validate-config.sh
#
# Exit codes:
#   0 - All checks passed
#   1 - Validation warnings found
#   2 - Critical errors found

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

# Files to validate
SETTINGS_FILE="$HOME/.claude/settings.json"
HOOKS_LOG="$HOME/.claude/logs/hooks-debug.log"
SESSION_LOG="$HOME/.claude/logs/session-test.log"

# Print functions
print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASS_COUNT++))
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAIL_COUNT++))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══ $1 ═══${NC}"
}

# Check if file exists
check_file_exists() {
    local file=$1
    local description=$2

    if [[ -f "$file" ]]; then
        print_pass "$description exists: $file"
        return 0
    else
        print_fail "$description not found: $file"
        return 1
    fi
}

# Validate JSON syntax
validate_json_syntax() {
    local file=$1

    if jq empty "$file" 2>/dev/null; then
        print_pass "JSON syntax valid"
        return 0
    else
        print_fail "JSON syntax invalid"
        jq empty "$file" 2>&1 | sed 's/^/  /'
        return 1
    fi
}

# Check for specific JSON field
check_json_field() {
    local file=$1
    local field=$2
    local description=$3

    if jq -e "$field" "$file" >/dev/null 2>&1; then
        local value=$(jq -r "$field" "$file")
        print_pass "$description: $value"
        return 0
    else
        print_warn "$description not found"
        return 1
    fi
}

# Validate hook structure
validate_hook_structure() {
    local hook_type=$1
    local hook_path=".hooks.${hook_type}"

    # Check if hook type exists
    if ! jq -e "$hook_path" "$SETTINGS_FILE" >/dev/null 2>&1; then
        print_info "Hook type '$hook_type' not configured (optional)"
        return 0
    fi

    print_info "Validating $hook_type hook structure..."

    # Check if it's an array
    if ! jq -e "$hook_path | type == \"array\"" "$SETTINGS_FILE" | grep -q true; then
        print_fail "$hook_type must be an array"
        return 1
    fi

    # Get number of hook configurations
    local hook_count=$(jq -r "$hook_path | length" "$SETTINGS_FILE")
    print_info "Found $hook_count hook configuration(s) for $hook_type"

    # Validate each hook configuration
    local i=0
    while [[ $i -lt $hook_count ]]; do
        local hook_config_path="${hook_path}[$i]"

        # Check for nested hooks array
        if jq -e "${hook_config_path}.hooks" "$SETTINGS_FILE" >/dev/null 2>&1; then
            local nested_count=$(jq -r "${hook_config_path}.hooks | length" "$SETTINGS_FILE")
            print_pass "Hook config $i has nested hooks array ($nested_count hook(s))"

            # Validate each nested hook
            local j=0
            while [[ $j -lt $nested_count ]]; do
                local nested_path="${hook_config_path}.hooks[$j]"

                # Check required fields
                if jq -e "${nested_path}.type" "$SETTINGS_FILE" >/dev/null 2>&1; then
                    local type_value=$(jq -r "${nested_path}.type" "$SETTINGS_FILE")
                    print_pass "  Hook $i.$j: type = '$type_value'"
                else
                    print_fail "  Hook $i.$j: missing 'type' field"
                fi

                if jq -e "${nested_path}.command" "$SETTINGS_FILE" >/dev/null 2>&1; then
                    local cmd_value=$(jq -r "${nested_path}.command" "$SETTINGS_FILE")
                    local cmd_preview=$(echo "$cmd_value" | head -c 50)
                    print_pass "  Hook $i.$j: command = '$cmd_preview...'"
                else
                    print_fail "  Hook $i.$j: missing 'command' field"
                fi

                if jq -e "${nested_path}.timeout" "$SETTINGS_FILE" >/dev/null 2>&1; then
                    local timeout_value=$(jq -r "${nested_path}.timeout" "$SETTINGS_FILE")
                    if [[ $timeout_value =~ ^[0-9]+$ ]]; then
                        print_pass "  Hook $i.$j: timeout = ${timeout_value}s"
                    else
                        print_warn "  Hook $i.$j: timeout value not numeric: $timeout_value"
                    fi
                else
                    print_warn "  Hook $i.$j: no timeout specified (may use default)"
                fi

                ((j++))
            done
        else
            print_warn "Hook config $i missing nested 'hooks' array"
        fi

        # Check for matcher (required for PreToolUse/PostToolUse)
        if [[ "$hook_type" == "PreToolUse" || "$hook_type" == "PostToolUse" ]]; then
            if jq -e "${hook_config_path}.matcher" "$SETTINGS_FILE" >/dev/null 2>&1; then
                local matcher_value=$(jq -r "${hook_config_path}.matcher" "$SETTINGS_FILE")
                print_pass "Hook config $i has matcher: '$matcher_value'"
            else
                print_fail "Hook config $i missing 'matcher' (required for $hook_type)"
            fi
        fi

        ((i++))
    done

    return 0
}

# Check hooks debug log for errors
check_hooks_log() {
    if [[ ! -f "$HOOKS_LOG" ]]; then
        print_warn "Hooks debug log not found (no hooks executed yet?)"
        return 0
    fi

    # Get current session ID from most recent log entry
    local session_id=$(grep -oP 'session: \K[a-f0-9-]+' "$HOOKS_LOG" | tail -1)

    if [[ -z "$session_id" ]]; then
        print_warn "No session ID found in hooks log"
        return 0
    fi

    print_info "Current session: $session_id"

    # Count hook executions for current session
    local exec_count=$(grep -c "session: $session_id" "$HOOKS_LOG" || true)
    print_info "Hook executions this session: $exec_count"

    # Check for errors in current session
    local error_count=$(grep "session: $session_id" "$HOOKS_LOG" | grep -ci "error\|fail\|timeout" || true)

    if [[ $error_count -eq 0 ]]; then
        print_pass "No errors found in hooks log for current session"
    else
        print_fail "Found $error_count potential error(s) in hooks log"
        echo "Recent errors:"
        grep "session: $session_id" "$HOOKS_LOG" | grep -i "error\|fail\|timeout" | tail -5 | sed 's/^/  /'
    fi

    return 0
}

# Check SessionStart hook execution
check_session_start_execution() {
    if [[ ! -f "$SESSION_LOG" ]]; then
        print_warn "Session test log not found (SessionStart hook not configured or not executed)"
        return 0
    fi

    # Get most recent session start entry
    local last_entry=$(tail -1 "$SESSION_LOG")

    if [[ -n "$last_entry" ]]; then
        print_pass "SessionStart hook executed: $last_entry"
    else
        print_warn "Session test log exists but is empty"
    fi

    return 0
}

# Main validation sequence
main() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Claude Code Hooks Configuration Validator               ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"

    # Phase 1: File existence
    print_section "File Existence Checks"
    check_file_exists "$SETTINGS_FILE" "Settings file"

    # Phase 2: JSON syntax
    if [[ -f "$SETTINGS_FILE" ]]; then
        print_section "JSON Syntax Validation"
        validate_json_syntax "$SETTINGS_FILE"

        # Phase 3: Basic configuration
        print_section "Basic Configuration"
        check_json_field "$SETTINGS_FILE" ".alwaysThinkingEnabled" "Always thinking enabled"
        check_json_field "$SETTINGS_FILE" ".disableAllHooks" "Hooks disabled"

        # Phase 4: Environment variables
        print_section "Environment Variables"
        check_json_field "$SETTINGS_FILE" ".env.CLAUDE_QC_OVERRIDE" "QC Override"

        # Phase 5: Hook structure validation
        print_section "Hook Structure Validation"

        # Check if hooks object exists
        if jq -e ".hooks" "$SETTINGS_FILE" >/dev/null 2>&1; then
            print_pass "Hooks configuration exists"

            # Validate each hook type
            validate_hook_structure "SessionStart"
            validate_hook_structure "PreToolUse"
            validate_hook_structure "PostToolUse"
        else
            print_info "No hooks configured (optional)"
        fi
    fi

    # Phase 6: Log file analysis
    print_section "Log File Analysis"
    check_hooks_log
    check_session_start_execution

    # Summary
    print_section "Validation Summary"
    echo -e "${GREEN}Passed:  $PASS_COUNT${NC}"
    echo -e "${YELLOW}Warnings: $WARN_COUNT${NC}"
    echo -e "${RED}Failed:   $FAIL_COUNT${NC}"
    echo ""

    # Exit code
    if [[ $FAIL_COUNT -gt 0 ]]; then
        echo -e "${RED}Validation FAILED with critical errors${NC}"
        exit 2
    elif [[ $WARN_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Validation completed with warnings${NC}"
        exit 1
    else
        echo -e "${GREEN}All validation checks PASSED${NC}"
        exit 0
    fi
}

# Run main validation
main "$@"
