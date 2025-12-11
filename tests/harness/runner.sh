#!/usr/bin/env bash
# runner.sh - Main test orchestrator
# Outputs TAP (Test Anything Protocol) format
set -euo pipefail

# =============================================================================
# Constants
# =============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FIXTURES_DIR="${FIXTURES_DIR:-/fixtures}"
export WORKING_DIR="${WORKING_DIR:-/working}"
export RESULTS_DIR="${RESULTS_DIR:-/results}"
export HOOKS_DIR="${HOOKS_DIR:-/hooks}"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_TEST_FAILURE=1
readonly EXIT_SETUP_ERROR=2

# =============================================================================
# Counters (global, updated by sourced test files)
# =============================================================================

# Use declare -g to ensure global scope
declare -g -i TESTS_RUN=0
declare -g -i TESTS_PASSED=0
declare -g -i TESTS_FAILED=0
declare -g -i TESTS_SKIPPED=0

# Export for any subprocesses that might need them
export TESTS_RUN TESTS_PASSED TESTS_FAILED TESTS_SKIPPED

# =============================================================================
# Source dependencies
# =============================================================================

source "$SCRIPT_DIR/lib/assertions.sh"
source "$SCRIPT_DIR/lib/fixtures.sh"
source "$SCRIPT_DIR/lib/hooks.sh"

# =============================================================================
# Configuration
# =============================================================================

TEST_MODE="${TEST_MODE:-all}"
VERBOSE="${VERBOSE:-0}"
USE_LLM="${USE_LLM:-1}"  # Default: E2E tests enabled

# =============================================================================
# Argument parsing
# =============================================================================

while [[ $# -gt 0 ]]; do
    case "$1" in
        --unit) TEST_MODE="unit" ;;
        --integration) TEST_MODE="integration" ;;
        --e2e) TEST_MODE="e2e" ;;
        --all) TEST_MODE="all" ;;
        --no-llm) USE_LLM=0 ;;
        --verbose|-v) VERBOSE=1 ;;
        --help|-h)
            echo "Usage: $0 [--unit|--integration|--e2e|--all] [--no-llm] [--verbose]"
            echo ""
            echo "Test modes:"
            echo "  --unit          Run unit tests only (pattern matching)"
            echo "  --integration   Run integration tests (hook behavior)"
            echo "  --e2e           Run E2E tests (real Claude Code)"
            echo "  --all           Run all tests (default)"
            echo ""
            echo "Options:"
            echo "  --no-llm        Skip E2E tests (no API calls)"
            echo "  --verbose, -v   Show detailed output"
            echo "  --help, -h      Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

export VERBOSE
export USE_LLM

# =============================================================================
# Output helpers
# =============================================================================

log() {
    [[ "$VERBOSE" -eq 1 ]] && echo "# [INFO] $*" >&2 || true
}

error() {
    echo "# [ERROR] $*" >&2
}

# =============================================================================
# Test execution
# =============================================================================

run_test_file() {
    local test_file="$1"
    local test_name
    test_name="$(basename "$test_file" .sh)"

    log "Running test file: $test_file"

    # Setup fresh working directory for this test file
    setup_working_dir

    # Source and run the test file DIRECTLY (not in subshell)
    # This allows counter variables to be updated
    # Use set +e to continue on test failures
    set +e
    source "$test_file"
    local result=$?
    set -e

    # Cleanup working directory
    cleanup_working_dir

    log "Test file completed: $test_name (exit: $result)"
}

run_test_suite() {
    local suite_dir="$1"
    local suite_name
    suite_name="$(basename "$suite_dir")"

    if [[ ! -d "$suite_dir" ]]; then
        log "Suite directory not found: $suite_dir"
        return 0
    fi

    echo "# Test Suite: $suite_name"

    # Find test files, handle empty results gracefully
    local test_files
    test_files=$(find "$suite_dir" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | sort) || true

    if [[ -z "$test_files" ]]; then
        log "No test files in $suite_dir"
        return 0
    fi

    while IFS= read -r test_file; do
        [[ -f "$test_file" ]] || continue
        run_test_file "$test_file"
    done <<< "$test_files"
}

