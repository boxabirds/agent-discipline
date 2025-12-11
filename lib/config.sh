#!/usr/bin/env bash
# config.sh - Constants and configuration for Claude Backlog (JSON backing store)
set -euo pipefail

# Guard against double-sourcing
[[ -n "${_CONFIG_SH_LOADED:-}" ]] && return 0
readonly _CONFIG_SH_LOADED=1

# =============================================================================
# Project Root Detection
# =============================================================================

# Find project root by looking for delivery/backlog.json or .claude directory
find_project_root() {
    local dir="${1:-$PWD}"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/delivery/backlog.json" ]] || [[ -d "$dir/.claude" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    echo "$PWD"  # Fallback to current directory
}

PROJECT_ROOT="${PROJECT_ROOT:-$(find_project_root)}"
export PROJECT_ROOT

# =============================================================================
# Backlog File Location
# =============================================================================

readonly BACKLOG_FILE="${PROJECT_ROOT}/delivery/backlog.json"
export BACKLOG_FILE

# =============================================================================
# Status Constants
# =============================================================================

readonly STATUS_PROPOSED="proposed"
readonly STATUS_IN_PROGRESS="in_progress"
readonly STATUS_DONE="done"

# Valid statuses (immutable array)
readonly STATUSES=("$STATUS_PROPOSED" "$STATUS_IN_PROGRESS" "$STATUS_DONE")

# =============================================================================
# Error Codes
# =============================================================================

readonly ERR_STORY_NOT_FOUND=10
readonly ERR_TASK_NOT_FOUND=11
readonly ERR_TASK_ALREADY_CLAIMED=12
readonly ERR_INVALID_STATUS=13
readonly ERR_BACKLOG_NOT_FOUND=14
readonly ERR_INVALID_JSON=15
readonly ERR_JQ_REQUIRED=16

# =============================================================================
# Verbose Mode
# =============================================================================

# parse_verbose_flag(args...)
# Call early in scripts to enable verbose output.
# Usage: parse_verbose_flag "$@"
parse_verbose_flag() {
    for arg in "$@"; do
        if [[ "$arg" == "--verbose" || "$arg" == "-v" ]]; then
            export VERBOSE=1
            return 0
        fi
    done
    return 0
}

# =============================================================================
# Dependency Check
# =============================================================================

require_jq() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed" >&2
        return "$ERR_JQ_REQUIRED"
    fi
}
