#!/usr/bin/env bash
# ask_tests.sh - Integration tests for ASK (confirmation required) protected files
# Verifies the protected-files-guard.py hook requests confirmation for certain files

echo "# Protected Files ASK Integration Tests"

# =============================================================================
# Lock files - REQUIRE_CONFIRMATION
# =============================================================================

test_ask_package_lock_json() {
    invoke_file_hook "Edit" "package-lock.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "package-lock.json - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "package-lock.json - permissionDecision is ask"
}

test_ask_yarn_lock() {
    invoke_file_hook "Write" "yarn.lock"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "yarn.lock - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "yarn.lock - permissionDecision is ask"
}

test_ask_pnpm_lock_yaml() {
    invoke_file_hook "Edit" "pnpm-lock.yaml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "pnpm-lock.yaml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "pnpm-lock.yaml - permissionDecision is ask"
}

# =============================================================================
# Docker files - REQUIRE_CONFIRMATION
# =============================================================================

test_ask_dockerfile() {
    invoke_file_hook "Edit" "Dockerfile"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "Dockerfile - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "Dockerfile - permissionDecision is ask"
}

test_ask_docker_compose_yml() {
    invoke_file_hook "Write" "docker-compose.yml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker-compose.yml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "docker-compose.yml - permissionDecision is ask"
}

test_ask_docker_compose_yaml() {
    invoke_file_hook "Edit" "docker-compose.yaml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker-compose.yaml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "docker-compose.yaml - permissionDecision is ask"
}

# =============================================================================
# CI/CD files - REQUIRE_CONFIRMATION
# =============================================================================

test_ask_github_workflow() {
    invoke_file_hook "Edit" ".github/workflows/ci.yml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".github/ workflow - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' ".github/ - permissionDecision is ask"
}

test_ask_gitlab_ci_yml() {
    invoke_file_hook "Write" ".gitlab-ci.yml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".gitlab-ci.yml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' ".gitlab-ci.yml - permissionDecision is ask"
}

# =============================================================================
# Build/config files - REQUIRE_CONFIRMATION
# =============================================================================

test_ask_makefile() {
    invoke_file_hook "Edit" "Makefile"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "Makefile - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "Makefile - permissionDecision is ask"
}

test_ask_tsconfig_json() {
    invoke_file_hook "Edit" "tsconfig.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "tsconfig.json - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "tsconfig.json - permissionDecision is ask"
}

test_ask_pyproject_toml() {
    invoke_file_hook "Write" "pyproject.toml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "pyproject.toml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "pyproject.toml - permissionDecision is ask"
}

test_ask_cargo_toml() {
    invoke_file_hook "Edit" "Cargo.toml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "Cargo.toml - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "Cargo.toml - permissionDecision is ask"
}

# =============================================================================
# Claude config - REQUIRE_CONFIRMATION
# =============================================================================

test_ask_claude_settings() {
    invoke_file_hook "Edit" ".claude/settings.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".claude/ settings - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' ".claude/ - permissionDecision is ask"
}

test_ask_claude_commands() {
    invoke_file_hook "Write" ".claude/commands/custom.md"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".claude/ commands - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' ".claude/ - permissionDecision is ask"
}

# =============================================================================
# Verify reason field
# =============================================================================

test_ask_reason_mentions_sensitive() {
    invoke_file_hook "Edit" "Dockerfile"

    local reason
    reason=$(echo "$HOOK_STDOUT" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')

    ((TESTS_RUN++)) || true
    if echo "$reason" | grep -qi "pattern\|sensitive\|confirm"; then
        echo "ok $TESTS_RUN - Dockerfile - reason mentions sensitive/pattern/confirm"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - Dockerfile - reason should mention sensitive"
        echo "  ---"
        echo "  reason: $reason"
        echo "  ..."
        ((TESTS_FAILED++)) || true
    fi
}

# =============================================================================
# Run all tests
# =============================================================================

# Lock files
test_ask_package_lock_json
test_ask_yarn_lock
test_ask_pnpm_lock_yaml

# Docker files
test_ask_dockerfile
test_ask_docker_compose_yml
test_ask_docker_compose_yaml

# CI/CD files
test_ask_github_workflow
test_ask_gitlab_ci_yml

# Build/config files
test_ask_makefile
test_ask_tsconfig_json
test_ask_pyproject_toml
test_ask_cargo_toml

# Claude config
test_ask_claude_settings
test_ask_claude_commands

# Reason field
test_ask_reason_mentions_sensitive
