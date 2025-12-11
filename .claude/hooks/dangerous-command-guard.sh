#!/usr/bin/env bash
# dangerous-command-guard.sh - PreToolUse hook for Bash tool
# Blocks dangerous commands, requires confirmation for risky ones
#
# Exit codes:
#   0 (no output)  = Allow
#   0 (with JSON)  = Ask for confirmation
#   2 (with stderr) = Block
set -euo pipefail

# =============================================================================
# Constants: DENY_PATTERNS (Hard Block - NEVER allowed)
# =============================================================================

readonly -a DENY_PATTERNS=(
    # Filesystem destruction
    'rm\s+-rf\s+/'
    'rm\s+-rf\s+\*'
    'rm\s+-rf\s+~'
    '>\s*/dev/sd'
    'mkfs'
    'dd\s+if=.*of=/dev/'

    # Git disasters
    'git\s+reset\s+--hard\s+origin'
    'git\s+push.*--force.*main'
    'git\s+push.*--force.*master'
    'git\s+push.*-f.*main'
    'git\s+push.*-f.*master'

    # Database destruction
    'DROP\s+DATABASE'
    'DROP\s+SCHEMA.*CASCADE'
    'TRUNCATE.*CASCADE'

    # Docker nuclear options
    'docker\s+system\s+prune\s+-a.*--volumes'
    'docker\s+system\s+prune.*--volumes.*-a'
    'docker\s+volume\s+prune\s+-f'
    'docker\s+volume\s+prune\s+--force'

    # Shell bypass of ALWAYS_BLOCK files (prevents using Bash to modify protected files)
    # .env files
    '(echo|cat|printf)\s+.*>\s*.*\.env'
    'tee\s+.*\.env'
    'sed\s+-i.*\.env'
    'ed\s+.*\.env'
    '(cp|mv)\s+.*\s+.*\.env'
    # Private keys
    '(echo|cat|printf)\s+.*>\s*.*\.(pem|key)'
    '(echo|cat|printf)\s+.*>\s*.*id_(rsa|ed25519)'
    'tee\s+.*(\.pem|\.key|id_rsa|id_ed25519)'
    'sed\s+-i.*(\.pem|\.key|id_rsa|id_ed25519)'
    '(cp|mv)\s+.*\s+.*(\.pem|\.key|id_rsa|id_ed25519)'
    # Secrets files
    '(echo|cat|printf)\s+.*>\s*.*(secrets\.(yml|yaml)|credentials\.json|service-account\.json)'
    'tee\s+.*(secrets\.(yml|yaml)|credentials\.json|service-account\.json)'
    'sed\s+-i.*(secrets\.(yml|yaml)|credentials\.json|service-account\.json)'
    '(cp|mv)\s+.*\s+.*(secrets\.(yml|yaml)|credentials\.json|service-account\.json)'
    # Git/SSH config
    '(echo|cat|printf)\s+.*>\s*.*\.git/config'
    '(echo|cat|printf)\s+.*>\s*.*\.ssh/'
    'sed\s+-i.*\.(git/config|ssh/)'
)

# =============================================================================
# Constants: ASK_PATTERNS (Require Confirmation)
# =============================================================================

