#!/bin/bash
# task-manager.sh - Hierarchical task management for claude-bot
# Provides CRUD operations for tasks with parent-child relationships

set -e

# Task manager state file
TASK_STATE_DIR="${STATE_DIR:-.claude}"
TASK_STATE_FILE="${TASK_STATE_DIR}/claude-bot.tasks.yaml"

# Initialize task state
task-init() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        mkdir -p "$TASK_STATE_DIR"
        cat > "$TASK_STATE_FILE" << 'EOF'
# Task State for Claude-Bot
version: "2.0"
tasks: []
task_counter: 0
EOF
    fi
}

# Create new task
# Usage: task-create "description" "parent_id" "complexity" "assigned_agent"
task-create() {
    local description="$1"
    local parent_id="${2:-null}"
    local complexity="${3:-medium}"
    local assigned_agent="${4:-unassigned}"

    task-init

    # Get next task ID
    local task_counter
    task_counter=$(grep "task_counter:" "$TASK_STATE_FILE" | awk '{print $2}')
    local task_id="task-$((task_counter + 1))"

    # Determine level based on parent
    local level=0
    if [[ "$parent_id" != "null" ]]; then
        level=$(grep -A 10 "id: $parent_id" "$TASK_STATE_FILE" | grep "level:" | awk '{print $2}' || echo 0)
        level=$((level + 1))
    fi

    # Append new task
    cat >> "$TASK_STATE_FILE" << EOF

  - id: $task_id
    description: "$description"
    parent_id: $parent_id
    level: $level
    status: pending
    complexity: $complexity
    assigned_agent: $assigned_agent
    dependencies: []
    subtasks: []
    progress: 0
    milestone: false
    created_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
EOF

    # Update counter
    sed -i.bak "s/task_counter: $task_counter/task_counter: $((task_counter + 1))/" "$TASK_STATE_FILE"
    rm -f "${TASK_STATE_FILE}.bak"

    echo "$task_id"
}

# Add dependency to task
# Usage: task-deps-add "task_id" "depends_on_task_id"
task-deps-add() {
    local task_id="$1"
    local depends_on="$2"

    task-init

    # Add dependency to task
    awk -v task="$task_id" -v dep="$depends_on" '
        $0 ~ "id: " task {
            in_task = 1
        }
        in_task && /dependencies:/ {
            $0 = "    dependencies: [" dep "]"
            modified = 1
        }
        in_task && /^  - id:/ && modified {
            in_task = 0
            modified = 0
        }
        { print }
    ' "$TASK_STATE_FILE" > "${TASK_STATE_FILE}.tmp" && mv "${TASK_STATE_FILE}.tmp" "$TASK_STATE_FILE"
}

