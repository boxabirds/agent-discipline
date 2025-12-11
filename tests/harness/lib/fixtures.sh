#!/usr/bin/env bash
# fixtures.sh - Fixture setup and teardown
set -euo pipefail

# Guard against double-sourcing
[[ -n "${_FIXTURES_SH_LOADED:-}" ]] && return 0
readonly _FIXTURES_SH_LOADED=1

# =============================================================================
# Constants
# =============================================================================

readonly FIXTURES_DIR="${FIXTURES_DIR:-/fixtures}"
readonly WORKING_DIR="${WORKING_DIR:-/working}"

# =============================================================================
# Core fixture management
# =============================================================================

# setup_working_dir()
# Create fresh working directory with fixtures copied
setup_working_dir() {
    # Clean any existing working directory
    rm -rf "${WORKING_DIR:?}"/* 2>/dev/null || true

    # Copy fixtures to working directory
    if [[ -d "$FIXTURES_DIR" ]]; then
        cp -r "$FIXTURES_DIR"/* "$WORKING_DIR/" 2>/dev/null || true
    fi

    # Make git fixtures functional (they are copied as static files)
    setup_git_fixtures
}

# setup_git_fixtures()
# Initialize copied git fixtures as real repos
setup_git_fixtures() {
    local git_dir="$WORKING_DIR/git/repo"

    if [[ -d "$git_dir" ]] && [[ ! -d "$git_dir/.git" ]]; then
        (
            cd "$git_dir"
            git init --quiet
            git add -A
            git commit -m "Test fixture" --quiet 2>/dev/null || true
        )
    fi
}

# cleanup_working_dir()
# Remove working directory contents
cleanup_working_dir() {
    rm -rf "${WORKING_DIR:?}"/* 2>/dev/null || true
}

# =============================================================================
# Selective fixture setup
# =============================================================================

# with_fixture(fixture_name, callback)
# Setup specific fixture and run callback
with_fixture() {
    local fixture_name="$1"
    shift
    local callback="$*"

    # Setup specific fixture
    case "$fixture_name" in
        fs)
            mkdir -p "$WORKING_DIR/fs"
            cp -r "$FIXTURES_DIR/fs"/* "$WORKING_DIR/fs/" 2>/dev/null || true
            ;;
        git)
            mkdir -p "$WORKING_DIR/git"
            cp -r "$FIXTURES_DIR/git"/* "$WORKING_DIR/git/" 2>/dev/null || true
            setup_git_fixtures
            ;;
        db)
            mkdir -p "$WORKING_DIR/db"
            cp -r "$FIXTURES_DIR/db"/* "$WORKING_DIR/db/" 2>/dev/null || true
            ;;
        protected)
            mkdir -p "$WORKING_DIR/protected"
            cp -r "$FIXTURES_DIR/protected"/* "$WORKING_DIR/protected/" 2>/dev/null || true
            ;;
        *)
            echo "Unknown fixture: $fixture_name" >&2
            return 1
            ;;
    esac

    # Run callback
    eval "$callback"
}

# =============================================================================
# Fixture creation helpers (for dynamic test setup)
# =============================================================================

# create_test_file(path, content)
# Create a file with content in working directory
create_test_file() {
    local path="$1"
    local content="${2:-test content}"

    mkdir -p "$(dirname "$WORKING_DIR/$path")"
    echo "$content" > "$WORKING_DIR/$path"
}

# create_test_dir(path)
# Create a directory in working directory
create_test_dir() {
    local path="$1"
    mkdir -p "$WORKING_DIR/$path"
}

# create_git_repo(path)
# Create a git repository with initial commit
create_git_repo() {
    local path="$1"
    local repo_dir="$WORKING_DIR/$path"

    mkdir -p "$repo_dir"
    (
        cd "$repo_dir"
        git init --quiet
        echo "# Test repo" > README.md
        git add README.md
        git commit -m "Initial commit" --quiet
    )
}

# create_sqlite_db(path, schema_sql)
# Create a SQLite database with schema
create_sqlite_db() {
    local path="$1"
    local schema="${2:-}"

    mkdir -p "$(dirname "$WORKING_DIR/$path")"
    if [[ -n "$schema" ]]; then
        sqlite3 "$WORKING_DIR/$path" "$schema"
    else
        touch "$WORKING_DIR/$path"
    fi
}
