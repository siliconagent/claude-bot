#!/bin/bash
# dependency-resolver.sh - DAG-based dependency resolution for claude-bot

set -e

TASK_STATE_DIR="${STATE_DIR:-.claude}"
TASK_STATE_FILE="${TASK_STATE_DIR}/claude-bot.tasks.yaml"
DEPS_CACHE_FILE="${TASK_STATE_DIR}/claude-bot.deps.cache"

# Build dependency graph from tasks
deps-build-graph() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        echo "Error: Task state file not found"
        return 1
    fi

    # Parse tasks and build adjacency list
    echo "# Dependency Graph"
    echo "graph:"
    grep -A 15 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            BEGIN { print "{" }
            /id:/ {
                id = $2
                gsub(/"/, "", id)
                current_id = id
            }
            /dependencies:/ {
                deps_str = $0
                gsub(/dependencies: |\[/, "", deps_str)
                if (deps_str != "]" && deps_str != "") {
                    print "  \"" current_id "\": [" deps_str
                }
            }
            END { print "}" }
        '
}

# Find tasks with no pending dependencies (ready to execute)
deps-find-ready() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        return 1
    fi

    # Get all pending tasks with empty or completed dependencies
    grep -A 20 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            /id:/ {
                id = $2
                gsub(/"/, "", id)
                task_id = id
            }
            /status:/ {
                status = $2
            }
            /dependencies:/ {
                deps = $0
                gsub(/dependencies: |\[|\]|,/, "", deps)
                has_deps = (deps != "")
            }
            /^  - id:/ && task_id != "" && status == "pending" && !has_deps {
                print task_id
                task_id = ""
                status = ""
                has_deps = 0
            }
        '
}

# Check for circular dependencies using DFS
deps-check-circular() {
    local visited="$TASK_STATE_DIR/.deps_visited"
    local rec_stack="$TASK_STATE_DIR/.deps_recstack"

    rm -f "$visited" "$rec_stack"
    touch "$visited" "$rec_stack"

    local has_cycle=0

    # DFS for cycle detection
    grep "id: task-" "$TASK_STATE_FILE" | awk '{print $2}' | while read -r task_id; do
        if ! grep -q "$task_id" "$visited"; then
            if deps-dfs-util "$task_id" "$visited" "$rec_stack"; then
                has_cycle=1
            fi
        fi
    done

    rm -f "$visited" "$rec_stack"

    if [[ $has_cycle -eq 1 ]]; then
        echo "Error: Circular dependencies detected!"
        return 1
    fi

    echo "No circular dependencies found"
    return 0
}

# Utility function for DFS cycle detection
deps-dfs-util() {
    local task_id="$1"
    local visited="$2"
    local rec_stack="$3"

    echo "$task_id" >> "$visited"
    echo "$task_id" >> "$rec_stack"

    # Get dependencies
    local deps
    deps=$(grep -A 10 "id: $task_id" "$TASK_STATE_FILE" | grep "dependencies:" | sed 's/dependencies: \[\(.*\)\]/\1/' | tr ',' ' ')

    for dep in $deps; do
        if grep -q "$dep" "$rec_stack"; then
            echo "Cycle detected: $task_id -> $dep"
            return 1
        fi
        if ! grep -q "$dep" "$visited"; then
            deps-dfs-util "$dep" "$visited" "$rec_stack"
        fi
    done

    # Remove from recursion stack
    sed -i.bak "/$task_id/d" "$rec_stack"
    rm -f "${rec_stack}.bak"
    return 0
}

# Calculate critical path (longest path to completion)
deps-critical-path() {
    echo "# Critical Path Analysis"

    # Calculate effort-weighted path
    grep -A 20 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            BEGIN {
                max_effort = 0
            }
            /id:/ {
                id = $2
                gsub(/"/, "", id)
            }
            /estimated_effort:/ {
                effort = $2
                if (effort > max_effort) max_effort = effort
            }
            /dependencies:/ {
                deps = $0
                gsub(/dependencies: |\[|\]|,/, "", deps)
                if (deps != "") {
                    print "  " id " depends on: " deps " (effort: " effort ")"
                }
            }
            END {
                print "\nMax single task effort: " max_effort " hours"
            }
        '
}

# Find tasks that can be executed in parallel
deps-find-parallel() {
    echo "# Parallel Execution Groups"

    local level=0
    local ready_tasks
    ready_tasks=$(deps-find-ready)

    while [[ -n "$ready_tasks" ]]; do
        echo "Level $level: $ready_tasks"
        level=$((level + 1))

        # Simulate completion and find next level
        echo "$ready_tasks" | while read -r task_id; do
            echo "Simulating completion of $task_id"
        done

        ready_tasks=$(deps-find-ready)
        sleep 0.1  # Prevent infinite loop in demo
        if [[ $level -gt 10 ]]; then break; fi
    done
}

# Mark task complete and update dependent tasks
deps-task-complete() {
    local task_id="$1"

    # Update dependent tasks that can now be ready
    grep -B 5 "$task_id" "$TASK_STATE_FILE" | grep "id:" | while read -r dep_line; do
        local dep_task
        dep_task=$(echo "$dep_line" | awk '{print $2}' | tr -d '"')
        echo "Task $dep_task may now be ready (dependency $task_id completed)"
    done
}

# Visualize dependency graph
deps-visualize() {
    echo "# Dependency Graph Visualization"
    echo "digraph tasks {"

    grep -A 15 "^  - id:" "$TASK_STATE_FILE" | \
        awk '
            /id:/ {
                id = $2
                gsub(/"/, "", id)
                printf "  \"%s\" [label=\"%s\"]\n", id, id
            }
            /dependencies:/ {
                deps = $0
                gsub(/dependencies: |\[|\]|,/, "", deps)
                if (deps != "") {
                    print "  \"" id "\" -> {" deps "}"
                }
            }
        '

    echo "}"
}

# Main command router
case "${1:-}" in
    build-graph)    deps-build-graph ;;
    find-ready)     deps-find-ready ;;
    check-circular) deps-check-circular ;;
    critical-path)  deps-critical-path ;;
    find-parallel)  deps-find-parallel ;;
    task-complete)  deps-task-complete "$2" ;;
    visualize)      deps-visualize ;;
    *)
        echo "Usage: $0 {build-graph|find-ready|check-circular|critical-path|find-parallel|task-complete|visualize}"
        exit 1
        ;;
esac
