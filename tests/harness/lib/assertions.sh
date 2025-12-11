#!/usr/bin/env bash
# assertions.sh - Test assertion functions
# Follows TAP (Test Anything Protocol) output format
set -euo pipefail

# Guard against double-sourcing
[[ -n "${_ASSERTIONS_SH_LOADED:-}" ]] && return 0
readonly _ASSERTIONS_SH_LOADED=1

# =============================================================================
# Counters (must be declared in sourcing script)
# =============================================================================

# These should be declared in runner.sh before sourcing:
# declare -i TESTS_RUN=0
# declare -i TESTS_PASSED=0
# declare -i TESTS_FAILED=0
# declare -i TESTS_SKIPPED=0

# =============================================================================
# Core assertions
# =============================================================================

# assert_exit_code(expected, actual, description)
assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if [[ "$actual" -eq "$expected" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  expected: $expected"
        echo "  actual: $actual"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_stdout_contains(pattern, actual_stdout, description)
assert_stdout_contains() {
    local pattern="$1"
    local actual="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if echo "$actual" | grep -qE "$pattern"; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  pattern: $pattern"
        echo "  actual: |"
        echo "$actual" | sed 's/^/    /'
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_stdout_empty(actual_stdout, description)
assert_stdout_empty() {
    local actual="$1"
    local description="$2"

    ((TESTS_RUN++)) || true

    if [[ -z "$actual" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  expected: (empty)"
        echo "  actual: |"
        echo "$actual" | sed 's/^/    /'
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_stderr_contains(pattern, actual_stderr, description)
assert_stderr_contains() {
    local pattern="$1"
    local actual="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if echo "$actual" | grep -qE "$pattern"; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  pattern: $pattern"
        echo "  actual_stderr: |"
        echo "$actual" | sed 's/^/    /'
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_json_field(json, field, expected, description)
assert_json_field() {
    local json="$1"
    local field="$2"
    local expected="$3"
    local description="$4"

    local actual
    actual=$(echo "$json" | jq -r "$field" 2>/dev/null || echo "PARSE_ERROR")

    ((TESTS_RUN++)) || true

    if [[ "$actual" == "$expected" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  field: $field"
        echo "  expected: $expected"
        echo "  actual: $actual"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# =============================================================================
# File assertions (for destruction tests)
# =============================================================================

# assert_file_exists(path, description)
assert_file_exists() {
    local path="$1"
    local description="$2"

    ((TESTS_RUN++)) || true

    if [[ -e "$path" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  path: $path"
        echo "  status: does not exist"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_file_not_exists(path, description)
assert_file_not_exists() {
    local path="$1"
    local description="$2"

    ((TESTS_RUN++)) || true

    if [[ ! -e "$path" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  path: $path"
        echo "  status: unexpectedly exists"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_file_contains(path, pattern, description)
assert_file_contains() {
    local path="$1"
    local pattern="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if [[ -f "$path" ]] && grep -qE "$pattern" "$path"; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  path: $path"
        echo "  pattern: $pattern"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_dir_empty(path, description)
assert_dir_empty() {
    local path="$1"
    local description="$2"

    ((TESTS_RUN++)) || true

    if [[ -d "$path" ]] && [[ -z "$(ls -A "$path")" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  path: $path"
        echo "  contents: $(ls -A "$path" 2>/dev/null || echo 'NOT_A_DIR')"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# =============================================================================
# Git assertions
# =============================================================================

# assert_git_commit_count(repo_path, expected_count, description)
assert_git_commit_count() {
    local repo_path="$1"
    local expected="$2"
    local description="$3"

    local actual
    actual=$(git -C "$repo_path" rev-list --count HEAD 2>/dev/null || echo "0")

    ((TESTS_RUN++)) || true

    if [[ "$actual" -eq "$expected" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  expected_commits: $expected"
        echo "  actual_commits: $actual"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_git_branch_exists(repo_path, branch, description)
assert_git_branch_exists() {
    local repo_path="$1"
    local branch="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if git -C "$repo_path" rev-parse --verify "$branch" &>/dev/null; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  branch: $branch"
        echo "  status: does not exist"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_git_clean(repo_path, description)
assert_git_clean() {
    local repo_path="$1"
    local description="$2"

    ((TESTS_RUN++)) || true

    if git -C "$repo_path" diff --quiet 2>/dev/null; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  status: working tree has changes"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# =============================================================================
# Database assertions
# =============================================================================

# assert_table_exists(db_path, table_name, description)
assert_table_exists() {
    local db_path="$1"
    local table_name="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if sqlite3 "$db_path" ".tables" 2>/dev/null | grep -qw "$table_name"; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  table: $table_name"
        echo "  status: does not exist"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_table_not_exists(db_path, table_name, description)
assert_table_not_exists() {
    local db_path="$1"
    local table_name="$2"
    local description="$3"

    ((TESTS_RUN++)) || true

    if ! sqlite3 "$db_path" ".tables" 2>/dev/null | grep -qw "$table_name"; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  table: $table_name"
        echo "  status: unexpectedly exists"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# assert_row_count(db_path, table_name, expected_count, description)
assert_row_count() {
    local db_path="$1"
    local table_name="$2"
    local expected="$3"
    local description="$4"

    local actual
    actual=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM $table_name;" 2>/dev/null || echo "-1")

    ((TESTS_RUN++)) || true

    if [[ "$actual" -eq "$expected" ]]; then
        echo "ok $TESTS_RUN - $description"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "not ok $TESTS_RUN - $description"
        echo "  ---"
        echo "  table: $table_name"
        echo "  expected_rows: $expected"
        echo "  actual_rows: $actual"
        echo "  ..."
        ((TESTS_FAILED++)) || true
        return 1
    fi
}
