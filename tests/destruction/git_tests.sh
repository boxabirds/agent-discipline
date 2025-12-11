#!/usr/bin/env bash
# git_tests.sh - Verify hooks prevent git destruction
# These tests verify that when hooks BLOCK a command, git state is preserved

echo "# Git Defense Verification Tests"

# =============================================================================
# Helper to create fresh git repo
# =============================================================================

setup_git_repo() {
    local repo_dir="$WORKING_DIR/git_test_repo"
    rm -rf "$repo_dir"
    mkdir -p "$repo_dir"

    (
        cd "$repo_dir"
        git init --quiet
        git config user.email "test@example.com"
        git config user.name "Test User"

        # Initial commit
        echo "initial content" > file.txt
        git add file.txt
        git commit -m "Initial commit" --quiet

        # Second commit
        echo "second content" >> file.txt
        git commit -am "Second commit" --quiet

        # Third commit
        echo "third content" >> file.txt
        git commit -am "Third commit" --quiet
    )

    echo "$repo_dir"
}

# =============================================================================
# Test: Hook blocks git reset --hard origin, commits preserved
# =============================================================================

test_defense_git_reset_hard_origin() {
    local repo_dir
    repo_dir=$(setup_git_repo)

    # Verify initial state: 3 commits
    assert_git_commit_count "$repo_dir" 3 "Setup: 3 commits exist"

    # Invoke hook - should BLOCK
    invoke_bash_hook "git reset --hard origin/main"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "git reset --hard origin is blocked"

    # Verify commits preserved
    assert_git_commit_count "$repo_dir" 3 "All 3 commits preserved - command blocked"
}

# =============================================================================
# Test: Hook blocks force push to main/master
# =============================================================================

test_defense_force_push_main() {
    local repo_dir
    repo_dir=$(setup_git_repo)

    # Verify setup
    assert_git_commit_count "$repo_dir" 3 "Setup: 3 commits exist"

    # Invoke hook - should BLOCK
    invoke_bash_hook "git push --force origin main"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "git push --force main is blocked"

    # Commits still intact locally
    assert_git_commit_count "$repo_dir" 3 "Commits preserved - command blocked"
}

test_defense_force_push_master() {
    invoke_bash_hook "git push -f origin master"
    assert_exit_code 2 "$HOOK_EXIT_CODE" "git push -f master is blocked"
}

# =============================================================================
# Test: Hook requires confirmation for git push (ASK, not BLOCK)
# =============================================================================

test_defense_git_push_asks_confirmation() {
    local repo_dir
    repo_dir=$(setup_git_repo)

    # Invoke hook - should ASK
    invoke_bash_hook "git push origin feature-branch"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git push exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "git push asks for confirmation"

    # Commits still intact (command intercepted before execution)
    assert_git_commit_count "$repo_dir" 3 "Commits preserved - confirmation required"
}

# =============================================================================
# Test: Hook requires confirmation for git reset --hard (non-origin)
# =============================================================================

test_defense_git_reset_hard_asks_confirmation() {
    local repo_dir
    repo_dir=$(setup_git_repo)

    # Verify initial state
    assert_git_commit_count "$repo_dir" 3 "Setup: 3 commits exist"

    # Invoke hook - should ASK (not origin, so not hard blocked)
    invoke_bash_hook "git reset --hard HEAD~1"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git reset --hard HEAD~1 exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "git reset --hard asks for confirmation"

    # Commits preserved because hook intercepts
    assert_git_commit_count "$repo_dir" 3 "All commits preserved - confirmation required"
}

# =============================================================================
# Test: Hook requires confirmation for git clean -fd
# =============================================================================

test_defense_git_clean_asks_confirmation() {
    local repo_dir
    repo_dir=$(setup_git_repo)

    # Create untracked file
    echo "untracked" > "$repo_dir/untracked.txt"
    assert_file_exists "$repo_dir/untracked.txt" "Setup: untracked file exists"

    # Invoke hook - should ASK
    invoke_bash_hook "git clean -fd"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git clean -fd exits 0"
    assert_json_field "$HOOK_STDOUT" '.hookSpecificOutput.permissionDecision' 'ask' "git clean -fd asks for confirmation"

    # Untracked file survives because hook intercepts
    assert_file_exists "$repo_dir/untracked.txt" "Untracked file preserved - confirmation required"
}

# =============================================================================
# Test: Safe git commands are allowed
# =============================================================================

test_defense_git_status_allowed() {
    invoke_bash_hook "git status"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git status exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "git status produces no JSON (allowed)"
}

test_defense_git_log_allowed() {
    invoke_bash_hook "git log --oneline -10"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git log exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "git log produces no JSON (allowed)"
}

test_defense_git_diff_allowed() {
    invoke_bash_hook "git diff HEAD~1"
    assert_exit_code 0 "$HOOK_EXIT_CODE" "git diff exits 0"
    assert_stdout_empty "$HOOK_STDOUT" "git diff produces no JSON (allowed)"
}

# =============================================================================
# Run all tests
# =============================================================================

# Hard blocks
test_defense_git_reset_hard_origin
test_defense_force_push_main
test_defense_force_push_master

# Confirmation required
test_defense_git_push_asks_confirmation
test_defense_git_reset_hard_asks_confirmation
test_defense_git_clean_asks_confirmation

# Allowed operations
test_defense_git_status_allowed
test_defense_git_log_allowed
test_defense_git_diff_allowed
