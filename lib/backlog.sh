#!/usr/bin/env bash
# backlog.sh - JSON backlog manipulation functions
set -euo pipefail

# Guard against double-sourcing
[[ -n "${_BACKLOG_SH_LOADED:-}" ]] && return 0
readonly _BACKLOG_SH_LOADED=1

# Source dependencies
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
source "$SCRIPT_DIR/config.sh"

# =============================================================================
# Initialization
# =============================================================================

# backlog_init(project_name)
# Create empty backlog.json if it doesn't exist
backlog_init() {
    local project_name="${1:-claude-backlog}"

    require_jq || return $?

    if [[ -f "$BACKLOG_FILE" ]]; then
        echo "Backlog already exists at $BACKLOG_FILE" >&2
        return 0
    fi

    mkdir -p "$(dirname "$BACKLOG_FILE")"
    cat > "$BACKLOG_FILE" <<EOF
{
  "version": 0,
  "meta": {
    "project": "$project_name",
    "updated_by": null
  },
  "stories": []
}
EOF
    echo "Created backlog at $BACKLOG_FILE"
}

# =============================================================================
# Read Operations
# =============================================================================

# backlog_read()
# Output entire backlog JSON
backlog_read() {
    require_jq || return $?

    if [[ ! -f "$BACKLOG_FILE" ]]; then
        echo "Error: Backlog not found at $BACKLOG_FILE" >&2
        return "$ERR_BACKLOG_NOT_FOUND"
    fi

    cat "$BACKLOG_FILE"
}

# backlog_get_story(story_id)
# Output story JSON by ID, or empty if not found
backlog_get_story() {
    local story_id="$1"

    require_jq || return $?

    jq --arg id "$story_id" \
        '.stories[] | select(.id == ($id | tonumber))' \
        "$BACKLOG_FILE" 2>/dev/null || echo ""
}

# backlog_get_task(story_id, task_id)
# Output task JSON by story and task ID
backlog_get_task() {
    local story_id="$1"
    local task_id="$2"

    require_jq || return $?

    jq --arg sid "$story_id" --arg tid "$task_id" \
        '.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))' \
        "$BACKLOG_FILE" 2>/dev/null || echo ""
}

# backlog_list_stories(status_filter?)
# Output all stories, optionally filtered by status
backlog_list_stories() {
    local status_filter="${1:-}"

    require_jq || return $?

    if [[ -n "$status_filter" ]]; then
        jq --arg status "$status_filter" \
            '.stories[] | select(.status == $status)' \
            "$BACKLOG_FILE"
    else
        jq '.stories[]' "$BACKLOG_FILE"
    fi
}

# backlog_list_tasks(story_id, status_filter?)
# Output tasks for a story, optionally filtered by status
backlog_list_tasks() {
    local story_id="$1"
    local status_filter="${2:-}"

    require_jq || return $?

    if [[ -n "$status_filter" ]]; then
        jq --arg sid "$story_id" --arg status "$status_filter" \
            '.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.status == $status)' \
            "$BACKLOG_FILE"
    else
        jq --arg sid "$story_id" \
            '.stories[] | select(.id == ($sid | tonumber)) | .tasks[]' \
            "$BACKLOG_FILE"
    fi
}

# backlog_story_exists(story_id)
# Return 0 if story exists, 1 otherwise
backlog_story_exists() {
    local story_id="$1"
    local result

    result=$(backlog_get_story "$story_id")
    [[ -n "$result" ]]
}

# backlog_task_exists(story_id, task_id)
# Return 0 if task exists, 1 otherwise
backlog_task_exists() {
    local story_id="$1"
    local task_id="$2"
    local result

    result=$(backlog_get_task "$story_id" "$task_id")
    [[ -n "$result" ]]
}

# =============================================================================
# Write Operations
# =============================================================================

# backlog_touch(author)
# Update version timestamp and author
backlog_touch() {
    local author="$1"
    local timestamp
    timestamp=$(date +%s)

    require_jq || return $?

    local tmp
    tmp=$(mktemp)
    jq --arg ts "$timestamp" --arg author "$author" \
        '.version = ($ts | tonumber) | .meta.updated_by = $author' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"
}

# backlog_set_task_status(story_id, task_id, status)
# Update task status
backlog_set_task_status() {
    local story_id="$1"
    local task_id="$2"
    local status="$3"

    require_jq || return $?

    # Validate status
    local valid=false
    for s in "${STATUSES[@]}"; do
        [[ "$s" == "$status" ]] && valid=true && break
    done
    if [[ "$valid" != "true" ]]; then
        echo "Error: Invalid status '$status'. Valid: ${STATUSES[*]}" >&2
        return "$ERR_INVALID_STATUS"
    fi

    # Validate task exists
    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --arg status "$status" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).status = $status' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"
}

# backlog_set_task_assignee(story_id, task_id, assignee)
# Update task assignee
backlog_set_task_assignee() {
    local story_id="$1"
    local task_id="$2"
    local assignee="$3"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --arg assignee "$assignee" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).assignee = $assignee' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"
}

