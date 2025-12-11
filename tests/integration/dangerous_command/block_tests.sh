#!/usr/bin/env bash
# block_tests.sh - Integration tests for BLOCKED dangerous commands
# Verifies the dangerous-command-guard.sh hook blocks these commands

echo "# Dangerous Command BLOCK Integration Tests"

# =============================================================================
# Test that DENY patterns produce correct hook output
# =============================================================================

test_block_output_rm_rf_root() {
    invoke_bash_hook "rm -rf /"

    # Verify exit code
    assert_exit_code 2 "$HOOK_EXIT_CODE" "rm -rf / - exit code is 2"

    # Verify stderr contains BLOCKED message
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "rm -rf / - stderr contains BLOCKED"

    # Verify stdout is empty (no JSON output)
    assert_stdout_empty "$HOOK_STDOUT" "rm -rf / - stdout is empty"
}

test_block_output_force_push() {
    invoke_bash_hook "git push --force origin main"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "git push --force main - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "git push --force main - stderr contains BLOCKED"
    assert_stderr_contains "pattern" "$HOOK_STDERR" "git push --force main - stderr mentions pattern"
}

test_block_output_drop_database() {
    invoke_bash_hook "DROP DATABASE production"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "DROP DATABASE - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "DROP DATABASE - stderr contains BLOCKED"
}

test_block_output_docker_nuclear() {
    invoke_bash_hook "docker system prune -a --volumes -f"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "docker system prune -a --volumes - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "docker system prune - stderr contains BLOCKED"
}

# =============================================================================
# Test message quality (feedback loop)
# =============================================================================

test_block_message_includes_command() {
    invoke_bash_hook "rm -rf /*"

    # The error message should include part of the command for debugging
    assert_stderr_contains "rm" "$HOOK_STDERR" "error message includes command"
}

test_block_message_includes_pattern() {
    invoke_bash_hook "mkfs.ext4 /dev/sda1"

    # The error message should indicate what pattern was matched
    assert_stderr_contains "mkfs" "$HOOK_STDERR" "error message includes matched pattern"
}

# =============================================================================
# Edge cases
# =============================================================================

test_block_case_insensitive_drop_database() {
    invoke_bash_hook "drop database production"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "drop database (lowercase) - exit code is 2"
}

test_block_with_extra_whitespace() {
    invoke_bash_hook "rm   -rf   /"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "rm -rf / (extra whitespace) - exit code is 2"
}

test_block_with_sudo() {
    invoke_bash_hook "sudo rm -rf /"

    # Should still block even with sudo prefix
    assert_exit_code 2 "$HOOK_EXIT_CODE" "sudo rm -rf / - exit code is 2"
}

# =============================================================================
# Run all tests
# =============================================================================

test_block_output_rm_rf_root
test_block_output_force_push
test_block_output_drop_database
test_block_output_docker_nuclear
test_block_message_includes_command
test_block_message_includes_pattern
test_block_case_insensitive_drop_database
test_block_with_extra_whitespace
test_block_with_sudo
