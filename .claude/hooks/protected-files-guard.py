#!/usr/bin/env python3
"""
protected-files-guard.py - PreToolUse hook for Edit/Write/MultiEdit tools
Blocks modifications to sensitive files, requires confirmation for certain file types.

Exit codes:
    0 (no output)   = Allow
    0 (with JSON)   = Ask for confirmation
    2 (with stderr) = Block
    1               = Hook error (non-blocking)
"""
import json
import sys

# =============================================================================
# Constants: ALWAYS_BLOCK (Never Modify)
# =============================================================================

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

# =============================================================================
# Constants: REQUIRE_CONFIRMATION
# =============================================================================

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

# =============================================================================
# Main
# =============================================================================

def main() -> None:
    try:
        data = json.load(sys.stdin)
        tool_input = data.get('tool_input', {})

        # Handle both file_path and path fields
        file_path = tool_input.get('file_path', '') or tool_input.get('path', '')

        # If no file_path found, allow (fail-open for malformed input)
        if not file_path:
            sys.exit(0)

        # Check ALWAYS_BLOCK first
        for pattern in ALWAYS_BLOCK:
            if pattern in file_path:
                print(
                    f"🛑 BLOCKED: Modifications to '{file_path}' are never allowed. "
                    f"Matched pattern: '{pattern}'",
                    file=sys.stderr
                )
                sys.exit(2)

        # Check REQUIRE_CONFIRMATION
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

        # Allow by default
        sys.exit(0)

    except json.JSONDecodeError as e:
        print(f"Hook error: Invalid JSON input - {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Hook error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