run_nested_test_suite() {
    local suite_dir="$1"

    if [[ ! -d "$suite_dir" ]]; then
        log "Suite directory not found: $suite_dir"
        return 0
    fi

    # Run tests in subdirectories
    for subdir in "$suite_dir"/*/; do
        [[ -d "$subdir" ]] || continue
        run_test_suite "$subdir"
    done

    # Also run any tests directly in the suite dir
    run_test_suite "$suite_dir"
}

# =============================================================================
# Main execution
# =============================================================================

main() {
    echo "TAP version 13"
    echo "# Starting test run: mode=$TEST_MODE, use_llm=$USE_LLM"
    echo "#"

    # Verify hooks exist (for unit/integration tests)
    if [[ ! -d "$HOOKS_DIR" ]] && [[ "$TEST_MODE" != "e2e" ]]; then
        echo "# WARNING: Hooks directory not found at $HOOKS_DIR"
        echo "# Unit/integration tests that invoke hooks will fail"
    else
        log "Hooks directory contents:"
        ls -la "$HOOKS_DIR" 2>/dev/null | while read -r line; do log "  $line"; done || true
    fi

    # Verify Claude Code available (for E2E tests)
    if [[ "$USE_LLM" -eq 1 ]] && [[ "$TEST_MODE" == "e2e" || "$TEST_MODE" == "all" ]]; then
        if ! command -v claude &>/dev/null; then
            echo "# WARNING: Claude Code not found in PATH"
            echo "# E2E tests will fail"
        else
            log "Claude Code version: $(claude --version 2>/dev/null || echo 'unknown')"
        fi
    fi

    case "$TEST_MODE" in
        unit)
            run_test_suite "$SCRIPT_DIR/../unit/bash"
            ;;
        integration)
            run_nested_test_suite "$SCRIPT_DIR/../integration"
            ;;
        e2e)
            if [[ "$USE_LLM" -eq 0 ]]; then
                echo "# SKIPPED: E2E tests disabled (--no-llm)"
            else
                run_test_suite "$SCRIPT_DIR/../e2e"
            fi
            ;;
        all)
            run_test_suite "$SCRIPT_DIR/../unit/bash"
            run_nested_test_suite "$SCRIPT_DIR/../integration"
            if [[ "$USE_LLM" -eq 1 ]]; then
                run_test_suite "$SCRIPT_DIR/../e2e"
            else
                echo "# SKIPPED: E2E tests disabled (--no-llm)"
            fi
            ;;
    esac

    # Summary
    echo ""
    echo "1..$TESTS_RUN"
    echo "# tests $TESTS_RUN"
    echo "# pass  $TESTS_PASSED"
    echo "# fail  $TESTS_FAILED"
    echo "# skip  $TESTS_SKIPPED"

    # Save results if results dir exists and is writable
    if [[ -d "$RESULTS_DIR" ]] && [[ -w "$RESULTS_DIR" ]]; then
        cat > "$RESULTS_DIR/summary.txt" <<EOF
Tests Run:    $TESTS_RUN
Tests Passed: $TESTS_PASSED
Tests Failed: $TESTS_FAILED
Tests Skipped: $TESTS_SKIPPED
EOF
        log "Results saved to $RESULTS_DIR/summary.txt"
    fi

    # Exit code based on test results
    if [[ $TESTS_RUN -eq 0 ]]; then
        echo "# WARNING: No tests were executed"
        exit $EXIT_SETUP_ERROR
    elif [[ $TESTS_FAILED -eq 0 ]]; then
        exit $EXIT_SUCCESS
    else
        exit $EXIT_TEST_FAILURE
    fi
}

main "$@"
