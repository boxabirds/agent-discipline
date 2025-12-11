#!/usr/bin/env bash
# pattern_ask_test.sh - Test ASK patterns in dangerous-command-guard.sh
# These commands should require confirmation (exit 0 + JSON with "ask")

echo "# ASK Pattern Tests"

# =============================================================================
# File deletion
# =============================================================================

test_ask_rm_rf() {
    invoke_bash_hook "rm -rf node_modules"
    assert_hook_asks "rm -rf requires confirmation"
}

test_ask_rm_r() {
    invoke_bash_hook "rm -r build/"
    assert_hook_asks "rm -r requires confirmation"
}

test_ask_rm_glob() {
    invoke_bash_hook "rm *.log"
    assert_hook_asks "rm with glob requires confirmation"
}

# =============================================================================
# Git operations
# =============================================================================

test_ask_git_push() {
    invoke_bash_hook "git push origin feature"
    assert_hook_asks "git push requires confirmation"
}

test_ask_git_push_main_no_force() {
    # Without --force, pushing to main should ASK not BLOCK
    invoke_bash_hook "git push origin main"
    assert_hook_asks "git push to main (no force) requires confirmation"
}

test_ask_git_reset_hard() {
    invoke_bash_hook "git reset --hard HEAD~1"
    assert_hook_asks "git reset --hard requires confirmation"
}

test_ask_git_clean_fd() {
    invoke_bash_hook "git clean -fd"
    assert_hook_asks "git clean -fd requires confirmation"
}

test_ask_git_checkout_dot() {
    invoke_bash_hook "git checkout -- ."
    assert_hook_asks "git checkout -- . requires confirmation"
}

# =============================================================================
# Package publishing
# =============================================================================

test_ask_npm_publish() {
    invoke_bash_hook "npm publish"
    assert_hook_asks "npm publish requires confirmation"
}

test_ask_yarn_publish() {
    invoke_bash_hook "yarn publish"
    assert_hook_asks "yarn publish requires confirmation"
}

test_ask_pip_upload() {
    invoke_bash_hook "pip upload dist/*"
    assert_hook_asks "pip upload requires confirmation"
}

test_ask_cargo_publish() {
    invoke_bash_hook "cargo publish"
    assert_hook_asks "cargo publish requires confirmation"
}

# =============================================================================
# Docker operations
# =============================================================================

test_ask_docker_compose_down_v() {
    invoke_bash_hook "docker-compose down -v"
    assert_hook_asks "docker-compose down -v requires confirmation"
}

test_ask_docker_compose_down_volumes() {
    invoke_bash_hook "docker-compose down --volumes"
    assert_hook_asks "docker-compose down --volumes requires confirmation"
}

test_ask_docker_compose_v2_down_v() {
    invoke_bash_hook "docker compose down -v"
    assert_hook_asks "docker compose down -v requires confirmation"
}

test_ask_docker_volume_rm() {
    invoke_bash_hook "docker volume rm myvolume"
    assert_hook_asks "docker volume rm requires confirmation"
}

test_ask_docker_volume_prune() {
    # Without -f, this should ASK not BLOCK
    invoke_bash_hook "docker volume prune"
    assert_hook_asks "docker volume prune requires confirmation"
}

test_ask_docker_system_prune() {
    # Without -a --volumes, this should ASK not BLOCK
    invoke_bash_hook "docker system prune"
    assert_hook_asks "docker system prune requires confirmation"
}

test_ask_docker_rm_v() {
    invoke_bash_hook "docker rm -v container1"
    assert_hook_asks "docker rm -v requires confirmation"
}

test_ask_docker_container_prune() {
    invoke_bash_hook "docker container prune"
    assert_hook_asks "docker container prune requires confirmation"
}

test_ask_docker_image_prune_a() {
    invoke_bash_hook "docker image prune -a"
    assert_hook_asks "docker image prune -a requires confirmation"
}

test_ask_docker_stop() {
    invoke_bash_hook "docker stop mycontainer"
    assert_hook_asks "docker stop requires confirmation"
}

test_ask_docker_kill() {
    invoke_bash_hook "docker kill mycontainer"
    assert_hook_asks "docker kill requires confirmation"
}

test_ask_docker_compose_down() {
    invoke_bash_hook "docker-compose down"
    assert_hook_asks "docker-compose down requires confirmation"
}

# =============================================================================
# Database operations
# =============================================================================

test_ask_drop_table() {
    invoke_bash_hook "psql -c 'DROP TABLE users'"
    assert_hook_asks "DROP TABLE requires confirmation"
}

test_ask_truncate() {
    invoke_bash_hook "psql -c 'TRUNCATE audit_log'"
    assert_hook_asks "TRUNCATE requires confirmation"
}

test_ask_delete_where_1_eq_1() {
    invoke_bash_hook "psql -c 'DELETE FROM logs WHERE 1=1'"
    assert_hook_asks "DELETE FROM WHERE 1=1 requires confirmation"
}

test_ask_delete_no_where() {
    invoke_bash_hook "psql -c 'DELETE FROM logs'"
    assert_hook_asks "DELETE FROM (no WHERE) requires confirmation"
}

# =============================================================================
# Service control
# =============================================================================

test_ask_systemctl_stop() {
    invoke_bash_hook "systemctl stop nginx"
    assert_hook_asks "systemctl stop requires confirmation"
}

test_ask_systemctl_restart() {
    invoke_bash_hook "systemctl restart nginx"
    assert_hook_asks "systemctl restart requires confirmation"
}

test_ask_service_stop() {
    invoke_bash_hook "service nginx stop"
    assert_hook_asks "service stop requires confirmation"
}

# =============================================================================
# Kubernetes
# =============================================================================

