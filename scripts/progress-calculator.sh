#!/bin/bash
# progress-calculator.sh - Calculate and display progress metrics

set -e

TASK_STATE_DIR="${STATE_DIR:-.claude}"
TASK_STATE_FILE="${TASK_STATE_DIR}/claude-bot.tasks.yaml"
WORKFLOW_STATE_FILE="${TASK_STATE_DIR}/claude-bot.local.md"

# Calculate overall progress percentage
# Usage: progress-calculate
progress-calculate() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        echo "0"
        return 0
    fi

    local total_tasks=0
    local completed_tasks=0
    local total_effort=0
    local completed_effort=0

    # Parse tasks
    while IFS= read -r line; do
        if [[ $line =~ id:\ task-([0-9]+) ]]; then
            total_tasks=$((total_tasks + 1))
        fi
        if [[ $line =~ status:\ completed ]]; then
            completed_tasks=$((completed_tasks + 1))
        fi
        if [[ $line =~ estimated_effort:\ ([0-9]+) ]]; then
            total_effort=$((total_effort + ${BASH_REMATCH[1]}))
        fi
    done < "$TASK_STATE_FILE"

    # Calculate weighted progress
    if [[ $total_effort -gt 0 ]]; then
        # Would need completed_effort tracking for true weighted progress
        # For now, use simple task count
        local percentage=$(( (completed_tasks * 100) / total_tasks ))
        echo "$percentage"
    else
        echo "0"
    fi
}

# Get milestone progress
# Usage: progress-milestones
progress-milestones() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        echo "Milestones: 0/0 (0%)"
        return 0
    fi

    local total_milestones=0
    local completed_milestones=0

    while IFS= read -r line; do
        if [[ $line =~ milestone:\ true ]]; then
            total_milestones=$((total_milestones + 1))
            # Check if this milestone task is completed
            if grep -B 5 "milestone: true" "$TASK_STATE_FILE" | grep -q "status: completed"; then
                completed_milestones=$((completed_milestones + 1))
            fi
        fi
    done < "$TASK_STATE_FILE"

    local percentage=0
    if [[ $total_milestones -gt 0 ]]; then
        percentage=$(( (completed_milestones * 100) / total_milestones ))
    fi

    echo "Milestones: $completed_milestones/$total_milestones ($percentage%)"
}

# Estimate completion time
# Usage: progress-estimate
progress-estimate() {
    local current_progress
    current_progress=$(progress-calculate)

    if [[ $current_progress -eq 0 ]]; then
        echo "Cannot estimate (no progress yet)"
        return 0
    fi

    # Get start time from workflow state
    local start_time
    start_time=$(grep "started_at:" "$WORKFLOW_STATE_FILE" 2>/dev/null | head -1 | awk '{print $2}' || echo "")

    if [[ -z "$start_time" ]]; then
        echo "Cannot estimate (no start time)"
        return 0
    fi

    # Calculate elapsed time
    local start_epoch
    local current_epoch
    start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" +%s 2>/dev/null || date -d "$start_time" +%s)
    current_epoch=$(date +%s)

    local elapsed_seconds=$((current_epoch - start_epoch))
    local elapsed_minutes=$((elapsed_seconds / 60))

    # Estimate remaining time
    local remaining_percentage=$((100 - current_progress))
    local estimated_remaining_seconds=$(( (elapsed_seconds * remaining_percentage) / current_progress ))
    local estimated_remaining_minutes=$((estimated_remaining_seconds / 60))

    local estimated_completion_epoch=$((current_epoch + estimated_remaining_seconds))
    local estimated_completion
    estimated_completion=$(date -r "$estimated_completion_epoch" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "@$estimated_completion_epoch" +"%Y-%m-%d %H:%M:%S")

    echo "Elapsed: ${elapsed_minutes}m | Est. remaining: ${estimated_remaining_minutes}m"
    echo "ETA: $estimated_completion"
}

