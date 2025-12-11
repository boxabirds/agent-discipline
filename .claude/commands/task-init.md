---
name: task-init
description: Initialize backlog.json
usage: /task-init [--project NAME]
---

## Behavior

Creates `delivery/backlog.json` with empty structure if it doesn't exist.

## Instructions

Source the shell library:
```bash
source lib/config.sh
source lib/backlog.sh
```

Check if backlog exists:
```bash
if [[ -f "$BACKLOG_FILE" ]]; then
    echo "Backlog already exists at $BACKLOG_FILE"
    exit 0
fi
```

Initialize empty backlog:
```bash
backlog_init "${PROJECT_NAME:-claude-backlog}"
```

This creates:
```json
{
  "version": 0,
  "meta": {
    "project": "claude-backlog",
    "updated_by": null
  },
  "stories": []
}
```

Report result:
```
Initialized backlog at delivery/backlog.json
```
