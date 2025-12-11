---
name: task-done
description: Mark current task complete
usage: /task-done COMPOSITE_ID
---

## Arguments

- `COMPOSITE_ID`: Task identifier in format `STORY.TASK` (e.g., `11.3`)

## Instructions

Source the shell library:
```bash
source lib/config.sh
source lib/backlog.sh
```

Parse the composite ID:
```bash
story_id="${COMPOSITE_ID%%.*}"
task_id="${COMPOSITE_ID##*.}"
```

Mark the task done:
```bash
backlog_set_task_status "$story_id" "$task_id" "$STATUS_DONE"
```

Recompute story status:
```bash
backlog_recompute_story_status "$story_id"
```

Update version:
```bash
backlog_touch "$(git config user.email)"
```

Report result:
```
Completed task 11.3: "Implement lib/backlog.sh core functions"
Story 11 status: in_progress (7/10 tasks done)
```
