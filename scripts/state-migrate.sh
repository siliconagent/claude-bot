#!/bin/bash
# state-migrate.sh - Migrate state from v1.0 to v2.0

set -e

STATE_FILE="${STATE_DIR:-.claude}/claude-bot.local.md"
BACKUP_FILE="${STATE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
STATE_V2_MARKER="version: \"2.0\""

# Check if migration is needed
state-check-version() {
    if [[ ! -f "$STATE_FILE" ]]; then
        echo "No state file found"
        return 1
    fi

    if grep -q "$STATE_V2_MARKER" "$STATE_FILE"; then
        echo "State is already at v2.0"
        return 0
    fi

    if grep -q "version: \"1.0\"" "$STATE_FILE"; then
        echo "State is at v1.0, migration needed"
        return 2
    fi

    echo "Unknown state version"
    return 1
}

# Create backup before migration
state-backup() {
    if [[ -f "$STATE_FILE" ]]; then
        cp "$STATE_FILE" "$BACKUP_FILE"
        echo "Backup created: $BACKUP_FILE"
    fi
}

# Migrate v1.0 to v2.0
state-migrate() {
    if ! state-check-version >/dev/null 2>&1; then
        return 1
    fi

    # Backup first
    state-backup

    echo "Migrating state from v1.0 to v2.0..."

    # Create new state file with v2.0 structure
    local temp_file="${STATE_FILE}.tmp"

    # Extract existing YAML frontmatter
    awk '
        BEGIN { in_yaml = 1 }
        /^---$/ {
            if (in_yaml) {
                in_yaml = 0
                next
            } else {
                in_yaml = 1
                print "---"
                next
            }
        }
        in_yaml { print }
    ' "$STATE_FILE" > "$temp_file"

    # Add new v2.0 fields
    cat >> "$temp_file" << 'EOF'

# NEW in v2.0: Hierarchical task management
tasks: []

# NEW in v2.0: Agent tracking
agents:
  - name: planner
    status: idle
    current_task: null
    assigned_tasks: []

# NEW in v2.0: Dependency graph
dependencies:
  graph: {}
  parallel_ready: []
  critical_path: []

# NEW in v2.0: Progress tracking
progress:
  total_tasks: 0
  completed_tasks: 0
  overall_percentage: 0

# NEW in v2.0: Worktree management
worktrees: []

# NEW in v2.0: Build status
build:
  status: pending
  attempts: 0
  artifacts: []

# NEW in v2.0: Test results
testing:
  unit_tests:
    status: pending
  playwright:
    status: pending

# NEW in v2.0: Requirements validation
requirements_validation:
  status: pending
  acceptance_criteria: []
EOF

    # Replace old state file
    mv "$temp_file" "$STATE_FILE"

    echo "Migration complete!"
    echo "Backup saved at: $BACKUP_FILE"
}

# Rollback to backup
state-rollback() {
    if [[ -f "$BACKUP_FILE" ]]; then
        cp "$BACKUP_FILE" "$STATE_FILE"
        echo "Rolled back to: $BACKUP_FILE"
    else
        echo "No backup found"
        return 1
    fi
}

# Validate migrated state
state-validate() {
    local required_fields=(
        "workflow_state"
        "goal"
        "phases"
        "tasks"
        "agents"
        "dependencies"
        "progress"
    )

    echo "Validating state v2.0..."

    for field in "${required_fields[@]}"; do
        if grep -q "^$field:" "$STATE_FILE"; then
            echo "  ✓ $field"
        else
            echo "  ✗ $field (MISSING)"
            return 1
        fi
    done

    echo "State validation passed!"
}

# Main command router
case "${1:-}" in
    check)   state-check-version ;;
    backup)  state-backup ;;
    migrate) state-migrate ;;
    rollback) state-rollback ;;
    validate) state-validate ;;
    *)
        echo "Usage: $0 {check|backup|migrate|rollback|validate}"
        exit 1
        ;;
esac
