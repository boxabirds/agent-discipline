#!/usr/bin/env bash
# filesystem_tests.sh - Verify hooks prevent filesystem destruction
# These tests verify that when hooks BLOCK a command, sentinel files SURVIVE

echo "# Filesystem Defense Verification Tests"

# =============================================================================
# Test: Hook blocks rm -rf / and sentinel survives
# =============================================================================

test_defense_rm_rf_root() {
    # Setup: create sentinel file
    mkdir -p "$WORKING_DIR/important"
    echo "critical data" > "$WORKING_DIR/important/sentinel.txt"

    # Verify setup
    assert_file_exists "$WORKING_DIR/important/sentinel.txt" "Setup: sentinel exists"

    # Invoke hook - should BLOCK
    invoke_bash_hook "rm -rf /"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "rm -rf / is blocked by hook"

    # Verify sentinel survives (command was never executed)
    assert_file_exists "$WORKING_DIR/important/sentinel.txt" "Sentinel survived - command blocked"
}

test_defense_rm_rf_star() {
    # Setup
    echo "important" > "$WORKING_DIR/sentinel.txt"
    assert_file_exists "$WORKING_DIR/sentinel.txt" "Setup: sentinel exists"

    # Invoke hook - should BLOCK
    invoke_bash_hook "rm -rf *"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "rm -rf * is blocked by hook"

    # Verify sentinel survives
    assert_file_exists "$WORKING_DIR/sentinel.txt" "Sentinel survived - command blocked"
}

test_defense_rm_rf_home() {
    # Setup
    echo "home data" > "$WORKING_DIR/home_sentinel.txt"
    assert_file_exists "$WORKING_DIR/home_sentinel.txt" "Setup: sentinel exists"

    # Invoke hook - should BLOCK
    invoke_bash_hook "rm -rf ~"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "rm -rf ~ is blocked by hook"

    # Verify sentinel survives
    assert_file_exists "$WORKING_DIR/home_sentinel.txt" "Sentinel survived - command blocked"
}

# =============================================================================
# Test: Hook blocks device writes
# =============================================================================

test_defense_write_to_device() {
    echo "system intact" > "$WORKING_DIR/system_sentinel.txt"

    invoke_bash_hook "dd if=/dev/zero of=/dev/sda"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "dd to device is blocked by hook"

    assert_file_exists "$WORKING_DIR/system_sentinel.txt" "Sentinel survived - command blocked"
}

test_defense_mkfs() {
    echo "filesystem intact" > "$WORKING_DIR/fs_sentinel.txt"

    invoke_bash_hook "mkfs.ext4 /dev/sda1"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "mkfs is blocked by hook"

    assert_file_exists "$WORKING_DIR/fs_sentinel.txt" "Sentinel survived - command blocked"
}

# =============================================================================
# Test: Hook requires confirmation for rm -rf (ASK, not BLOCK)
# =============================================================================

test_defense_rm_rf_asks_confirmation() {
    # Setup
    mkdir -p "$WORKING_DIR/node_modules"
    echo "package" > "$WORKING_DIR/node_modules/sentinel.txt"
    assert_file_exists "$WORKING_DIR/node_modules/sentinel.txt" "Setup: sentinel exists"

    # Invoke hook - should ASK (exit 0 + JSON)
    invoke_bash_hook "rm -rf node_modules"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "rm -rf node_modules exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "rm -rf asks for confirmation"

    # Sentinel survives because hook intercepts before execution
    assert_file_exists "$WORKING_DIR/node_modules/sentinel.txt" "Sentinel survived - confirmation required"
}

# =============================================================================
# Test: Shell bypass attempts are blocked, sentinels survive
# =============================================================================

test_defense_echo_to_env() {
    # Setup: create a file that shouldn't be modified
    echo "original" > "$WORKING_DIR/.env"
    local original_content
    original_content=$(cat "$WORKING_DIR/.env")

    # Invoke hook - should BLOCK
    invoke_bash_hook 'echo "HACKED=true" >> .env'
    assert_exit_code 2 "$HOOK_EXIT_CODE" "echo >> .env is blocked by hook"

    # Verify content unchanged
    local current_content
    current_content=$(cat "$WORKING_DIR/.env")
    ((TESTS_RUN++)) || true
    if [[ "$current_content" == "$original_content" ]]; then
        echo "ok $TESTS_RUN - .env content unchanged"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - .env was modified"
        ((TESTS_FAILED++)) || true
    fi
}

test_defense_cat_to_secrets() {
    echo "secret: original" > "$WORKING_DIR/secrets.yml"
    local original_content
    original_content=$(cat "$WORKING_DIR/secrets.yml")

    invoke_bash_hook 'cat > secrets.yml << EOF
secret: hacked
EOF'
    assert_exit_code 2 "$HOOK_EXIT_CODE" "cat > secrets.yml is blocked by hook"

    local current_content
    current_content=$(cat "$WORKING_DIR/secrets.yml")
    ((TESTS_RUN++)) || true
    if [[ "$current_content" == "$original_content" ]]; then
        echo "ok $TESTS_RUN - secrets.yml content unchanged"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - secrets.yml was modified"
        ((TESTS_FAILED++)) || true
    fi
}

test_defense_sed_private_key() {
    echo "-----BEGIN PRIVATE KEY-----" > "$WORKING_DIR/server.pem"
    local original_content
    original_content=$(cat "$WORKING_DIR/server.pem")

    invoke_bash_hook 'sed -i "s/PRIVATE/PUBLIC/" server.pem'
    assert_exit_code 2 "$HOOK_EXIT_CODE" "sed -i on .pem is blocked by hook"

    local current_content
    current_content=$(cat "$WORKING_DIR/server.pem")
    ((TESTS_RUN++)) || true
    if [[ "$current_content" == "$original_content" ]]; then
        echo "ok $TESTS_RUN - server.pem content unchanged"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - server.pem was modified"
        ((TESTS_FAILED++)) || true
    fi
}

# =============================================================================
# Run all tests
# =============================================================================

# Filesystem destruction blocked
test_defense_rm_rf_root
test_defense_rm_rf_star
test_defense_rm_rf_home
test_defense_write_to_device
test_defense_mkfs

# Confirmation required (sentinel survives)
test_defense_rm_rf_asks_confirmation

# Shell bypass blocked
test_defense_echo_to_env
test_defense_cat_to_secrets
test_defense_sed_private_key