# Find tasks ready for execution (no pending dependencies)
# Usage: task-ready
task-ready() {
    task-init

    echo "Tasks ready for execution:"
    grep -A 20 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            /id:/ { id = $2; gsub(/"/, "", id) }
            /status:/ { status = $2 }
            /dependencies:/ { deps = $0; gsub(/dependencies: |\[\]|,/, "", deps) }
            /^  - id:/ && id != "" && status == "pending" && deps == "" {
                print "  - " id
                id = ""
                status = ""
                deps = ""
            }
        '
}

# Mark task as complete and update dependents
# Usage: task-complete "task_id"
task-complete() {
    local task_id="$1"

    task-init

    # Update task status
    sed -i.bak "/id: $task_id/,/^  - id:/s/status: pending/status: completed/" "$TASK_STATE_FILE"
    sed -i.bak "/id: $task_id/,/^  - id:/s/progress: [0-9]*/progress: 100/" "$TASK_STATE_FILE"
    sed -i.bak "/id: $task_id/,/^  - id:/s/completed_at: null/completed_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")/" "$TASK_STATE_FILE"
    rm -f "${TASK_STATE_FILE}.bak"

    # Find and notify dependent tasks
    echo "Task $task_id completed. Dependents that may now be ready:"
    grep -B 5 "$task_id" "$TASK_STATE_FILE" | grep "id:" | head -5
}

# Assign task to agent
# Usage: task-assign "task_id" "agent_name"
task-assign() {
    local task_id="$1"
    local agent="$2"

    task-init

    sed -i.bak "/id: $task_id/,/^  - id:/s/assigned_agent: [a-z_]*/assigned_agent: $agent/" "$TASK_STATE_FILE"
    rm -f "${TASK_STATE_FILE}.bak"
}

# Update task progress
# Usage: task-progress "task_id" "percentage"
task-progress() {
    local task_id="$1"
    local progress="$2"

    task-init

    # Update progress and potentially status
    sed -i.bak "/id: $task_id/,/^  - id:/s/progress: [0-9]*/progress: $progress/" "$TASK_STATE_FILE"

    if [[ "$progress" -ge 100 ]]; then
        sed -i.bak "/id: $task_id/,/^  - id:/s/status: in_progress/status: completed/" "$TASK_STATE_FILE"
    elif [[ "$progress" -gt 0 ]]; then
        sed -i.bak "/id: $task_id/,/^  - id:/s/status: pending/status: in_progress/" "$TASK_STATE_FILE"
    fi

    rm -f "${TASK_STATE_FILE}.bak"
}

# Get task status
# Usage: task-status "task_id"
task-status() {
    local task_id="$1"

    task-init

    echo "Task: $task_id"
    grep -A 15 "id: $task_id" "$TASK_STATE_FILE" | head -16
}

# List all tasks
# Usage: task-list
task-list() {
    task-init

    echo "All Tasks:"
    echo "---"
    grep -A 12 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            /id:/ {
                id = $2
                gsub(/"/, "", id)
                printf "  %s", id
            }
            /description:/ {
                for(i=2; i<=NF; i++) printf " %s", $i
                printf "\n"
            }
            /status:/ {
                printf "    Status: %s\n", $2
            }
            /progress:/ {
                printf "    Progress: %s%%\n", $2
            }
        '
}

# Find tasks ready for parallel execution
# Usage: task-parallel-ready
task-parallel-ready() {
    task-init

    echo "Tasks ready for parallel execution (no dependencies, pending):"
    grep -A 20 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            BEGIN { count = 0 }
            /id:/ { id = $2; gsub(/"/, "", id) }
            /status:/ { status = $2 }
            /dependencies:/ { deps = $0; gsub(/dependencies: |\[\]|,/, "", deps) }
            /^  - id:/ && id != "" && status == "pending" && deps == "" {
                print "  - " id
                count++
                id = ""
                status = ""
                deps = ""
            }
            END { print "\nTotal: " count " tasks ready" }
        '
}

# Get subtasks of a task
# Usage: task-subtasks "parent_task_id"
task-subtasks() {
    local parent_id="$1"

    task-init

    echo "Subtasks of $parent_id:"
    grep -A 12 "parent_id: $parent_id" "$TASK_STATE_FILE" | \
        awk '
            /id:/ {
                id = $2
                gsub(/"/, "", id)
                print "  - " id
            }
            /description:/ {
                for(i=2; i<=NF; i++) printf " %s", $i
                printf "\n"
            }
        '
}

# Mark task as milestone
# Usage: task-milestone "task_id"
task-milestone() {
    local task_id="$1"

    task-init

    sed -i.bak "/id: $task_id/,/^  - id:/s/milestone: false/milestone: true/" "$TASK_STATE_FILE"
    rm -f "${TASK_STATE_FILE}.bak"
}

# Get all milestones
# Usage: task-milestones
task-milestones() {
    task-init

    echo "Milestones:"
    grep -B 2 "milestone: true" "$TASK_STATE_FILE" | \
        awk '
            /id:/ {
                id = $2
                gsub(/"/, "", id)
            }
            /description:/ {
                desc = ""
                for(i=2; i<=NF; i++) desc = desc " " $i
                printf "  %s:%s\n", id, desc
            }
        '
}

# Main command router
case "${1:-}" in
    init)       task-init ;;
    create)     task-create "$2" "$3" "$4" "$5" ;;
    deps-add)   task-deps-add "$2" "$3" ;;
    ready)      task-ready ;;
    complete)   task-complete "$2" ;;
    assign)     task-assign "$2" "$3" ;;
    progress)   task-progress "$2" "$3" ;;
    status)     task-status "$2" ;;
    list)       task-list ;;
    parallel)   task-parallel-ready ;;
    subtasks)   task-subtasks "$2" ;;
    milestone)  task-milestone "$2" ;;
    milestones) task-milestones ;;
    *)
        echo "Usage: $0 {init|create|deps-add|ready|complete|assign|progress|status|list|parallel|subtasks|milestone|milestones}"
        exit 1
        ;;
esac