# backlog_claim_task(story_id, task_id, assignee)
# Claim task: set assignee and status to in_progress
backlog_claim_task() {
    local story_id="$1"
    local task_id="$2"
    local assignee="$3"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    # Check if already claimed
    local current_assignee
    current_assignee=$(backlog_get_task "$story_id" "$task_id" | jq -r '.assignee // empty')
    if [[ -n "$current_assignee" && "$current_assignee" != "null" ]]; then
        echo "Error: Task $story_id.$task_id already claimed by $current_assignee" >&2
        return "$ERR_TASK_ALREADY_CLAIMED"
    fi

    # Update both fields
    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --arg assignee "$assignee" --arg status "$STATUS_IN_PROGRESS" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))) |= (.assignee = $assignee | .status = $status)' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    # Update story status if needed
    backlog_recompute_story_status "$story_id"

    # Update version
    backlog_touch "$assignee"

    echo "Claimed task $story_id.$task_id"
}

# backlog_recompute_story_status(story_id)
# Derive story status from task statuses
backlog_recompute_story_status() {
    local story_id="$1"

    require_jq || return $?

    if ! backlog_story_exists "$story_id"; then
        echo "Error: Story $story_id not found" >&2
        return "$ERR_STORY_NOT_FOUND"
    fi

    # Compute status: all done -> done, any not proposed -> in_progress, else proposed
    local new_status
    new_status=$(jq -r --arg sid "$story_id" '
        .stories[] | select(.id == ($sid | tonumber)) |
        if (.tasks | length) == 0 then "proposed"
        elif (.tasks | all(.status == "done")) then "done"
        elif (.tasks | any(.status != "proposed")) then "in_progress"
        else "proposed"
        end
    ' "$BACKLOG_FILE")

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg status "$new_status" \
        '(.stories[] | select(.id == ($sid | tonumber))).status = $status' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"
}

# backlog_add_story(title, prd_path?, design_path?)
# Add new story, returns story ID
backlog_add_story() {
    local title="$1"
    local prd_path="${2:-}"
    local design_path="${3:-}"

    require_jq || return $?

    # Get next story ID
    local next_id
    next_id=$(jq '[.stories[].id] | (max // 0) + 1' "$BACKLOG_FILE")

    # Set default paths if not provided
    [[ -z "$prd_path" ]] && prd_path="docs/stories/$next_id/prd.md"
    [[ -z "$design_path" ]] && design_path="docs/tech/$next_id/design.md"

    local tmp
    tmp=$(mktemp)
    jq --arg id "$next_id" --arg title "$title" --arg prd "$prd_path" --arg design "$design_path" \
        '.stories += [{
            "id": ($id | tonumber),
            "title": $title,
            "status": "proposed",
            "priority": ($id | tonumber),
            "prd": $prd,
            "design": $design,
            "dependencies": [],
            "tasks": []
        }]' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"

    echo "$next_id"
}

# backlog_add_task(story_id, title, files?, extras_json?)
# Add task to story, returns task ID
# extras_json: optional JSON object with scope, implementation, testing fields
backlog_add_task() {
    local story_id="$1"
    local title="$2"
    local files="${3:-}"
    local extras="${4:-{\}}"

    require_jq || return $?

    if ! backlog_story_exists "$story_id"; then
        echo "Error: Story $story_id not found" >&2
        return "$ERR_STORY_NOT_FOUND"
    fi

    # Get next task ID within story
    local next_id
    next_id=$(jq --arg sid "$story_id" \
        '[.stories[] | select(.id == ($sid | tonumber)) | .tasks[].id] | (max // 0) + 1' \
        "$BACKLOG_FILE")

    # Parse files into array
    local files_json="[]"
    if [[ -n "$files" ]]; then
        files_json=$(echo "$files" | jq -R 'split(",")')
    fi

    # Build base task object, then merge extras
    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg id "$next_id" --arg title "$title" \
       --argjson files "$files_json" --argjson extras "$extras" \
        '(.stories[] | select(.id == ($sid | tonumber))).tasks += [{
            "id": ($id | tonumber),
            "title": $title,
            "status": "proposed",
            "assignee": null,
            "files": $files
        } * $extras]' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"

    echo "$next_id"
}

# =============================================================================
# Rich Task Field Operations
# =============================================================================

# backlog_set_task_field(story_id, task_id, field, value_json)
# Generic setter for any task field
backlog_set_task_field() {
    local story_id="$1"
    local task_id="$2"
    local field="$3"
    local value="$4"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --arg field "$field" --argjson value "$value" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber)))[$field] = $value' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"
}

# backlog_set_task_scope(story_id, task_id, in_json, out_json)
# Set task scope with in/out arrays
backlog_set_task_scope() {
    local story_id="$1"
    local task_id="$2"
    local in_arr="$3"
    local out_arr="$4"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --argjson in_arr "$in_arr" --argjson out_arr "$out_arr" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).scope = {"in": $in_arr, "out": $out_arr}' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"
}

