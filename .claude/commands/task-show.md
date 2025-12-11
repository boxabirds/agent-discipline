---
name: task-show
description: Show full task detail
usage: /task-show STORY.TASK
---

## Showing Task Details

```bash
/task-show 11.3
```

## Instructions

Source the shell library:
```bash
source lib/config.sh
source lib/backlog.sh
```

### Parse Composite ID

Extract story and task IDs:
```bash
STORY_ID="${COMPOSITE_ID%%.*}"
TASK_ID="${COMPOSITE_ID##*.}"
```

### Display Task Detail

Call the formatter:
```bash
backlog_format_task_detail "$STORY_ID" "$TASK_ID"
```

This outputs markdown with:
- Title, status, assignee
- Files list
- Scope (in/out)
- Implementation steps
- Testing strategy (domains, edges, WAVs)

### Handle Missing Task

If task not found, display error and list available tasks in that story:
```bash
backlog_format_tasks "$STORY_ID"
```
