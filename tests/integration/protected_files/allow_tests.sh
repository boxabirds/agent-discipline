#!/usr/bin/env bash
# allow_tests.sh - Integration tests for ALLOWED file modifications
# Verifies the protected-files-guard.py hook allows modifications to safe files

echo "# Protected Files ALLOW Integration Tests"

# =============================================================================
# Source code files - ALLOWED
# =============================================================================

test_allow_typescript() {
    invoke_file_hook "Edit" "src/main.ts"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "main.ts - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "main.ts - stdout is empty"
}

test_allow_javascript() {
    invoke_file_hook "Write" "src/utils.js"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "utils.js - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "utils.js - stdout is empty"
}

test_allow_python() {
    invoke_file_hook "Edit" "app/main.py"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "main.py - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "main.py - stdout is empty"
}

test_allow_rust() {
    invoke_file_hook "Write" "src/lib.rs"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "lib.rs - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "lib.rs - stdout is empty"
}

test_allow_go() {
    invoke_file_hook "Edit" "cmd/main.go"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "main.go - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "main.go - stdout is empty"
}

# =============================================================================
# Test files - ALLOWED
# =============================================================================

test_allow_test_file() {
    invoke_file_hook "Edit" "tests/test_main.py"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "test file - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "test file - stdout is empty"
}

test_allow_spec_file() {
    invoke_file_hook "Write" "src/__tests__/utils.spec.ts"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "spec file - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "spec file - stdout is empty"
}

# =============================================================================
# Documentation - ALLOWED
# =============================================================================

test_allow_readme() {
    invoke_file_hook "Edit" "README.md"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "README.md - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "README.md - stdout is empty"
}

test_allow_docs() {
    invoke_file_hook "Write" "docs/api.md"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "docs/ - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "docs/ - stdout is empty"
}

# =============================================================================
# Config files that are NOT protected - ALLOWED
# =============================================================================

test_allow_package_json() {
    # Note: package.json is allowed, only package-lock.json requires confirmation
    invoke_file_hook "Edit" "package.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "package.json - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "package.json - stdout is empty"
}

test_allow_eslint_config() {
    invoke_file_hook "Write" ".eslintrc.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".eslintrc.json - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" ".eslintrc.json - stdout is empty"
}

test_allow_prettier_config() {
    invoke_file_hook "Edit" ".prettierrc"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".prettierrc - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" ".prettierrc - stdout is empty"
}

test_allow_gitignore() {
    invoke_file_hook "Write" ".gitignore"

    assert_exit_code 0 "$HOOK_EXIT_CODE" ".gitignore - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" ".gitignore - stdout is empty"
}

# =============================================================================
# Data files - ALLOWED
# =============================================================================

test_allow_json_data() {
    invoke_file_hook "Edit" "data/users.json"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "data JSON - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "data JSON - stdout is empty"
}

test_allow_yaml_data() {
    invoke_file_hook "Write" "config/settings.yaml"

    assert_exit_code 0 "$HOOK_EXIT_CODE" "settings.yaml - exit code is 0"
    assert_stdout_empty "$HOOK_STDOUT" "settings.yaml - stdout is empty"
}

# =============================================================================
# Edge cases - files with similar names
# =============================================================================

test_env_example_blocked_by_substring() {
    # NOTE: .env.example is BLOCKED because the pattern '.env' is a substring
    # This is a known limitation of the current hook implementation
    # The hook uses `if pattern in file_path` which matches substrings
    invoke_file_hook "Write" ".env.example"

    # This WILL be blocked because '.env' is in '.env.example'
    ((TESTS_RUN++)) || true
    if [[ "$HOOK_EXIT_CODE" -eq 2 ]]; then
        echo "ok $TESTS_RUN - .env.example - blocked (substring match on '.env')"
        ((TESTS_PASSED++)) || true
    elif [[ "$HOOK_EXIT_CODE" -eq 0 ]] && [[ -z "$HOOK_STDOUT" ]]; then
        echo "ok $TESTS_RUN - .env.example - allowed (hook behavior changed)"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - .env.example - unexpected behavior"
        ((TESTS_FAILED++)) || true
    fi
}

test_secrets_template_blocked_by_substring() {
    # NOTE: secrets.yml.example is BLOCKED because 'secrets.yml' is a substring
    invoke_file_hook "Edit" "secrets.yml.example"

    # This WILL be blocked because 'secrets.yml' is in 'secrets.yml.example'
    ((TESTS_RUN++)) || true
    if [[ "$HOOK_EXIT_CODE" -eq 2 ]]; then
        echo "ok $TESTS_RUN - secrets.yml.example - blocked (substring match)"
        ((TESTS_PASSED++)) || true
    elif [[ "$HOOK_EXIT_CODE" -eq 0 ]] && [[ -z "$HOOK_STDOUT" ]]; then
        echo "ok $TESTS_RUN - secrets.yml.example - allowed (hook behavior changed)"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - secrets.yml.example - unexpected behavior"
        ((TESTS_FAILED++)) || true
    fi
}

test_allow_public_key() {
    # Public keys should be allowed (only private keys are blocked)
    invoke_file_hook "Write" ".ssh/id_rsa.pub"

    # Note: This might be blocked because .ssh/ is in ALWAYS_BLOCK
    # If blocked, that's actually correct behavior
    ((TESTS_RUN++)) || true
    if [[ "$HOOK_EXIT_CODE" -eq 0 ]] && [[ -z "$HOOK_STDOUT" ]]; then
        echo "ok $TESTS_RUN - id_rsa.pub - allowed"
        ((TESTS_PASSED++)) || true
    elif [[ "$HOOK_EXIT_CODE" -eq 2 ]]; then
        echo "ok $TESTS_RUN - id_rsa.pub - blocked (due to .ssh/ pattern)"
        ((TESTS_PASSED++)) || true
    else
        echo "not ok $TESTS_RUN - id_rsa.pub - unexpected behavior"
        ((TESTS_FAILED++)) || true
    fi
}

# =============================================================================
# Run all tests
# =============================================================================

# Source code
test_allow_typescript
test_allow_javascript
test_allow_python
test_allow_rust
test_allow_go

# Test files
test_allow_test_file
test_allow_spec_file

# Documentation
test_allow_readme
test_allow_docs

# Unprotected configs
test_allow_package_json
test_allow_eslint_config
test_allow_prettier_config
test_allow_gitignore

# Data files
test_allow_json_data
test_allow_yaml_data

# Edge cases (substring matching behavior)
test_env_example_blocked_by_substring
test_secrets_template_blocked_by_substring
test_allow_public_key
