#!/bin/bash
# worktree-manager.sh - Git worktree management for isolated testing

set -e

WORKTREE_STATE="${STATE_DIR:-.claude}/claude-bot.worktrees.yaml"
WORKTREE_BASE_DIR="${WORKTREE_BASE_DIR:-.git/worktrees}"

# Initialize worktree state
worktree-init() {
    if [[ ! -f "$WORKTREE_STATE" ]]; then
        mkdir -p "$(dirname "$WORKTREE_STATE")"
        cat > "$WORKTREE_STATE" << 'EOF'
# Worktree State for Claude-Bot
version: "2.0"
worktrees: []
EOF
    fi
}

# Create new worktree
# Usage: worktree-create "branch_name" "purpose"
worktree-create() {
    local branch_name="$1"
    local purpose="${2:-testing}"
    local worktree_id="worktree-$(date +%s)"

    # Check if we're in a git repo
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: Not in a git repository"
        return 1
    fi

    # Create worktree
    local worktree_path=".git/worktrees/${branch_name}"
    git worktree add "$worktree_path" -b "$branch_name" 2>/dev/null || {
        echo "Failed to create worktree"
        return 1
    }

    # Register in state
    worktree-init

    cat >> "$WORKTREE_STATE" << EOF

  - id: $worktree_id
    path: $worktree_path
    branch: $branch_name
    base_branch: $(git branch --show-current)
    purpose: $purpose
    status: active
    created_at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
    tasks: []
    test_results: []
    archived: false
EOF

    echo "Created worktree: $worktree_id"
    echo "  Path: $worktree_path"
    echo "  Branch: $branch_name"
    echo "  Purpose: $purpose"
}

# List all active worktrees
worktree-list() {
    worktree-init

    if [[ ! -s "$WORKTREE_STATE" ]] || ! grep -q "worktrees:" "$WORKTREE_STATE"; then
        echo "No worktrees registered"
        return 0
    fi

    echo "# Active Worktrees"
    grep -A 12 "^  - id:" "$WORKTREE_STATE" | \
        awk '
            /id:/ {
                id = $2
                printf "  %s\n", id
            }
            /path:/ {
                printf "    Path: %s\n", $2
            }
            /branch:/ {
                printf "    Branch: %s\n", $2
            }
            /purpose:/ {
                printf "    Purpose: %s\n", $2
            }
            /status:/ {
                printf "    Status: %s\n", $2
            }
            /archived:/ {
                if ($2 == "true") printf "    [ARCHIVED]\n"
            }
            /^  - id:/ {
                printf "\n"
            }
        '
}

# Get worktree by ID
# Usage: worktree-get "worktree_id"
worktree-get() {
    local worktree_id="$1"

    worktree-init

    grep -A 12 "id: $worktree_id" "$WORKTREE_STATE" || {
        echo "Worktree not found: $worktree_id"
        return 1
    }
}

# Clean up worktree
# Usage: worktree-clean "worktree_id"
worktree-clean() {
    local worktree_id="$1"
    local archive="${2:-false}"

    worktree-init

    # Get worktree path
    local worktree_path
    worktree_path=$(grep -A 5 "id: $worktree_id" "$WORKTREE_STATE" | grep "path:" | awk '{print $2}')

    if [[ -z "$worktree_path" ]]; then
        echo "Worktree not found: $worktree_id"
        return 1
    fi

    local branch_name
    branch_name=$(grep -A 5 "id: $worktree_id" "$WORKTREE_STATE" | grep "branch:" | awk '{print $2}')

    # Remove worktree
    if [[ "$archive" == "true" ]]; then
        echo "Archiving worktree: $worktree_id"
        # Mark as archived instead of removing
        sed -i.bak "/id: $worktree_id/,/^  - id:/s/archived: false/archived: true/" "$WORKTREE_STATE"
        sed -i.bak "/id: $worktree_id/,/^  - id:/s/status: active/status: archived/" "$WORKTREE_STATE"
        rm -f "${WORKTREE_STATE}.bak"
    else
        echo "Removing worktree: $worktree_id"

        # Remove git worktree
        git worktree remove "$worktree_path" 2>/dev/null || true

        # Delete branch
        git branch -D "$branch_name" 2>/dev/null || true

        # Remove from state
        awk "
            /id: $worktree_id/ { skip = 1 }
            skip && /^  - id:/ && !/id: $worktree_id/ { skip = 0 }
            !skip { print }
        " "$WORKTREE_STATE" > "${WORKTREE_STATE}.tmp" && mv "${WORKTREE_STATE}.tmp" "$WORKTREE_STATE"
    fi

    echo "Worktree cleaned"
}

# Archive worktree (keep for debugging)
# Usage: worktree-archive "worktree_id"
worktree-archive() {
    worktree-clean "$1" true
}

# Run command in worktree
# Usage: worktree-exec "worktree_id" "command"
worktree-exec() {
    local worktree_id="$1"
    local command="$2"

    worktree-init

    local worktree_path
    worktree_path=$(grep -A 5 "id: $worktree_id" "$WORKTREE_STATE" | grep "path:" | awk '{print $2}')

    if [[ -z "$worktree_path" ]]; then
        echo "Worktree not found: $worktree_id"
        return 1
    fi

    if [[ ! -d "$worktree_path" ]]; then
        echo "Worktree path does not exist: $worktree_path"
        return 1
    fi

    echo "Running in worktree $worktree_id: $command"
    (cd "$worktree_path" && eval "$command")
}

# Sync changes back to main branch
# Usage: worktree-sync "worktree_id"
worktree-sync() {
    local worktree_id="$1"

    worktree-init

    local worktree_path
    worktree_path=$(grep -A 5 "id: $worktree_id" "$WORKTREE_STATE" | grep "path:" | awk '{print $2}')

    if [[ -z "$worktree_path" ]]; then
        echo "Worktree not found: $worktree_id"
        return 1
    fi

    local branch_name
    branch_name=$(grep -A 5 "id: $worktree_id" "$WORKTREE_STATE" | grep "branch:" | awk '{print $2}')

    echo "Syncing worktree $worktree_id to main branch..."

    # Commit any changes in worktree
    (cd "$worktree_path" && git add -A && git commit -m "WIP: Auto-commit from worktree" 2>/dev/null || true)

    # Merge back to main
    git merge "$branch_name" -m "Merge worktree $worktree_id"

    echo "Sync complete"
}

# Prune all archived worktrees
# Usage: worktree-prune
worktree-prune() {
    worktree-init

    echo "Pruning archived worktrees..."

    grep "archived: true" "$WORKTREE_STATE" | while read -r line; do
        local worktree_id
        worktree_id=$(echo "$line" | grep "id:" | awk '{print $2}' || true)
        if [[ -n "$worktree_id" ]]; then
            worktree-clean "$worktree_id"
        fi
    done

    echo "Prune complete"
}

# Main command router
case "${1:-}" in
    init)       worktree-init ;;
    create)     worktree-create "$2" "$3" ;;
    list)       worktree-list ;;
    get)        worktree-get "$2" ;;
    clean)      worktree-clean "$2" "${3:-false}" ;;
    archive)    worktree-archive "$2" ;;
    exec)       worktree-exec "$2" "$3" ;;
    sync)       worktree-sync "$2" ;;
    prune)      worktree-prune ;;
    *)
        echo "Usage: $0 {init|create|list|get|clean|archive|exec|sync|prune}"
        exit 1
        ;;
esac