readonly -a ASK_PATTERNS=(
    # File deletion
    'rm\s+-rf'
    'rm\s+-r'
    'rm\s+.*\*'

    # Git operations that push/modify remote
    'git\s+push'
    'git\s+reset\s+--hard'
    'git\s+clean\s+-fd'
    'git\s+checkout\s+--\s+\.'

    # Package publishing
    'npm\s+publish'
    'yarn\s+publish'
    'pip\s+upload'
    'cargo\s+publish'

    # Docker - volume/data destruction
    'docker-compose\s+down.*-v'
    'docker-compose\s+down.*--volumes'
    'docker\s+compose\s+down.*-v'
    'docker\s+compose\s+down.*--volumes'
    'docker\s+volume\s+rm'
    'docker\s+volume\s+prune'
    'docker\s+system\s+prune'
    'docker\s+rm.*-v'
    'docker\s+rm.*--volumes'
    'docker\s+container\s+prune'
    'docker\s+image\s+prune\s+-a'

    # Docker - stopping/removing services with data
    'docker\s+stop'
    'docker\s+kill'
    'docker-compose\s+down'
    'docker\s+compose\s+down'

    # Database operations
    'DROP\s+TABLE'
    'TRUNCATE'
    'DELETE\s+FROM.*WHERE\s+1=1'
    'DELETE\s+FROM[^W]*$'

    # Service restarts
    'systemctl\s+stop'
    'systemctl\s+restart'
    'service\s+.*\s+stop'

    # Kubernetes
    'kubectl\s+delete'
    'kubectl\s+drain'
    'helm\s+uninstall'

    # Shell bypass of REQUIRE_CONFIRMATION files
    # Lock files
    '(echo|cat|printf)\s+.*>\s*.*(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)'
    'tee\s+.*(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)'
    'sed\s+-i.*(package-lock\.json|yarn\.lock|pnpm-lock\.yaml)'
    # Docker files
    '(echo|cat|printf)\s+.*>\s*.*(Dockerfile|docker-compose\.(yml|yaml))'
    'tee\s+.*(Dockerfile|docker-compose\.(yml|yaml))'
    'sed\s+-i.*(Dockerfile|docker-compose\.(yml|yaml))'
    # CI/CD files
    '(echo|cat|printf)\s+.*>\s*.*\.github/'
    '(echo|cat|printf)\s+.*>\s*.*\.gitlab-ci\.yml'
    'sed\s+-i.*\.(github/|gitlab-ci\.yml)'
    # Build config
    '(echo|cat|printf)\s+.*>\s*.*(Makefile|tsconfig\.json|pyproject\.toml|Cargo\.toml)'
    'tee\s+.*(Makefile|tsconfig\.json|pyproject\.toml|Cargo\.toml)'
    'sed\s+-i.*(Makefile|tsconfig\.json|pyproject\.toml|Cargo\.toml)'
    # Claude config
    '(echo|cat|printf)\s+.*>\s*.*\.claude/'
    'tee\s+.*\.claude/'
    'sed\s+-i.*\.claude/'
)

# =============================================================================
# Helper Functions
# =============================================================================

# Truncate command for display (max 60 chars)
truncate_command() {
    local cmd="$1"
    local max_len=60
    if [[ ${#cmd} -gt $max_len ]]; then
        echo "${cmd:0:$max_len}..."
    else
        echo "$cmd"
    fi
}

# Output block message to stderr
block_command() {
    local pattern="$1"
    local command="$2"
    local truncated
    truncated=$(truncate_command "$command")

    cat >&2 <<EOF
╔═══════════════════════════════════════════════════════════════════╗
║  🛑 BLOCKED: Dangerous command pattern detected                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  Pattern: $pattern
║  Command: $truncated
║                                                                   ║
║  This command is NEVER allowed, even with confirmation.           ║
║  If you really need to do this, run it manually in a terminal.    ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    exit 2
}

# Output ask JSON to stdout
ask_confirmation() {
    local pattern="$1"
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "⚠️  This command matches a sensitive pattern ('$pattern') and requires explicit confirmation before running."
  }
}
EOF
    exit 0
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Read JSON from stdin
    local input
    input=$(cat)

    # Parse command from JSON using jq
    # Handle missing command gracefully (fail-open)
    local command
    command=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || true

    # If no command found, allow (fail-open for malformed input)
    if [[ -z "$command" ]]; then
        exit 0
    fi

    # Check DENY_PATTERNS first (hard block)
    for pattern in "${DENY_PATTERNS[@]}"; do
        if echo "$command" | grep -Eiq "$pattern"; then
            block_command "$pattern" "$command"
        fi
    done

    # Check ASK_PATTERNS (require confirmation)
    for pattern in "${ASK_PATTERNS[@]}"; do
        if echo "$command" | grep -Eiq "$pattern"; then
            ask_confirmation "$pattern"
        fi
    done

    # Allow by default
    exit 0
}

main "$@"
