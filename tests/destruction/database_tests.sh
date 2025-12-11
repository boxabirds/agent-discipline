#!/usr/bin/env bash
# database_tests.sh - Verify hooks prevent database destruction
# These tests verify that when hooks BLOCK a command, database state is preserved

echo "# Database Defense Verification Tests"

# =============================================================================
# Helper to create fresh SQLite database
# =============================================================================

setup_test_db() {
    local db_path="$WORKING_DIR/test.sqlite"
    rm -f "$db_path"

    sqlite3 "$db_path" <<'EOF'
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL
);

INSERT INTO users (name, email) VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com'),
    ('Charlie', 'charlie@example.com');

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    total DECIMAL(10,2)
);

INSERT INTO orders (user_id, total) VALUES
    (1, 99.99),
    (2, 149.99),
    (3, 49.99);
EOF

    echo "$db_path"
}

# =============================================================================
# Test: Hook blocks DROP DATABASE, data preserved
# =============================================================================

test_defense_drop_database() {
    local db_path
    db_path=$(setup_test_db)

    # Verify setup
    assert_table_exists "$db_path" "users" "Setup: users table exists"
    assert_row_count "$db_path" "users" 3 "Setup: users has 3 rows"

    # Invoke hook - should BLOCK
    invoke_bash_hook "psql -c 'DROP DATABASE production'"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "DROP DATABASE is blocked"

    # Verify data preserved
    assert_table_exists "$db_path" "users" "users table preserved - command blocked"
    assert_row_count "$db_path" "users" 3 "All 3 users preserved - command blocked"
}

test_defense_drop_schema_cascade() {
    local db_path
    db_path=$(setup_test_db)

    assert_table_exists "$db_path" "users" "Setup: users table exists"

    invoke_bash_hook "psql -c 'DROP SCHEMA public CASCADE'"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "DROP SCHEMA CASCADE is blocked"

    assert_table_exists "$db_path" "users" "users table preserved - command blocked"
}

test_defense_truncate_cascade() {
    local db_path
    db_path=$(setup_test_db)

    assert_row_count "$db_path" "users" 3 "Setup: users has 3 rows"

    invoke_bash_hook "psql -c 'TRUNCATE users CASCADE'"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "TRUNCATE CASCADE is blocked"

    assert_row_count "$db_path" "users" 3 "All rows preserved - command blocked"
}

# =============================================================================
# Test: Hook requires confirmation for DROP TABLE (ASK, not BLOCK)
# =============================================================================

test_defense_drop_table_asks_confirmation() {
    local db_path
    db_path=$(setup_test_db)

    assert_table_exists "$db_path" "orders" "Setup: orders table exists"

    # Invoke hook - should ASK
    invoke_bash_hook "psql -c 'DROP TABLE orders'"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "DROP TABLE exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "DROP TABLE asks for confirmation"

    # Table preserved because hook intercepts
    assert_table_exists "$db_path" "orders" "orders table preserved - confirmation required"
}

# =============================================================================
# Test: Hook requires confirmation for TRUNCATE (ASK, not BLOCK)
# =============================================================================

test_defense_truncate_asks_confirmation() {
    local db_path
    db_path=$(setup_test_db)

    assert_row_count "$db_path" "users" 3 "Setup: users has 3 rows"

    # Invoke hook - should ASK (TRUNCATE without CASCADE)
    invoke_bash_hook "psql -c 'TRUNCATE users'"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "TRUNCATE exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "TRUNCATE asks for confirmation"

    # Rows preserved because hook intercepts
    assert_row_count "$db_path" "users" 3 "All rows preserved - confirmation required"
}

# =============================================================================
# Test: Hook requires confirmation for DELETE without WHERE
# =============================================================================

test_defense_delete_no_where_asks_confirmation() {
    local db_path
    db_path=$(setup_test_db)

    assert_row_count "$db_path" "orders" 3 "Setup: orders has 3 rows"

    # Invoke hook - should ASK
    invoke_bash_hook "psql -c 'DELETE FROM orders'"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "DELETE FROM exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "DELETE FROM asks for confirmation"

    # Rows preserved
    assert_row_count "$db_path" "orders" 3 "All rows preserved - confirmation required"
}

# =============================================================================
# Test: Safe database operations are allowed
# =============================================================================

test_defense_select_allowed() {
    invoke_bash_hook "psql -c 'SELECT * FROM users'"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "SELECT exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "SELECT produces no JSON (allowed)"
}

test_defense_insert_allowed() {
    invoke_bash_hook "psql -c \"INSERT INTO users (name, email) VALUES ('Dave', 'dave@example.com')\""
    assert_exit_code 0 "$HOOK_EXIT_CODE" "INSERT exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "INSERT produces no JSON (allowed)"
}

test_defense_update_with_where_allowed() {
    invoke_bash_hook "psql -c \"UPDATE users SET name = 'Alice Smith' WHERE id = 1\""
    assert_exit_code 0 "$HOOK_EXIT_CODE" "UPDATE with WHERE exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "UPDATE with WHERE produces no JSON (allowed)"
}

test_defense_delete_with_where_allowed() {
    invoke_bash_hook "psql -c \"DELETE FROM orders WHERE id = 1\""
    assert_exit_code 0 "$HOOK_EXIT_CODE" "DELETE with WHERE exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "DELETE with WHERE produces no JSON (allowed)"
}

# =============================================================================
# Run all tests
# =============================================================================

# Hard blocks
test_defense_drop_database
test_defense_drop_schema_cascade
test_defense_truncate_cascade

# Confirmation required
test_defense_drop_table_asks_confirmation
test_defense_truncate_asks_confirmation
test_defense_delete_no_where_asks_confirmation

# Allowed operations
test_defense_select_allowed
test_defense_insert_allowed
test_defense_update_with_where_allowed
test_defense_delete_with_where_allowed
