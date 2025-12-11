#!/usr/bin/env bash
# allow_tests.sh - Integration tests for ALLOWED commands
# Verifies the dangerous-command-guard.sh hook allows safe commands through

echo "# Dangerous Command ALLOW Integration Tests"

# =============================================================================
# Test that safe commands produce correct output (silent, exit 0)
# =============================================================================

test_allow_output_ls() {
    invoke_bash_hook "ls -la /tmp"

    # Verify exit code is 0
    assert_exit_code 0 "$HOOK_EXIT_CODE" "ls - exit code is 0"

    # Verify stdout is empty (no JSON output)
    assert_stdout_empty "$HOOK_STDOUT" "ls - stdout is empty"

    # Verify stderr is empty
    ((TESTS_RUN++)) || true
    if [[ -z "$HOOK_STDERR" ]]; then
        echo "ok $TESTS_RUN - ls - stderr is empty"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - ls - stderr should be empty"
        echo "  ---"
        echo "  stderr: $HOOK_STDERR"
        echo "  ..."
        ((TESTS_FAILED++)) || true
    fi
}

test_allow_output_git_status() {
    invoke_bash_hook "git status"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "git status - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "git status - stdout is empty"
}

test_allow_output_npm_install() {
    invoke_bash_hook "npm install express"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "npm install - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "npm install - stdout is empty"
}

test_allow_output_docker_build() {
    invoke_bash_hook "docker build -t myapp:latest ."

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker build - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "docker build - stdout is empty"
}

# =============================================================================
# Verify safe commands with similar patterns to dangerous ones
# =============================================================================

test_allow_git_commit_not_push() {
    invoke_bash_hook "git commit -m 'add feature'"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "git commit - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "git commit - stdout is empty"
}

test_allow_npm_run_not_publish() {
    invoke_bash_hook "npm run publish-script"

    # npm run <anything> should be allowed
    assert_exit_code 0 "$HOOK_EXIT_CODE" "npm run - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "npm run - stdout is empty"
}

test_allow_docker_pull_not_stop() {
    invoke_bash_hook "docker pull nginx:latest"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker pull - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "docker pull - stdout is empty"
}

test_allow_kubectl_apply_not_delete() {
    invoke_bash_hook "kubectl apply -f deployment.yaml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "kubectl apply - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "kubectl apply - stdout is empty"
}

# =============================================================================
# Verify database read operations are allowed
# =============================================================================

test_allow_select_query() {
    invoke_bash_hook "psql -c 'SELECT * FROM users WHERE id = 1'"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "SELECT query - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "SELECT query - stdout is empty"
}

test_allow_insert_query() {
    invoke_bash_hook "psql -c \"INSERT INTO logs VALUES (1, 'test')\""

    assert_exit_code 0 "$HOOK_EXIT_CODE" "INSERT query - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "INSERT query - stdout is empty"
}

test_allow_update_query() {
    invoke_bash_hook "psql -c \"UPDATE users SET name = 'Bob' WHERE id = 1\""

    assert_exit_code 0 "$HOOK_EXIT_CODE" "UPDATE query - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "UPDATE query - stdout is empty"
}

# =============================================================================
# Verify file operations that don't match patterns
# =============================================================================

test_allow_mkdir() {
    invoke_bash_hook "mkdir -p /tmp/newdir"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "mkdir - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "mkdir - stdout is empty"
}

test_allow_cp() {
    invoke_bash_hook "cp -r src/ dest/"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "cp - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "cp - stdout is empty"
}

test_allow_mv() {
    invoke_bash_hook "mv old.txt new.txt"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "mv - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "mv - stdout is empty"
}

test_allow_touch() {
    invoke_bash_hook "touch newfile.txt"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "touch - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "touch - stdout is empty"
}

# =============================================================================
# Run all tests
# =============================================================================

test_allow_output_ls
test_allow_output_git_status
test_allow_output_npm_install
test_allow_output_docker_build
test_allow_git_commit_not_push
test_allow_npm_run_not_publish
test_allow_docker_pull_not_stop
test_allow_kubectl_apply_not_delete
test_allow_select_query
test_allow_insert_query
test_allow_update_query
test_allow_mkdir
test_allow_cp
test_allow_mv
test_allow_touch
