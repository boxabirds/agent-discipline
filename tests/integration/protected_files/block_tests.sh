#!/usr/bin/env bash
# block_tests.sh - Integration tests for BLOCKED protected files
# Verifies the protected-files-guard.py hook blocks modifications to sensitive files

echo "# Protected Files BLOCK Integration Tests"

# =============================================================================
# Environment files - ALWAYS_BLOCK
# =============================================================================

test_block_env() {
    invoke_file_hook "Edit" ".env"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".env - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".env - stderr contains BLOCKED"
    assert_stdout_empty "$HOOK_STDOUT" ".env - stdout is empty"
}

test_block_env_local() {
    invoke_file_hook "Edit" ".env.local"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".env.local - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".env.local - stderr contains BLOCKED"
}

test_block_env_production() {
    invoke_file_hook "Write" ".env.production"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".env.production - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".env.production - stderr contains BLOCKED"
}

test_block_env_nested() {
    invoke_file_hook "Edit" "config/settings/.env"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "nested .env - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "nested .env - stderr contains BLOCKED"
}

# =============================================================================
# Private keys and certificates - ALWAYS_BLOCK
# =============================================================================

test_block_pem() {
    invoke_file_hook "Write" "ssl/server.pem"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".pem file - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".pem file - stderr contains BLOCKED"
}

test_block_key() {
    invoke_file_hook "Edit" "certs/private.key"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".key file - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".key file - stderr contains BLOCKED"
}

test_block_id_rsa() {
    invoke_file_hook "Edit" "~/.ssh/id_rsa"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "id_rsa - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "id_rsa - stderr contains BLOCKED"
}

test_block_id_ed25519() {
    invoke_file_hook "Write" ".ssh/id_ed25519"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "id_ed25519 - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "id_ed25519 - stderr contains BLOCKED"
}

# =============================================================================
# Secrets files - ALWAYS_BLOCK
# =============================================================================

test_block_secrets_yml() {
    invoke_file_hook "Edit" "secrets.yml"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "secrets.yml - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "secrets.yml - stderr contains BLOCKED"
}

test_block_secrets_yaml() {
    invoke_file_hook "Write" "config/secrets.yaml"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "secrets.yaml - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "secrets.yaml - stderr contains BLOCKED"
}

test_block_credentials_json() {
    invoke_file_hook "Edit" "credentials.json"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "credentials.json - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "credentials.json - stderr contains BLOCKED"
}

test_block_service_account_json() {
    invoke_file_hook "Write" "gcp/service-account.json"

    assert_exit_code 2 "$HOOK_EXIT_CODE" "service-account.json - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" "service-account.json - stderr contains BLOCKED"
}

# =============================================================================
# Git/SSH config - ALWAYS_BLOCK
# =============================================================================

test_block_git_config() {
    invoke_file_hook "Edit" ".git/config"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".git/config - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".git/config - stderr contains BLOCKED"
}

test_block_ssh_dir() {
    invoke_file_hook "Write" ".ssh/config"

    assert_exit_code 2 "$HOOK_EXIT_CODE" ".ssh/ files - exit code is 2"
    assert_stderr_contains "BLOCKED" "$HOOK_STDERR" ".ssh/ - stderr contains BLOCKED"
}

# =============================================================================
# Error message quality
# =============================================================================

test_block_message_includes_pattern() {
    invoke_file_hook "Edit" ".env"

    # Error message should include the matched pattern
    assert_stderr_contains "\\.env" "$HOOK_STDERR" ".env - error mentions pattern"
}

test_block_message_includes_filepath() {
    invoke_file_hook "Write" "config/secrets.yml"

    # Error message should include the file path
    assert_stderr_contains "secrets" "$HOOK_STDERR" "secrets.yml - error mentions file"
}

# =============================================================================
# Run all tests
# =============================================================================

# Environment files
test_block_env
test_block_env_local
test_block_env_production
test_block_env_nested

# Keys and certificates
test_block_pem
test_block_key
test_block_id_rsa
test_block_id_ed25519

# Secrets files
test_block_secrets_yml
test_block_secrets_yaml
test_block_credentials_json
test_block_service_account_json

# Git/SSH config
test_block_git_config
test_block_ssh_dir

# Message quality
test_block_message_includes_pattern
test_block_message_includes_filepath
