
### Decision Making
- Take autonomous decisions unless explicitly asked for options
- Implement solutions directly rather than asking for permission at each step
- Only ask for clarification when there are critical ambiguities

### Date Accuracy
- **ALWAYS use the correct current date** when writing documentation, deployment instructions, or migration files
- The current date is shown in the environment info at the start of each conversation
- Accurate dates are critical for migration ordering and deployment history

### Error Handling - CRITICAL
- **NEVER provide mock responses when something fails**
- Always show REAL error messages with helpful context
- Let code fail naturally - real errors are valuable debugging information
- Include hints about potential causes when errors occur


# Backlog Management

This project uses Claude Backlog for task management via `delivery/backlog.json`.

## Slash Commands

- `/task-init` - Initialize project tracking
- `/task-list` - List stories and tasks
- `/task-claim <story>.<task>` - Claim a task (e.g., `/task-claim 3.2`)
- `/task-done` - Mark current task complete
- `/task-create` - Create new story or task

## Folder Structure

```
delivery/
├── backlog.json              # Task tracking (single source of truth)
└── uat/                      # UAT specs

docs/
├── stories/
│   └── <story-id>/
│       └── prd.md            # Product requirements
├── tech/
│   └── <story-id>/
│       └── design.md         # Technical design
└── worklog.md                # Chronological activity log (optional)
```

## PRD (`docs/stories/<id>/prd.md`)

Focus on business/user problem:
- Problem to solve
- Proposed solution
- UX design aspects
- Business rules, links to research/domain knowledge

**Template:**
```markdown
# Story <id>: <Title>

Navigation: [Design](../../tech/<id>/design.md)

## Problem Statement

<What problem does this solve? Who is affected?>

## Proposed Solution

<High-level approach. What will be built?>

## User Experience

<How will users interact with this? Include examples.>

## Out of Scope

<What this story does NOT cover.>
```

## Tech Design (`docs/tech/<id>/design.md`)

Write enough detail that implementation is mechanical.

**Header:**
```markdown
# Tech Design: <Title>

Navigation: [PRD](../../stories/<id>/prd.md)
```

**Must include:**
- 2-3 sentence plain English intro (user-visible problem + proposed solution)
- Affected components/modules/public APIs
- **Data model** - structs with fields, types, descriptions
- **Interface signatures** - function signatures, parameter types, return values, error enums
- **Algorithm sketch** - pseudocode for non-trivial flows
- Invariants, pre/post-conditions, error codes
- **Diagrams (Mermaid)** - component, sequence (golden/alternate/error paths)

**Template:**
```markdown
# Tech Design: <Title>

Navigation: [PRD](../../stories/<id>/prd.md)

## Overview

<2-3 sentences: what problem this solves and the approach.>

## Data Model

<Structs/types with fields, types, descriptions>

## Interface

<Function signatures, parameters, return values>

## Algorithm

<Pseudocode for non-trivial flows>

## Sequence Diagrams

<Mermaid diagrams for key flows>

## Error Handling

<Error cases and how they're handled>

## Testing Strategy

<How to test this implementation>
```

## Quick Start (new story)

1. Use `/task-create` to add story to `delivery/backlog.json`
2. Create `docs/stories/<id>/prd.md` using PRD template
3. Create `docs/tech/<id>/design.md` using design template
4. Use `/task-create` to add tasks under the story
5. Use `/task-claim` to start work

## Workflow

1. **Before claiming a task:** Read the PRD and design docs
2. **During implementation:** Update design doc if approach changes
3. **Before marking done:** Verify implementation matches design
4. **For architectural decisions:** Add to design doc or create ADR

## Work Log (Optional)

Maintain `docs/worklog.md` as a chronological log of activity and decisions.

Each entry should state *why* alongside the what:
```markdown
## 2024-01-15 14:30 UTC

Completed task 3.2 (implement user auth). Used JWT instead of sessions
because <reason>. See design doc section 4.2.
```
# Other requirements

- silent fallbacks mask bugs. NEVER DO FALLBACKS unless by design and explicitly signed off by a real human.
- A "fix" is defined as a change that has been tested successfully. Never say something is fixed without having it tested.
- when creating documents derived from the code base, always include references to file and line numbers for grounding.
- when responding to a question that involves a full code base scan, repeat the research until you don't find any more results. This can sometimes take 7 or more iterations.