---
name: task-claim
description: Claim a task to work on
usage: /task-claim COMPOSITE_ID
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
assignee=$(git config user.email)
```

Claim the task:
```bash
backlog_claim_task "$story_id" "$task_id" "$assignee"
```

This will:
1. Set task status to `in_progress`
2. Set task assignee
3. Update story status if needed (proposed -> in_progress)
4. Update backlog version timestamp

Report result to user:
```
Claimed task 11.3: "Implement lib/backlog.sh core functions"
Assigned to: user@example.com
```
