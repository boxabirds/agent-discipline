# Claude Code Safety Hooks Plugin

A configurable safety net for Claude Code that blocks or requires confirmation for dangerous commands — even when running with `--dangerously-skip-permissions`.

## How It Works

### The Key Insight

Claude Code's permission processing order is:

> **PreToolUse Hook → Deny Rules → Allow Rules → Ask Rules → Permission Mode Check → canUseTool Callback → PostToolUse Hook**

Hooks execute **first**, before permission mode is checked. This means PreToolUse hooks can block operations even when `--dangerously-skip-permissions` (bypassPermissions mode) is active.

### Exit Codes

| Exit Code | Effect |
|-----------|--------|
| `0` | Success — tool proceeds (or JSON output is processed) |
| `2` | **Blocking error** — stops execution, stderr sent to Claude as feedback |
| Any other non-zero | Non-blocking error — shown to user in verbose mode, execution continues |

### Permission Decisions (JSON Output)

When exiting with code `0`, you can output JSON to control behaviour:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Reason shown to user"
  }
}
```

| Decision | Effect |
|----------|--------|
| `"allow"` | Bypass permission system, auto-approve |
| `"deny"` | Block the tool, reason sent to Claude |
| `"ask"` | Force user confirmation dialog |

### The Feedback Loop

`exit 2` blocks the command AND feeds your stderr message back to Claude, so it learns and adapts:

```
Claude: "I'll run npm install"
     ↓
Hook: exit 2 + "Use bun instead of npm"
     ↓
Claude: "I see npm is blocked. I'll use bun install instead"
     ↓
Hook: (no match, exits 0)
     ↓
Command runs ✅
```

---

## Plugin Structure

Hooks are distributed as part of **plugins** via the `/plugin` command:

```bash
# Add a marketplace (GitHub repo)
/plugin marketplace add user-or-org/repo-name

# Browse and install
/plugin install plugin-name@marketplace-name
```

### Directory Structure

```
safety-hooks-plugin/
├── .claude-plugin/
│   ├── manifest.json
│   └── marketplace.json      # If hosting your own marketplace
├── hooks/
│   ├── dangerous-command-guard.sh
│   └── protected-files-guard.py
├── README.md
└── LICENSE
```

### manifest.json

```json
{
  "name": "safety-guard",
  "version": "1.0.0",
  "description": "Blocks dangerous commands and protects sensitive files, even with --dangerously-skip-permissions",
  "author": "your-name",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "command": "./hooks/dangerous-command-guard.sh"
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "command": "./hooks/protected-files-guard.py"
      }
    ]
  }
}
```

### marketplace.json (if hosting your own marketplace)

```json
{
  "name": "your-org-marketplace",
  "description": "Internal plugins for your team",
  "plugins": [
    {
      "name": "safety-guard",
      "description": "Blocks dangerous commands and protects sensitive files",
      "path": "./safety-guard"
    }
  ]
}
```

---

## Hook Scripts

### hooks/dangerous-command-guard.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

cmd=$(jq -r '.tool_input.command // ""')

# =============================================================================
# HARD BLOCKS - These NEVER run, even with confirmation
# =============================================================================
deny_patterns=(
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
)

# =============================================================================
# ASK PATTERNS - Require explicit user confirmation
# =============================================================================
ask_patterns=(
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
    'DELETE\s+FROM[^W]*$'  # DELETE without WHERE
    
    # Service restarts
    'systemctl\s+stop'
    'systemctl\s+restart'
    'service\s+.*\s+stop'
    
    # Kubernetes
    'kubectl\s+delete'
    'kubectl\s+drain'
    'helm\s+uninstall'
)

# =============================================================================
# CHECK DENY PATTERNS (hard block)
# =============================================================================
for pat in "${deny_patterns[@]}"; do
    if echo "$cmd" | grep -Eiq "$pat"; then
        cat 1>&2 << EOF
╔═══════════════════════════════════════════════════════════════════╗
║  🛑 BLOCKED: Dangerous command pattern detected                   ║
╠═══════════════════════════════════════════════════════════════════╣
║  Pattern: $pat
║  Command: ${cmd:0:60}...
║                                                                   ║
║  This command is NEVER allowed, even with confirmation.           ║
║  If you really need to do this, run it manually in a terminal.    ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
        exit 2
    fi
done

# =============================================================================
# CHECK ASK PATTERNS (require confirmation)
# =============================================================================
for pat in "${ask_patterns[@]}"; do
    if echo "$cmd" | grep -Eiq "$pat"; then
        cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "⚠️  This command matches a sensitive pattern ('$pat') and requires explicit confirmation before running."
  }
}
EOF
        exit 0
    fi
done

# =============================================================================
# ALLOW - Command doesn't match any patterns
# =============================================================================
exit 0
```

