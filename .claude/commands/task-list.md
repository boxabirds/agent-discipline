---
name: task-list
description: List tasks
usage: /task-list [STORY_ID] [--mine] [--status STATUS]
---

## Options

- `STORY_ID`: Show tasks for specific story (e.g., `11`)
- `--mine`: Show only tasks assigned to you
- `--status`: Filter by status (proposed, in_progress, done)

## Instructions

Source the shell library:
```bash
source lib/config.sh
source lib/backlog.sh
```

### List all stories

If no STORY_ID provided:
```bash
backlog_list_stories
```

Format output:
```
ID | Title | Status | Tasks
11 | Migrate to backlog.json | in_progress | 3/10 done
```

### List tasks for a story

If STORY_ID provided:
```bash
backlog_list_tasks "$STORY_ID"
```

Format output:
```
ID | Title | Status | Assignee
11.1 | Delete GitHub code | done | user@example.com
11.2 | Define JSON schema | in_progress | user@example.com
11.3 | Implement backlog.sh | proposed | -
```

Apply filters:
- If `--mine`: filter to `assignee == $(git config user.email)`
- If `--status STATUS`: filter to matching status
