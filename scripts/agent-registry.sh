#!/bin/bash
# agent-registry.sh - Agent capability and workload management

set -e

AGENT_REGISTRY_FILE="${STATE_DIR:-.claude}/claude-bot.agents.yaml"

# Agent capability definitions
declare -A AGENT_CAPABILITIES=(
    ["planner"]="planning decomposition dependency_analysis"
    ["explorer"]="code_analysis pattern_detection file_search"
    ["architect"]="design architecture trade_off_analysis"
    ["implementer"]="coding file_creation modification"
    ["builder"]="build compilation dependency_management"
    ["validator"]="code_review security quality"
    ["tester"]="testing playwright unit_tests"
    ["documenter"]="documentation examples guides"
    ["requirements_validator"]="requirements acceptance_criteria"
)

# Initialize agent registry
agent-init() {
    if [[ ! -f "$AGENT_REGISTRY_FILE" ]]; then
        mkdir -p "$(dirname "$AGENT_REGISTRY_FILE")"
        cat > "$AGENT_REGISTRY_FILE" << 'EOF'
# Agent Registry for Claude-Bot
version: "2.0"
agents:
  - name: planner
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [planning, decomposition, dependency_analysis]
    max_concurrent: 1
    started_at: null
    last_activity: null
  - name: explorer
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [code_analysis, pattern_detection, file_search]
    max_concurrent: 4
    started_at: null
    last_activity: null
  - name: architect
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [design, architecture, trade_off_analysis]
    max_concurrent: 1
    started_at: null
    last_activity: null
  - name: implementer
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [coding, file_creation, modification]
    max_concurrent: 3
    started_at: null
    last_activity: null
  - name: builder
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [build, compilation, dependency_management]
    max_concurrent: 1
    started_at: null
    last_activity: null
  - name: validator
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [code_review, security, quality]
    max_concurrent: 3
    started_at: null
    last_activity: null
  - name: tester
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [testing, playwright, unit_tests]
    max_concurrent: 2
    started_at: null
    last_activity: null
  - name: documenter
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [documentation, examples, guides]
    max_concurrent: 1
    started_at: null
    last_activity: null
  - name: requirements_validator
    type: agent
    status: idle
    current_task: null
    assigned_tasks: []
    completed_tasks: []
    capabilities: [requirements, acceptance_criteria]
    max_concurrent: 1
    started_at: null
    last_activity: null
EOF
    fi
}

# Register new agent instance
# Usage: agent-register "agent_name" "instance_id"
agent-register() {
    local agent_name="$1"
    local instance_id="${2:-${agent_name}-$(date +%s)}"

    agent-init

    echo "Registered agent instance: $instance_id (type: $agent_name)"
}

# Assign task to capable agent
# Usage: agent-assign "task_id" "required_capability"
agent-assign() {
    local task_id="$1"
    local required_capability="$2"

    agent-init

    # Find idle agent with required capability
    local agent_name
    agent_name=$(grep -A 10 "capabilities:.*$required_capability" "$AGENT_REGISTRY_FILE" | grep "name:" | head -1 | awk '{print $2}')

    if [[ -z "$agent_name" ]]; then
        echo "No capable agent found for: $required_capability"
        return 1
    fi

    # Check if agent is at capacity
    local current_tasks
    current_tasks=$(grep -A 5 "name: $agent_name" "$AGENT_REGISTRY_FILE" | grep "assigned_tasks:" | sed 's/assigned_tasks: \[\(.*\)\]/\1/' | wc -w)

    local max_concurrent
    max_concurrent=$(grep -A 10 "name: $agent_name" "$AGENT_REGISTRY_FILE" | grep "max_concurrent:" | awk '{print $2}')

    if [[ $current_tasks -ge $max_concurrent ]]; then
        echo "Agent $agent_name is at capacity ($current_tasks/$max_concurrent)"
        return 1
    fi

    # Assign task
    sed -i.bak "/name: $agent_name/,/^  - name:/s/current_task: null/current_task: $task_id/" "$AGENT_REGISTRY_FILE"
    sed -i.bak "/name: $agent_name/,/^  - name:/s/status: idle/status: working/" "$AGENT_REGISTRY_FILE"
    rm -f "${AGENT_REGISTRY_FILE}.bak"

    echo "Assigned $task_id to $agent_name"
}