### hooks/protected-files-guard.py

```python
#!/usr/bin/env python3
"""
Protects sensitive files from modification.
- ALWAYS_BLOCK: Files that can never be modified by Claude
- REQUIRE_CONFIRMATION: Files that require explicit user approval
"""
import sys
import json

# Files/patterns that are NEVER allowed to be modified
ALWAYS_BLOCK = [
    '.env',
    '.env.local',
    '.env.production',
    '.pem',
    '.key',
    'id_rsa',
    'id_ed25519',
    'secrets.yml',
    'secrets.yaml',
    'credentials.json',
    'service-account.json',
    '.git/config',
    '.ssh/',
]

# Files/patterns that require explicit confirmation
REQUIRE_CONFIRMATION = [
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml',
    'Dockerfile',
    'docker-compose.yml',
    'docker-compose.yaml',
    '.github/',
    '.gitlab-ci.yml',
    'Makefile',
    'tsconfig.json',
    'pyproject.toml',
    'Cargo.toml',
    '.claude/',
]

def main():
    try:
        data = json.load(sys.stdin)
        tool_input = data.get('tool_input', {})
        
        # Handle different tool input structures
        file_path = tool_input.get('file_path', '') or tool_input.get('path', '')
        
        # Check for hard blocks
        for pattern in ALWAYS_BLOCK:
            if pattern in file_path:
                print(
                    f"🛑 BLOCKED: Modifications to '{file_path}' are never allowed. "
                    f"Matched pattern: '{pattern}'",
                    file=sys.stderr
                )
                sys.exit(2)
        
        # Check for confirmation required
        for pattern in REQUIRE_CONFIRMATION:
            if pattern in file_path:
                output = {
                    "hookSpecificOutput": {
                        "hookEventName": "PreToolUse",
                        "permissionDecision": "ask",
                        "permissionDecisionReason": (
                            f"⚠️  Modifying '{file_path}' requires confirmation. "
                            f"This file matches sensitive pattern: '{pattern}'"
                        )
                    }
                }
                print(json.dumps(output))
                sys.exit(0)
        
        # No match - allow the operation
        sys.exit(0)
        
    except json.JSONDecodeError as e:
        print(f"Hook error: Invalid JSON input - {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

---

## Team Distribution

Add to your repository's `.claude/settings.json` for automatic installation:

```json
{
  "plugins": {
    "marketplaces": [
      "your-org/your-claude-plugins"
    ],
    "install": [
      "safety-guard@your-org/your-claude-plugins"
    ]
  }
}
```

When team members trust the repository folder, Claude Code automatically installs the specified plugins.

---

## Docker Data Loss: Why This Matters

Your colleague's Postgres data loss is a common scenario. Here are all the ways Docker can destroy data:

| Command | What It Does |
|---------|--------------|
| `docker-compose down -v` | Removes containers AND named/anonymous volumes |
| `docker-compose down --rmi all -v` | Nuclear - containers, networks, ALL images, AND volumes |
| `docker volume rm <name>` | Explicitly removes a specific volume |
| `docker volume prune` | Removes all "unused" volumes (stopped container = unused!) |
| `docker system prune -a --volumes` | Removes everything including all volumes |
| `docker rm -v <container>` | Removes container AND its anonymous volumes |

### The Sneaky One: Anonymous vs Named Volumes

```yaml
# DANGEROUS - anonymous volume, tied to container lifecycle
services:
  db:
    image: postgres
    volumes:
      - /var/lib/postgresql/data  # Anonymous!

