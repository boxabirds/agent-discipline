#!/usr/bin/env bash
# pattern_allow_test.sh - Test that safe commands are ALLOWED
# These commands should pass through without any intervention (exit 0, silent)

echo "# ALLOW Pattern Tests"

# =============================================================================
# Basic safe commands
# =============================================================================

test_allow_ls() {
    invoke_bash_hook "ls -la"
    assert_hook_allowed "ls -la is allowed"
}

test_allow_cat() {
    invoke_bash_hook "cat file.txt"
    assert_hook_allowed "cat is allowed"
}

test_allow_grep() {
    invoke_bash_hook "grep -r 'pattern' ."
    assert_hook_allowed "grep is allowed"
}

test_allow_find() {
    invoke_bash_hook "find . -name '*.txt'"
    assert_hook_allowed "find is allowed"
}

test_allow_pwd() {
    invoke_bash_hook "pwd"
    assert_hook_allowed "pwd is allowed"
}

test_allow_echo() {
    invoke_bash_hook "echo 'hello world'"
    assert_hook_allowed "echo is allowed"
}

test_allow_head() {
    invoke_bash_hook "head -n 10 file.txt"
    assert_hook_allowed "head is allowed"
}

test_allow_tail() {
    invoke_bash_hook "tail -f log.txt"
    assert_hook_allowed "tail is allowed"
}

test_allow_wc() {
    invoke_bash_hook "wc -l file.txt"
    assert_hook_allowed "wc is allowed"
}

# =============================================================================
# Safe git operations
# =============================================================================

test_allow_git_status() {
    invoke_bash_hook "git status"
    assert_hook_allowed "git status is allowed"
}

test_allow_git_log() {
    invoke_bash_hook "git log --oneline -10"
    assert_hook_allowed "git log is allowed"
}

test_allow_git_diff() {
    invoke_bash_hook "git diff HEAD~1"
    assert_hook_allowed "git diff is allowed"
}

test_allow_git_add() {
    invoke_bash_hook "git add ."
    assert_hook_allowed "git add is allowed"
}

test_allow_git_commit() {
    invoke_bash_hook "git commit -m 'message'"
    assert_hook_allowed "git commit is allowed"
}

test_allow_git_branch() {
    invoke_bash_hook "git branch -a"
    assert_hook_allowed "git branch is allowed"
}

test_allow_git_checkout_branch() {
    invoke_bash_hook "git checkout feature-branch"
    assert_hook_allowed "git checkout branch is allowed"
}

test_allow_git_fetch() {
    invoke_bash_hook "git fetch origin"
    assert_hook_allowed "git fetch is allowed"
}

test_allow_git_pull() {
    invoke_bash_hook "git pull origin main"
    assert_hook_allowed "git pull is allowed"
}

test_allow_git_stash() {
    invoke_bash_hook "git stash"
    assert_hook_allowed "git stash is allowed"
}

test_allow_git_show() {
    invoke_bash_hook "git show HEAD"
    assert_hook_allowed "git show is allowed"
}

# =============================================================================
# Build commands
# =============================================================================

test_allow_npm_install() {
    invoke_bash_hook "npm install"
    assert_hook_allowed "npm install is allowed"
}

test_allow_npm_run() {
    invoke_bash_hook "npm run build"
    assert_hook_allowed "npm run is allowed"
}

test_allow_npm_test() {
    invoke_bash_hook "npm test"
    assert_hook_allowed "npm test is allowed"
}

test_allow_yarn_install() {
    invoke_bash_hook "yarn install"
    assert_hook_allowed "yarn install is allowed"
}

test_allow_yarn_build() {
    invoke_bash_hook "yarn build"
    assert_hook_allowed "yarn build is allowed"
}

test_allow_cargo_build() {
    invoke_bash_hook "cargo build --release"
    assert_hook_allowed "cargo build is allowed"
}

test_allow_cargo_test() {
    invoke_bash_hook "cargo test"
    assert_hook_allowed "cargo test is allowed"
}

test_allow_cargo_run() {
    invoke_bash_hook "cargo run"
    assert_hook_allowed "cargo run is allowed"
}

test_allow_pip_install() {
    invoke_bash_hook "pip install -r requirements.txt"
    assert_hook_allowed "pip install is allowed"
}