test_ask_kubectl_delete() {
    invoke_bash_hook "kubectl delete pod mypod"
    assert_hook_asks "kubectl delete requires confirmation"
}

test_ask_kubectl_drain() {
    invoke_bash_hook "kubectl drain node1"
    assert_hook_asks "kubectl drain requires confirmation"
}

test_ask_helm_uninstall() {
    invoke_bash_hook "helm uninstall myrelease"
    assert_hook_asks "helm uninstall requires confirmation"
}

# =============================================================================
# Shell bypass of protected files - REQUIRE_CONFIRMATION files via Bash
# These catch agents trying to modify confirmation-required files using
# shell commands instead of Edit/Write tools
# =============================================================================

# --- Lock files ---
test_ask_echo_to_package_lock() {
    invoke_bash_hook 'echo "{}" >> package-lock.json'
    assert_hook_asks "echo >> package-lock.json requires confirmation"
}

test_ask_cat_to_yarn_lock() {
    invoke_bash_hook 'cat backup.lock > yarn.lock'
    assert_hook_asks "cat > yarn.lock requires confirmation"
}

test_ask_sed_pnpm_lock() {
    invoke_bash_hook 'sed -i "s/old/new/" pnpm-lock.yaml'
    assert_hook_asks "sed -i pnpm-lock.yaml requires confirmation"
}

# --- Docker files ---
test_ask_echo_to_dockerfile() {
    invoke_bash_hook 'echo "RUN apt-get update" >> Dockerfile'
    assert_hook_asks "echo >> Dockerfile requires confirmation"
}

test_ask_cat_to_docker_compose() {
    invoke_bash_hook 'cat template.yml > docker-compose.yml'
    assert_hook_asks "cat > docker-compose.yml requires confirmation"
}

test_ask_sed_docker_compose_yaml() {
    invoke_bash_hook 'sed -i "s/postgres:13/postgres:14/" docker-compose.yaml'
    assert_hook_asks "sed -i docker-compose.yaml requires confirmation"
}

# --- CI/CD files ---
test_ask_echo_to_github_workflow() {
    invoke_bash_hook 'echo "  - run: npm test" >> .github/workflows/ci.yml'
    assert_hook_asks "echo >> .github/ workflow requires confirmation"
}

test_ask_cat_to_gitlab_ci() {
    invoke_bash_hook 'cat ci-template.yml > .gitlab-ci.yml'
    assert_hook_asks "cat > .gitlab-ci.yml requires confirmation"
}

# --- Build config files ---
test_ask_echo_to_makefile() {
    invoke_bash_hook 'echo "test: pytest" >> Makefile'
    assert_hook_asks "echo >> Makefile requires confirmation"
}

test_ask_sed_tsconfig() {
    invoke_bash_hook 'sed -i "s/ES2020/ES2022/" tsconfig.json'
    assert_hook_asks "sed -i tsconfig.json requires confirmation"
}

test_ask_cat_to_pyproject() {
    invoke_bash_hook 'cat template.toml > pyproject.toml'
    assert_hook_asks "cat > pyproject.toml requires confirmation"
}

test_ask_tee_cargo_toml() {
    invoke_bash_hook 'echo "[package]" | tee Cargo.toml'
    assert_hook_asks "tee Cargo.toml requires confirmation"
}

# --- Claude config ---
test_ask_echo_to_claude_settings() {
    invoke_bash_hook 'echo "{}" > .claude/settings.json'
    assert_hook_asks "echo > .claude/settings.json requires confirmation"
}

test_ask_cat_to_claude_commands() {
    invoke_bash_hook 'cat template.md > .claude/commands/custom.md'
    assert_hook_asks "cat > .claude/commands/ requires confirmation"
}

# =============================================================================
# Run all tests
# =============================================================================

# File deletion
test_ask_rm_rf
test_ask_rm_r
test_ask_rm_glob

# Git
test_ask_git_push
test_ask_git_push_main_no_force
test_ask_git_reset_hard
test_ask_git_clean_fd
test_ask_git_checkout_dot

# Package publishing
test_ask_npm_publish
test_ask_yarn_publish
test_ask_pip_upload
test_ask_cargo_publish

# Docker
test_ask_docker_compose_down_v
test_ask_docker_compose_down_volumes
test_ask_docker_compose_v2_down_v
test_ask_docker_volume_rm
test_ask_docker_volume_prune
test_ask_docker_system_prune
test_ask_docker_rm_v
test_ask_docker_container_prune
test_ask_docker_image_prune_a
test_ask_docker_stop
test_ask_docker_kill
test_ask_docker_compose_down

# Database
test_ask_drop_table
test_ask_truncate
test_ask_delete_where_1_eq_1
test_ask_delete_no_where

# Service control
test_ask_systemctl_stop
test_ask_systemctl_restart
test_ask_service_stop

# Kubernetes
test_ask_kubectl_delete
test_ask_kubectl_drain
test_ask_helm_uninstall

# Shell bypass - lock files
test_ask_echo_to_package_lock
test_ask_cat_to_yarn_lock
test_ask_sed_pnpm_lock

# Shell bypass - Docker files
test_ask_echo_to_dockerfile
test_ask_cat_to_docker_compose
test_ask_sed_docker_compose_yaml

# Shell bypass - CI/CD files
test_ask_echo_to_github_workflow
test_ask_cat_to_gitlab_ci

# Shell bypass - build config
test_ask_echo_to_makefile
test_ask_sed_tsconfig
test_ask_cat_to_pyproject
test_ask_tee_cargo_toml

# Shell bypass - Claude config
test_ask_echo_to_claude_settings
test_ask_cat_to_claude_commands
