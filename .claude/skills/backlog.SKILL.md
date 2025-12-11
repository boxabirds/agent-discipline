---
description: >
  Manages tasks and project tracking with JSON backlog. Use this skill when
  the user wants to: see what work is available, claim or start working on
  a task, check current task, mark work as done or complete, view task status,
  sync or share their backlog progress, push changes upstream, or asks about
  their backlog, todos, or work items.
---

# Task Workflow

This skill helps manage work through a local JSON backlog at `delivery/backlog.json`.

## Available Actions

| Action | Trigger Phrases |
|:-------|:----------------|
| List Stories | "what stories", "show backlog", "all stories" |
| List Tasks | "what's available", "show tasks", "tasks for story X" |
| Claim Task | "I'll take", "work on", "claim", "start" |
| Complete | "done", "finished", "mark complete" |
| Status | "task status", "progress", "where are we" |
| Sync | "sync the backlog", "push my progress", "share changes" |

---

## Listing Stories

When user wants to see all stories:

### Recognition
- "what stories are there?"
- "show me the backlog"
- "list all stories"

### Action
```bash
source lib/config.sh
source lib/backlog.sh
backlog_list_stories
```

### Response Template
"Here are the stories:

| ID | Title | Status | Progress |
|----|-------|--------|----------|
| 11 | Migrate to backlog.json | in_progress | 3/10 |

Use `/task-list 11` to see tasks for a story."

---

## Listing Tasks

When user wants to see tasks for a story:

### Recognition
- "tasks for story 11"
- "what tasks in story 11"
- "/task-list 11"

### Action
```bash
source lib/config.sh
source lib/backlog.sh
backlog_list_tasks 11
```

### Response Template
"Tasks for Story 11: Migrate to backlog.json

| ID | Title | Status | Assignee |
|----|-------|--------|----------|
| 11.1 | Delete GitHub code | done | user@example.com |
| 11.2 | Define JSON schema | in_progress | user@example.com |
| 11.3 | Implement backlog.sh | proposed | - |

Claim with `/task-claim 11.3`"

---

## Claiming Tasks

When user wants to start work:

### Recognition
- "I'll take 11.3"
- "claim task 11.3"
- "/task-claim 11.3"

### Action
```bash
source lib/config.sh
source lib/backlog.sh
backlog_claim_task 11 3 "$(git config user.email)"
```

### Response Template
"Claimed task 11.3: Implement lib/backlog.sh core functions
Assigned to: user@example.com
Status: in_progress"

---

## Completing Tasks

When user indicates work is done:

### Recognition
- "done with 11.3"
- "finished 11.3"
- "/task-done 11.3"

### Action
```bash
source lib/config.sh
source lib/backlog.sh
backlog_set_task_status 11 3 "done"
backlog_recompute_story_status 11
backlog_touch "$(git config user.email)"
```

### Response Template
"Completed task 11.3: Implement lib/backlog.sh core functions
Story 11 progress: 4/10 tasks done"

---

## Status Overview

When user wants a summary:

### Recognition
- "where are we?"
- "project status"
- "what's the progress?"

### Action
```bash
source lib/config.sh
source lib/backlog.sh
backlog_list_stories
```

### Response Template
"Project Status:

Stories:
- Story 11: Migrate to backlog.json [in_progress] - 4/10 tasks

In Progress Tasks:
- 11.4: Update slash commands (assigned to you)

Ready to claim:
- 11.5: Create sync-backlog.sh script"

---

## Syncing Backlog

When user wants to share their backlog progress upstream:

### Recognition
- "sync the backlog"
- "push my progress"
- "share backlog changes"
- "sync to upstream"
- "update the team backlog"

### Action

1. Check for uncommitted backlog changes:
```bash
git diff --name-only delivery/backlog.json
```

2. If changes exist, commit them:
```bash
git add delivery/backlog.json
git commit -m "Update backlog.json

$(jq -r '.stories[] | select(.status == "in_progress") | "- \(.title): in progress"' delivery/backlog.json)

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

3. Push to origin:
```bash
git push origin HEAD
```

4. Check for existing PR, create if needed:
```bash
# Check if PR exists
gh pr list --head "$(git branch --show-current)" --state open

# If no PR, create one
gh pr create --title "Backlog sync: $(date +%Y-%m-%d)" --body "Syncing backlog.json changes.

🤖 Generated with [Claude Code](https://claude.com/claude-code)"
```

### Response Template
"Synced backlog to upstream:
- Committed: abc1234
- Pushed to origin/feature-branch
- PR: https://github.com/owner/repo/pull/42

Changes will be merged when PR is approved."

### Already Synced
"Backlog is already in sync - no uncommitted changes and branch is up to date."

---

## Error Responses

### Backlog Not Found
"No backlog found at delivery/backlog.json.

Run `/task-init` to create one."

### Task Not Found
"Task 11.99 not found.

Use `/task-list 11` to see available tasks."

### Already Claimed
"Task 11.3 is already assigned to other@example.com."

---

## Unknown Intent Fallback

"I can help you manage tasks. Here's what I can do:

**View**: `/task-list` or `/task-list 11`
**Claim**: `/task-claim 11.3`
**Complete**: `/task-done 11.3`

What would you like to do?"
