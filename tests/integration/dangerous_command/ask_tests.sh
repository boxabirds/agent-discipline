#!/usr/bin/env bash
# ask_tests.sh - Integration tests for ASK (confirmation required) dangerous commands
# Verifies the dangerous-command-guard.sh hook requests confirmation for these commands

echo "# Dangerous Command ASK Integration Tests"

# =============================================================================
# Test that ASK patterns produce correct JSON output
# =============================================================================

test_ask_output_git_push() {
    invoke_bash_hook "git push origin feature-branch"

    # Verify exit code is 0
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git push - exit code is 0"

    # Verify JSON structure
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.hookEventName' 'PreToolUse' "git push - hookEventName is PreToolUse"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "git push - permissionDecision is ask"

    # Verify reason is present
    local reason
    reason=$(echo "$HOOK_STDOUT" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
    if [[ -n "$reason" ]]; then
        echo "ok $((++TESTS_RUN)) - git push - reason is present: $reason"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $((++TESTS_RUN)) - git push - reason is missing"
        ((TESTS_FAILED++)) || true
    fi
}

test_ask_output_rm_rf_dir() {
    invoke_bash_hook "rm -rf node_modules"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "rm -rf dir - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "rm -rf dir - permissionDecision is ask"
}

test_ask_output_docker_stop() {
    invoke_bash_hook "docker stop web-server"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker stop - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "docker stop - permissionDecision is ask"
}

test_ask_output_kubectl_delete() {
    invoke_bash_hook "kubectl delete deployment nginx"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "kubectl delete - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "kubectl delete - permissionDecision is ask"
}

test_ask_output_npm_publish() {
    invoke_bash_hook "npm publish --access public"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "npm publish - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "npm publish - permissionDecision is ask"
}

# =============================================================================
# Verify reason field contains useful information
# =============================================================================

test_ask_reason_mentions_pattern() {
    invoke_bash_hook "docker-compose down -v"

    local reason
    reason=$(echo "$HOOK_STDOUT" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')

    ((TESTS_RUN++)) || true
    if echo "$reason" | grep -qi "pattern\|sensitive\|confirm"; then
        echo "ok $TESTS_RUN - docker-compose down -v - reason mentions pattern/sensitive/confirm"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - docker-compose down -v - reason should mention pattern"
        echo "  ---"
        echo "  reason: $reason"
        echo "  ..."
        ((TESTS_FAILED++)) || true
    fi
}

# =============================================================================
# Edge cases for ASK patterns
# =============================================================================

test_ask_git_push_with_flags() {
    invoke_bash_hook "git push -u origin feature --tags"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "git push with flags - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "git push with flags - permissionDecision is ask"
}

test_ask_docker_compose_v2() {
    invoke_bash_hook "docker compose down -v"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docker compose (v2) down -v - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "docker compose (v2) - permissionDecision is ask"
}

test_ask_truncate_lowercase() {
    invoke_bash_hook "truncate table logs"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "truncate (lowercase) - exit code is 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "truncate - permissionDecision is ask"
}

# =============================================================================
# Run all tests
# =============================================================================

test_ask_output_git_push
test_ask_output_rm_rf_dir
test_ask_output_docker_stop
test_ask_output_kubectl_delete
test_ask_output_npm_publish
test_ask_reason_mentions_pattern
test_ask_git_push_with_flags
test_ask_docker_compose_v2
test_ask_truncate_lowercase