# backlog_set_task_implementation(story_id, task_id, steps_json)
# Set task implementation steps array
backlog_set_task_implementation() {
    local story_id="$1"
    local task_id="$2"
    local steps="$3"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --argjson steps "$steps" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).implementation = $steps' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"
}

# backlog_set_task_testing(story_id, task_id, domains_json, edges_json, wavs_json)
# Set task testing strategy
backlog_set_task_testing() {
    local story_id="$1"
    local task_id="$2"
    local domains="$3"
    local edges="$4"
    local wavs="$5"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --argjson domains "$domains" --argjson edges "$edges" --argjson wavs "$wavs" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).testing = {"domains": $domains, "edges": $edges, "wavs": $wavs}' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"
}

# backlog_set_task_design_refs(story_id, task_id, refs_json)
# Set task design document references
backlog_set_task_design_refs() {
    local story_id="$1"
    local task_id="$2"
    local refs="$3"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    local tmp
    tmp=$(mktemp)
    jq --arg sid "$story_id" --arg tid "$task_id" --argjson refs "$refs" \
        '(.stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber))).designRefs = $refs' \
        "$BACKLOG_FILE" > "$tmp" && mv "$tmp" "$BACKLOG_FILE"

    backlog_touch "$(git config user.email 2>/dev/null || echo 'unknown')"
}

# =============================================================================
# Formatting Helpers
# =============================================================================

# backlog_format_stories()
# Output stories as formatted table
backlog_format_stories() {
    require_jq || return $?

    echo "ID | Title | Status | Progress"
    echo "---|-------|--------|----------"

    jq -r '.stories[] |
        "\(.id) | \(.title) | \(.status) | \([.tasks[] | select(.status == "done")] | length)/\(.tasks | length)"
    ' "$BACKLOG_FILE"
}

# backlog_format_tasks(story_id)
# Output tasks for story as formatted table
backlog_format_tasks() {
    local story_id="$1"

    require_jq || return $?

    local story_title
    story_title=$(jq -r --arg sid "$story_id" \
        '.stories[] | select(.id == ($sid | tonumber)) | .title' \
        "$BACKLOG_FILE")

    echo "Tasks for Story $story_id: $story_title"
    echo ""
    echo "ID | Title | Status | Assignee"
    echo "---|-------|--------|----------"

    jq -r --arg sid "$story_id" '
        .stories[] | select(.id == ($sid | tonumber)) | .tasks[] |
        "\($sid).\(.id) | \(.title) | \(.status) | \(.assignee // "-")"
    ' "$BACKLOG_FILE"
}

# backlog_format_task_detail(story_id, task_id)
# Output full task detail as markdown
backlog_format_task_detail() {
    local story_id="$1"
    local task_id="$2"

    require_jq || return $?

    if ! backlog_task_exists "$story_id" "$task_id"; then
        echo "Error: Task $story_id.$task_id not found" >&2
        return "$ERR_TASK_NOT_FOUND"
    fi

    jq -r --arg sid "$story_id" --arg tid "$task_id" '
        .stories[] | select(.id == ($sid | tonumber)) | .tasks[] | select(.id == ($tid | tonumber)) |
        "# Task \($sid).\(.id): \(.title)\n" +
        "\n**Status:** \(.status)" +
        "\n**Assignee:** \(.assignee // "unassigned")\n" +
        "\n## Design References\n" +
        (if .designRefs and (.designRefs | length) > 0 then (.designRefs | map("- \(.)") | join("\n")) else "_No design refs_" end) +
        "\n\n## Files\n" +
        (if (.files | length) > 0 then (.files | map("- `\(.)`") | join("\n")) else "_No files specified_" end) +
        "\n\n## Scope\n" +
        (if .scope then
            "**In:**\n" + (if (.scope.in | length) > 0 then (.scope.in | map("- \(.)") | join("\n")) else "_Not specified_" end) +
            "\n\n**Out:**\n" + (if (.scope.out | length) > 0 then (.scope.out | map("- \(.)") | join("\n")) else "_Not specified_" end)
        else "_Not specified_" end) +
        "\n\n## Implementation\n" +
        (if .implementation and (.implementation | length) > 0 then
            (.implementation | to_entries | map("\(.key + 1). \(.value)") | join("\n"))
        else "_No steps defined_" end) +
        "\n\n## Testing\n" +
        (if .testing then
            "**Domains:** " + (if (.testing.domains | length) > 0 then (.testing.domains | join(", ")) else "_none_" end) +
            "\n**Edges:** " + (if (.testing.edges | length) > 0 then (.testing.edges | join(", ")) else "_none_" end) +
            "\n**WAVs:** " + (if (.testing.wavs | length) > 0 then (.testing.wavs | join(", ")) else "_none_" end)
        else "_Not specified_" end)
    ' "$BACKLOG_FILE"
}
