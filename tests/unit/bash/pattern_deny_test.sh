#!/usr/bin/env bash
# pattern_deny_test.sh - Test DENY patterns in dangerous-command-guard.sh
# These commands should ALWAYS be blocked (exit 2)

echo "# DENY Pattern Tests"

# =============================================================================
# Filesystem destruction
# =============================================================================

test_deny_rm_rf_root() {
    invoke_bash_hook "rm -rf /"
    assert_hook_blocked "rm -rf / is blocked"
}

test_deny_rm_rf_star() {
    invoke_bash_hook "rm -rf *"
    assert_hook_blocked "rm -rf * is blocked"
}

test_deny_rm_rf_home() {
    invoke_bash_hook "rm -rf ~"
    assert_hook_blocked "rm -rf ~ is blocked"
}

test_deny_redirect_to_device() {
    invoke_bash_hook "echo garbage > /dev/sda"
    assert_hook_blocked "redirect to /dev/sd is blocked"
}

test_deny_mkfs() {
    invoke_bash_hook "mkfs.ext4 /dev/sda1"
    assert_hook_blocked "mkfs is blocked"
}

test_deny_dd_to_device() {
    invoke_bash_hook "dd if=/dev/zero of=/dev/sda"
    assert_hook_blocked "dd to device is blocked"
}

# =============================================================================
# Git disasters
# =============================================================================

test_deny_git_reset_hard_origin() {
    invoke_bash_hook "git reset --hard origin/main"
    assert_hook_blocked "git reset --hard origin is blocked"
}

test_deny_force_push_main() {
    invoke_bash_hook "git push --force origin main"
    assert_hook_blocked "git push --force main is blocked"
}

test_deny_force_push_main_short() {
    invoke_bash_hook "git push -f origin main"
    assert_hook_blocked "git push -f main is blocked"
}

test_deny_force_push_master() {
    invoke_bash_hook "git push --force origin master"
    assert_hook_blocked "git push --force master is blocked"
}

test_deny_force_push_master_short() {
    invoke_bash_hook "git push -f origin master"
    assert_hook_blocked "git push -f master is blocked"
}

# =============================================================================
# Database destruction
# =============================================================================

test_deny_drop_database() {
    invoke_bash_hook "psql -c 'DROP DATABASE production'"
    assert_hook_blocked "DROP DATABASE is blocked"
}

test_deny_drop_schema_cascade() {
    invoke_bash_hook "psql -c 'DROP SCHEMA public CASCADE'"
    assert_hook_blocked "DROP SCHEMA CASCADE is blocked"
}

test_deny_truncate_cascade() {
    invoke_bash_hook "psql -c 'TRUNCATE users CASCADE'"
    assert_hook_blocked "TRUNCATE CASCADE is blocked"
}

# =============================================================================
# Docker nuclear options
# =============================================================================

test_deny_docker_system_prune_all_volumes() {
    invoke_bash_hook "docker system prune -a --volumes"
    assert_hook_blocked "docker system prune -a --volumes is blocked"
}

test_deny_docker_system_prune_volumes_all() {
    invoke_bash_hook "docker system prune --volumes -a"
    assert_hook_blocked "docker system prune --volumes -a is blocked"
}

test_deny_docker_volume_prune_force() {
    invoke_bash_hook "docker volume prune -f"
    assert_hook_blocked "docker volume prune -f is blocked"
}

test_deny_docker_volume_prune_force_long() {
    invoke_bash_hook "docker volume prune --force"
    assert_hook_blocked "docker volume prune --force is blocked"
}

# =============================================================================
# Shell bypass of protected files - ALWAYS_BLOCK files via Bash
# These catch agents trying to modify protected files using shell commands
# instead of Edit/Write tools (which are caught by protected-files-guard.py)
# =============================================================================

# --- .env files ---
test_deny_echo_to_env() {
    invoke_bash_hook 'echo "SECRET=value" >> .env'
    assert_hook_blocked "echo >> .env is blocked"
}

test_deny_cat_heredoc_to_env() {
    invoke_bash_hook 'cat > .env << EOF
API_KEY=secret
EOF'
    assert_hook_blocked "cat heredoc > .env is blocked"
}

test_deny_tee_to_env() {
    invoke_bash_hook 'echo "SECRET=x" | tee .env'
    assert_hook_blocked "tee .env is blocked"
}