# Generate progress bar
# Usage: progress-bar [width]
progress-bar() {
    local width="${1:-40}"
    local progress
    progress=$(progress-calculate)

    local filled=$(( (progress * width) / 100 ))
    local empty=$((width - filled))

    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%%\n" "$progress"
}

# Get agent activity summary
# Usage: progress-agents
progress-agents() {
    local agent_file="${TASK_STATE_DIR}/claude-bot.agents.yaml"

    if [[ ! -f "$agent_file" ]]; then
        echo "No agent activity recorded"
        return 0
    fi

    echo "# Agent Activity"
    grep -A 12 "^  - name:" "$agent_file" | \
        awk '
            /name:/ {
                name = $2
            }
            /status:/ {
                status = $2
                if (status == "working") {
                    printf "  🔄 %s (working)\n", name
                } else if (status == "idle") {
                    printf "  💤 %s (idle)\n", name
                } else {
                    printf "  ⚪ %s (%s)\n", name, status
                }
            }
            /current_task:/ {
                if ($2 != "null") {
                    printf "     └─ Task: %s\n", $2
                }
            }
        '
}

# Get task breakdown by status
# Usage: progress-breakdown
progress-breakdown() {
    if [[ ! -f "$TASK_STATE_FILE" ]]; then
        echo "No tasks recorded"
        return 0
    fi

    echo "# Task Breakdown"

    local pending=0
    local in_progress=0
    local completed=0
    local blocked=0

    while IFS= read -r line; do
        case "$line" in
            *status:\ pending*) pending=$((pending + 1)) ;;
            *status:\ in_progress*) in_progress=$((in_progress + 1)) ;;
            *status:\ completed*) completed=$((completed + 1)) ;;
            *status:\ blocked*) blocked=$((blocked + 1)) ;;
        esac
    done < "$TASK_STATE_FILE"

    local total=$((pending + in_progress + completed + blocked))
    echo "  Pending:     $pending"
    echo "  In Progress: $in_progress"
    echo "  Completed:   $completed"
    echo "  Blocked:     $blocked"
    echo "  ─────────────"
    echo "  Total:       $total"
}

# Get detailed progress view
# Usage: progress-detail
progress-detail() {
    echo "╔══════════════════════════════════════════╗"
    echo "║        Claude-Bot Progress              ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""

    # Progress bar
    progress-bar
    echo ""

    # Milestones
    progress-milestones
    echo ""

    # Task breakdown
    progress-breakdown
    echo ""

    # Time estimate
    echo "⏱️  Time Tracking"
    progress-estimate | sed 's/^/    /'
    echo ""

    # Agent activity
    progress-agents
}

# Get phase progress
# Usage: progress-phases
progress-phases() {
    if [[ ! -f "$WORKFLOW_STATE_FILE" ]]; then
        echo "No workflow state found"
        return 0
    fi

    echo "# Phase Progress"

    # Define phases
    local phases=(plan explore design implement build validate test requirements document)

    for phase in "${phases[@]}"; do
        local phase_status
        phase_status=$(grep -A 5 "^phases:" "$WORKFLOW_STATE_FILE" | grep -A 3 "^  $phase:" | grep "status:" | awk '{print $2}' || echo "pending")

        case "$phase_status" in
            completed)
                echo "  ✅ $phase"
                ;;
            in_progress)
                echo "  🔄 $phase (active)"
                ;;
            pending)
                echo "  ⏳ $phase"
                ;;
            blocked)
                echo "  🚫 $phase (blocked)"
                ;;
            *)
                echo "  ⚪ $phase"
                ;;
        esac
    done
}

# Main command router
case "${1:-}" in
    calculate)   progress-calculate ;;
    milestones)  progress-milestones ;;
    estimate)    progress-estimate ;;
    bar)         progress-bar "${2:-40}" ;;
    agents)      progress-agents ;;
    breakdown)   progress-breakdown ;;
    detail)      progress-detail ;;
    phases)      progress-phases ;;
    *)
        echo "Usage: $0 {calculate|milestones|estimate|bar|agents|breakdown|detail|phases}"
        exit 1
        ;;
esac
