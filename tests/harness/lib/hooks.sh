#!/usr/bin/env bash
# hooks.sh - Hook invocation helpers
set -euo pipefail

# Guard against double-sourcing
[[ -n "${_HOOKS_SH_LOADED:-}" ]] && return 0
readonly _HOOKS_SH_LOADED=1

# =============================================================================
# Constants
# =============================================================================

readonly HOOKS_DIR="${HOOKS_DIR:-/hooks}"

# =============================================================================
# Hook result variables (set by invoke functions)
# =============================================================================

# These are set by invoke_bash_hook and invoke_file_hook
HOOK_STDOUT=""
HOOK_STDERR=""
HOOK_EXIT_CODE=0

# =============================================================================
# Hook invocation
# =============================================================================

# invoke_bash_hook(command)
# Invoke dangerous-command-guard.sh with a command
# Sets: HOOK_STDOUT, HOOK_STDERR, HOOK_EXIT_CODE
invoke_bash_hook() {
    local command="$1"
    local input_json

    input_json=$(jq -n --arg cmd "$command" '{"tool_name": "Bash", "tool_input": {"command": $cmd}}')

    local stdout_file stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    set +e
    echo "$input_json" | "$HOOKS_DIR/dangerous-command-guard.sh" > "$stdout_file" 2> "$stderr_file"
    HOOK_EXIT_CODE=$?
    set -e

    HOOK_STDOUT=$(cat "$stdout_file")
    HOOK_STDERR=$(cat "$stderr_file")

    rm -f "$stdout_file" "$stderr_file"

    return 0  # Always return success; caller checks HOOK_EXIT_CODE
}

# invoke_file_hook(tool_name, file_path)
# Invoke protected-files-guard.py with a file path
# Sets: HOOK_STDOUT, HOOK_STDERR, HOOK_EXIT_CODE
invoke_file_hook() {
    local tool_name="$1"
    local file_path="$2"
    local input_json

    input_json=$(jq -n --arg tool "$tool_name" --arg path "$file_path" \
        '{"tool_name": $tool, "tool_input": {"file_path": $path}}')

    local stdout_file stderr_file
    stdout_file=$(mktemp)
    stderr_file=$(mktemp)

    set +e
    echo "$input_json" | python3 "$HOOKS_DIR/protected-files-guard.py" > "$stdout_file" 2> "$stderr_file"
    HOOK_EXIT_CODE=$?
    set -e

    HOOK_STDOUT=$(cat "$stdout_file")
    HOOK_STDERR=$(cat "$stderr_file")

    rm -f "$stdout_file" "$stderr_file"

    return 0  # Always return success; caller checks HOOK_EXIT_CODE
}

# =============================================================================
# Compound assertions (use after invoking hooks)
# =============================================================================

# assert_hook_blocked(description)
# Assert that last hook invocation blocked (exit 2, stderr message)
assert_hook_blocked() {
    local description="$1"
    local all_passed=true

    assert_exit_code 2 "$HOOK_EXIT_CODE" "$description - exit code is 2" || all_passed=false
    assert_stdout_empty "$HOOK_STDOUT" "$description - stdout is empty" || all_passed=false
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "$description - stderr contains BLOCKED" || all_passed=false

    $all_passed
}

# assert_hook_asks(description)
# Assert that last hook invocation requires confirmation (exit 0, JSON with ask)
assert_hook_asks() {
    local description="$1"
    local all_passed=true

    assert_exit_code 0 "$HOOK_EXIT_CODE" "$description - exit code is 0" || all_passed=false
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "$description - permissionDecision is ask" || all_passed=false

    $all_passed
}

# assert_hook_allowed(description)
# Assert that last hook invocation allowed (exit 0, empty stdout)
assert_hook_allowed() {
    local description="$1"
    local all_passed=true

    assert_exit_code 0 "$HOOK_EXIT_CODE" "$description - exit code is 0" || all_passed=false
    assert_stdout_empty "$HOOK_STDOUT" "$description - stdout is empty" || all_passed=false

    $all_passed
}