test_deny_sed_i_env() {
    invoke_bash_hook 'sed -i "s/old/new/" .env'
    assert_hook_blocked "sed -i .env is blocked"
}

test_deny_sed_inplace_env() {
    invoke_bash_hook "sed -i '' 's/old/new/' .env.local"
    assert_hook_blocked "sed -i .env.local is blocked"
}

test_deny_ed_env() {
    invoke_bash_hook 'ed .env'
    assert_hook_blocked "ed .env is blocked"
}

test_deny_cp_to_env() {
    invoke_bash_hook 'cp something .env'
    assert_hook_blocked "cp to .env is blocked"
}

test_deny_mv_to_env() {
    invoke_bash_hook 'mv something .env.production'
    assert_hook_blocked "mv to .env.production is blocked"
}

# --- Private keys ---
test_deny_echo_to_pem() {
    invoke_bash_hook 'echo "-----BEGIN PRIVATE KEY-----" > server.pem'
    assert_hook_blocked "echo > .pem is blocked"
}

test_deny_tee_to_key() {
    invoke_bash_hook 'cat private.key.bak | tee private.key'
    assert_hook_blocked "tee private.key is blocked"
}

test_deny_cp_to_id_rsa() {
    invoke_bash_hook 'cp backup ~/.ssh/id_rsa'
    assert_hook_blocked "cp to id_rsa is blocked"
}

test_deny_echo_to_id_ed25519() {
    invoke_bash_hook 'echo "key" >> ~/.ssh/id_ed25519'
    assert_hook_blocked "echo >> id_ed25519 is blocked"
}

# --- Secrets files ---
test_deny_cat_to_secrets_yml() {
    invoke_bash_hook 'cat > secrets.yml << EOF
password: hunter2
EOF'
    assert_hook_blocked "cat heredoc > secrets.yml is blocked"
}

test_deny_sed_secrets_yaml() {
    invoke_bash_hook 'sed -i "s/old/new/" config/secrets.yaml'
    assert_hook_blocked "sed -i secrets.yaml is blocked"
}

test_deny_tee_credentials_json() {
    invoke_bash_hook 'echo "{}" | tee credentials.json'
    assert_hook_blocked "tee credentials.json is blocked"
}

test_deny_cp_service_account() {
    invoke_bash_hook 'cp template.json service-account.json'
    assert_hook_blocked "cp to service-account.json is blocked"
}

# --- Git/SSH config ---
test_deny_echo_to_git_config() {
    invoke_bash_hook 'echo "[user]" >> .git/config'
    assert_hook_blocked "echo >> .git/config is blocked"
}

test_deny_sed_ssh_config() {
    invoke_bash_hook 'sed -i "s/Host/Host new/" .ssh/config'
    assert_hook_blocked "sed -i .ssh/config is blocked"
}

# =============================================================================
# Run all tests
# =============================================================================

# Filesystem
test_deny_rm_rf_root
test_deny_rm_rf_star
test_deny_rm_rf_home
test_deny_redirect_to_device
test_deny_mkfs
test_deny_dd_to_device

# Git
test_deny_git_reset_hard_origin
test_deny_force_push_main
test_deny_force_push_main_short
test_deny_force_push_master
test_deny_force_push_master_short

# Database
test_deny_drop_database
test_deny_drop_schema_cascade
test_deny_truncate_cascade

# Docker
test_deny_docker_system_prune_all_volumes
test_deny_docker_system_prune_volumes_all
test_deny_docker_volume_prune_force
test_deny_docker_volume_prune_force_long

# Shell bypass - .env files
test_deny_echo_to_env
test_deny_cat_heredoc_to_env
test_deny_tee_to_env
test_deny_sed_i_env
test_deny_sed_inplace_env
test_deny_ed_env
test_deny_cp_to_env
test_deny_mv_to_env

# Shell bypass - private keys
test_deny_echo_to_pem
test_deny_tee_to_key
test_deny_cp_to_id_rsa
test_deny_echo_to_id_ed25519

# Shell bypass - secrets files
test_deny_cat_to_secrets_yml
test_deny_sed_secrets_yaml
test_deny_tee_credentials_json
test_deny_cp_service_account

# Shell bypass - git/ssh config
test_deny_echo_to_git_config
test_deny_sed_ssh_config