# Get agent status
# Usage: agent-status "agent_name"
agent-status() {
    local agent_name="${1:-all}"

    agent-init

    if [[ "$agent_name" == "all" ]]; then
        echo "# Agent Status"
        grep -A 12 "^  - name:" "$AGENT_REGISTRY_FILE" | \
            awk '
                /name:/ {
                    name = $2
                    printf "  %s:\n", name
                }
                /status:/ {
                    printf "    Status: %s\n", $2
                }
                /current_task:/ {
                    printf "    Current Task: %s\n", $2
                }
                /assigned_tasks:/ {
                    printf "    Assigned: %s\n", $0
                }
                /^  - name:/ {
                    printf "\n"
                }
            '
    else
        echo "# Agent: $agent_name"
        grep -A 12 "name: $agent_name" "$AGENT_REGISTRY_FILE" | head -13
    fi
}

# Check agent workload
# Usage: agent-workload
agent-workload() {
    agent-init

    echo "# Agent Workload"
    grep -A 12 "^  - name:" "$AGENT_REGISTRY_FILE" | \
        awk '
            /name:/ {
                name = $2
            }
            /status:/ {
                status = $2
            }
            /assigned_tasks:/ {
                tasks = $0
                gsub(/assigned_tasks: \[|\]|,/, "", tasks)
                count = gsub(/task-/, "", tasks)
                printf "  %-20s %-10s %d tasks\n", name, status, count
            }
        '
}

# Check if agent is capable of task
# Usage: agent-capable "agent_name" "capability"
agent-capable() {
    local agent_name="$1"
    local capability="$2"

    agent-init

    if grep -A 8 "name: $agent_name" "$AGENT_REGISTRY_FILE" | grep -q "$capability"; then
        echo "Agent $agent_name is capable of: $capability"
        return 0
    else
        echo "Agent $agent_name is NOT capable of: $capability"
        return 1
    fi
}

# Balance tasks across agents
# Usage: agent-balance
agent-balance() {
    agent-init

    echo "# Agent Load Balancing"
    echo "Redistributing tasks to balance workload..."

    # Find most loaded agent
    local max_load=0
    local most_loaded=""

    # Find least loaded agent with same capabilities
    # (Simplified - real implementation would match capabilities)
    grep -A 12 "^  - name:" "$AGENT_REGISTRY_FILE" | \
        awk '
            /name:/ { name = $2 }
            /assigned_tasks:/ {
                tasks = $0
                gsub(/assigned_tasks: \[|\]|,/, "", tasks)
                count = gsub(/task-/, "", tasks)
                printf "%s %d\n", name, count
            }
        ' | sort -k2 -rn
}

# Complete task and update agent
# Usage: agent-complete-task "agent_name" "task_id"
agent-complete-task() {
    local agent_name="$1"
    local task_id="$2"

    agent-init

    # Add to completed tasks
    sed -i.bak "/name: $agent_name/,/^  - name:/s/current_task: $task_id/current_task: null/" "$AGENT_REGISTRY_FILE"
    sed -i.bak "/name: $agent_name/,/^  - name:/s/status: working/status: idle/" "$AGENT_REGISTRY_FILE"
    rm -f "${AGENT_REGISTRY_FILE}.bak"

    echo "Task $task_id completed by $agent_name"
}

# Get all capable agents for a task
# Usage: agent-find-capable "capability1,capability2"
agent-find-capable() {
    local capabilities="$1"

    agent-init

    echo "# Capable Agents for: $capabilities"

    IFS=',' read -ra caps <<< "$capabilities"
    for cap in "${caps[@]}"; do
        grep -A 8 "capabilities:.*$cap" "$AGENT_REGISTRY_FILE" | grep "name:" | awk '{print "  - " $2}'
    done | sort -u
}

# Main command router
case "${1:-}" in
    init)           agent-init ;;
    register)       agent-register "$2" "$3" ;;
    assign)         agent-assign "$2" "$3" ;;
    status)         agent-status "${2:-all}" ;;
    workload)       agent-workload ;;
    capable)        agent-capable "$2" "$3" ;;
    balance)        agent-balance ;;
    complete-task)  agent-complete-task "$2" "$3" ;;
    find-capable)   agent-find-capable "$2" ;;
    *)
        echo "Usage: $0 {init|register|assign|status|workload|capable|balance|complete-task|find-capable}"
        exit 1
        ;;
esac
