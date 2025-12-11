---
name: task-edit
description: Edit existing task fields
usage: /task-edit STORY.TASK [--scope|--impl|--testing|--files|--design]
---

## Editing Task Fields

```bash
/task-edit 11.3 --scope
/task-edit 11.3 --impl
/task-edit 11.3 --testing
/task-edit 11.3 --files
/task-edit 11.3 --design
/task-edit 11.3  # Show current, ask what to change
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

### Based on Flag

**`--design`**: Prompt user for:
- Which design doc sections does this task implement?
- e.g., "Section 4.2 - Error Handling", "Section 5.1 - Data Model"

Then call:
```bash
backlog_set_task_design_refs "$STORY_ID" "$TASK_ID" '["Section 4.2 - Error Handling", "Section 5.1 - Data Model"]'
```

**`--scope`**: Prompt user for:
- What's in scope? (list of items)
- What's out of scope? (list of items)

Then call:
```bash
backlog_set_task_scope "$STORY_ID" "$TASK_ID" '["item1", "item2"]' '["out1", "out2"]'
```

**`--impl`**: Prompt user for:
- Implementation steps (numbered list)

Then call:
```bash
backlog_set_task_implementation "$STORY_ID" "$TASK_ID" '["Step 1", "Step 2"]'
```

**`--testing`**: Prompt user for:
- Test domains (input categories)
- Edge cases to cover
- WAV files if applicable

Then call:
```bash
backlog_set_task_testing "$STORY_ID" "$TASK_ID" '["domain1"]' '["edge1"]' '["wav1"]'
```

**`--files`**: Prompt user for:
- Files to be modified (comma-separated)

Then call:
```bash
backlog_set_task_field "$STORY_ID" "$TASK_ID" "files" '["file1.rs", "file2.rs"]'
```

**No flag**: Show current task detail using `backlog_format_task_detail`, then ask what to change.

### Report Result

```
Updated task 11.3 design references
```
or
```
Updated task 11.3 scope
```
