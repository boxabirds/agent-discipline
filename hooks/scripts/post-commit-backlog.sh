#!/usr/bin/env bash
# post-commit-backlog.sh - Remind user to sync backlog after committing changes
#
# This hook fires after Bash tool use. It checks if:
# 1. The command was a git commit
# 2. backlog.json was included in the commit
#
# If both true, it outputs a reminder to push/PR.
#
set -euo pipefail

BACKLOG_FILE="delivery/backlog.json"

# Read the tool input from stdin (Claude Code passes JSON)
INPUT=$(cat)

# Extract the command that was run
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# Check if it was a git commit command
if [[ ! "$COMMAND" =~ ^git[[:space:]]+commit ]]; then
    exit 0
fi

# Check if backlog.json was in the last commit
if ! git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | grep -q "$BACKLOG_FILE"; then
    exit 0
fi

# Get current branch and remote status
BRANCH=$(git branch --show-current 2>/dev/null)
AHEAD=$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo "?")

# Output reminder (this will be shown to Claude, who can relay to user)
cat <<EOF
---
BACKLOG_SYNC_REMINDER: backlog.json was committed.

Branch '$BRANCH' is $AHEAD commit(s) ahead of origin.

To share your progress:
- Push: git push origin HEAD
- Or say: "sync the backlog"
---
EOF