# SAFE - named volume, persists independently  
services:
  db:
    image: postgres
    volumes:
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:  # Explicitly declared, survives container removal
```

With anonymous volumes, even `docker-compose down` followed by `docker-compose up` can orphan data.

---

## Known Issues & Caveats

### Folder Trust Bug

If you launch Claude Code with `--dangerously-skip-permissions` in a folder that was never explicitly trusted, hooks get skipped entirely. Always trust folders via the `/hooks` menu first.

### JSON Deny Sometimes Ignored

There are reports of `"permissionDecision": "deny"` being ignored in some versions. For reliable hard blocks, use `exit 2` with stderr message instead of JSON deny.

### Settings Reload Required

Changes to hooks in settings files don't take effect immediately in a running session. Review them via `/hooks` menu for changes to apply — this is a security feature.

---

## Community Marketplaces

| Marketplace | Focus |
|-------------|-------|
| Dan Ávila's | DevOps automation, documentation, project management, testing |
| Seth Hobson's | 80+ specialized sub-agents |
| `ccplugins/marketplace` | Curated collection |
| `zpaper-com/ClaudeKit` | Agents, commands, and hooks bundle |

### Discovery (With Caveats)

Third-party aggregators exist:
- `claudecodemarketplace.com`
- `claudecodeplugin.com`  
- `claudemarketplaces.com` (auto-scrapes GitHub hourly)

**⚠️ Security warning**: These are unverified. PromptArmor has documented real risks with malicious plugins bypassing permission guardrails.

---

## Installation

### As a Plugin (Recommended)

```bash
# Add your marketplace
/plugin marketplace add your-org/your-claude-plugins

# Install the safety guard
/plugin install safety-guard@your-org/your-claude-plugins
```

### Manual Setup (Alternative)

1. Create `.claude/hooks/` directory in your project
2. Copy the hook scripts and make them executable:
   ```bash
   chmod +x .claude/hooks/dangerous-command-guard.sh
   chmod +x .claude/hooks/protected-files-guard.py
   ```
3. Add to `.claude/settings.json`:
   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/dangerous-command-guard.sh"
             }
           ]
         },
         {
           "matcher": "Edit|Write|MultiEdit",
           "hooks": [
             {
               "type": "command",
               "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/protected-files-guard.py"
             }
           ]
         }
       ]
     }
   }
   ```
4. Restart Claude Code or review via `/hooks` menu

---

## Customisation

### Adding Package Manager Enforcement

To enforce bun over npm:

```bash
# Add to deny_patterns in dangerous-command-guard.sh for hard block
# OR add to ask_patterns for confirmation
# OR create a separate hook with helpful feedback:

if echo "$cmd" | grep -Eq '^\s*npm\s+'; then
    echo "This project uses bun, not npm. Use 'bun' instead (e.g., 'bun install', 'bun run dev')." >&2
    exit 2
fi
```

### Adding Project-Specific Protected Files

Edit `ALWAYS_BLOCK` or `REQUIRE_CONFIRMATION` lists in `protected-files-guard.py`.

### Adjusting Patterns

The regex patterns use extended grep (`grep -E`). Test patterns with:
```bash
echo "your command here" | grep -Eiq 'your\s+pattern'
echo $?  # 0 = matched, 1 = no match
```

---

## License

MIT — use freely, no warranty provided.
