---
name: task-create
description: Create new story or task
usage: /task-create [--story] TITLE or /task-create STORY_ID TITLE
---

## Creating a Story

```bash
/task-create --story "New feature implementation"
```

## Creating a Task

```bash
/task-create 11 "Write unit tests"
```

## Instructions

Source the shell library:
```bash
source lib/config.sh
source lib/backlog.sh
```

### Creating a Story

If `--story` flag present:
```bash
story_id=$(backlog_add_story "$TITLE")
```

Creates story with next available ID, status=proposed.

### Creating a Task (Rich Fields)

If STORY_ID provided, gather task details:

1. **Title** (required): Already provided in command
2. **Scope** (optional): Ask user:
   - "What's in scope for this task?"
   - "What's explicitly out of scope?"
3. **Files** (optional): Ask user:
   - "What files will be modified?"
4. **Implementation** (optional): Ask user:
   - "What are the implementation steps?"
5. **Testing** (optional): Ask user:
   - "What domains/input categories need testing?"
   - "What edge cases should be covered?"
   - "Any WAV files to validate?"

Build extras JSON from answers:
```bash
extras='{
  "scope": {"in": ["..."], "out": ["..."]},
  "implementation": ["Step 1", "Step 2"],
  "testing": {"domains": [], "edges": [], "wavs": []}
}'
```

Create task with rich fields:
```bash
task_id=$(backlog_add_task "$STORY_ID" "$TITLE" "$FILES" "$extras")
```

For quick task creation without prompts, pass empty extras:
```bash
task_id=$(backlog_add_task "$STORY_ID" "$TITLE")
```

Use `/task-edit` to add rich fields later.

### Report Result

```
Created story 12: "New feature implementation"
```
or
```
Created task 11.4: "Write unit tests"
```