test_allow_python() {
    invoke_bash_hook "python script.py"
    assert_hook_allowed "python is allowed"
}

test_allow_pytest() {
    invoke_bash_hook "pytest tests/"
    assert_hook_allowed "pytest is allowed"
}

test_allow_make() {
    invoke_bash_hook "make build"
    assert_hook_allowed "make is allowed"
}

# =============================================================================
# Docker read-only operations
# =============================================================================

test_allow_docker_ps() {
    invoke_bash_hook "docker ps"
    assert_hook_allowed "docker ps is allowed"
}

test_allow_docker_images() {
    invoke_bash_hook "docker images"
    assert_hook_allowed "docker images is allowed"
}

test_allow_docker_logs() {
    invoke_bash_hook "docker logs mycontainer"
    assert_hook_allowed "docker logs is allowed"
}

test_allow_docker_build() {
    invoke_bash_hook "docker build -t myimage ."
    assert_hook_allowed "docker build is allowed"
}

test_allow_docker_run() {
    invoke_bash_hook "docker run -it ubuntu bash"
    assert_hook_allowed "docker run is allowed"
}

test_allow_docker_exec() {
    invoke_bash_hook "docker exec -it container bash"
    assert_hook_allowed "docker exec is allowed"
}

test_allow_docker_inspect() {
    invoke_bash_hook "docker inspect container"
    assert_hook_allowed "docker inspect is allowed"
}

test_allow_docker_compose_up() {
    invoke_bash_hook "docker-compose up -d"
    assert_hook_allowed "docker-compose up is allowed"
}

test_allow_docker_compose_logs() {
    invoke_bash_hook "docker-compose logs -f"
    assert_hook_allowed "docker-compose logs is allowed"
}

# =============================================================================
# Database read operations
# =============================================================================

test_allow_psql_select() {
    invoke_bash_hook "psql -c 'SELECT * FROM users'"
    assert_hook_allowed "SELECT is allowed"
}

test_allow_sqlite_query() {
    invoke_bash_hook "sqlite3 test.db 'SELECT COUNT(*) FROM orders'"
    assert_hook_allowed "sqlite SELECT is allowed"
}

test_allow_mysql_select() {
    invoke_bash_hook "mysql -e 'SELECT * FROM users'"
    assert_hook_allowed "mysql SELECT is allowed"
}

# =============================================================================
# Kubernetes read operations
# =============================================================================

test_allow_kubectl_get() {
    invoke_bash_hook "kubectl get pods"
    assert_hook_allowed "kubectl get is allowed"
}

test_allow_kubectl_describe() {
    invoke_bash_hook "kubectl describe pod mypod"
    assert_hook_allowed "kubectl describe is allowed"
}

test_allow_kubectl_logs() {
    invoke_bash_hook "kubectl logs mypod"
    assert_hook_allowed "kubectl logs is allowed"
}

test_allow_helm_list() {
    invoke_bash_hook "helm list"
    assert_hook_allowed "helm list is allowed"
}

# =============================================================================
# Run all tests
# =============================================================================

# Basic commands
test_allow_ls
test_allow_cat
test_allow_grep
test_allow_find
test_allow_pwd
test_allow_echo
test_allow_head
test_allow_tail
test_allow_wc

# Git
test_allow_git_status
test_allow_git_log
test_allow_git_diff
test_allow_git_add
test_allow_git_commit
test_allow_git_branch
test_allow_git_checkout_branch
test_allow_git_fetch
test_allow_git_pull
test_allow_git_stash
test_allow_git_show

# Build
test_allow_npm_install
test_allow_npm_run
test_allow_npm_test
test_allow_yarn_install
test_allow_yarn_build
test_allow_cargo_build
test_allow_cargo_test
test_allow_cargo_run
test_allow_pip_install
test_allow_python
test_allow_pytest
test_allow_make

# Docker
test_allow_docker_ps
test_allow_docker_images
test_allow_docker_logs
test_allow_docker_build
test_allow_docker_run
test_allow_docker_exec
test_allow_docker_inspect
test_allow_docker_compose_up
test_allow_docker_compose_logs

# Database
test_allow_psql_select
test_allow_sqlite_query
test_allow_mysql_select

# Kubernetes
test_allow_kubectl_get
test_allow_kubectl_describe
test_allow_kubectl_logs
test_allow_helm_list
