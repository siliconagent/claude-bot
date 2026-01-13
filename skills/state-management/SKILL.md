---
description: State persistence and management
---

# State Management Skill

This skill handles loading, saving, and validating workflow state for Claude-Bot v2.0.

## State File Path

`.claude/claude-bot.local.md`

## State Schema v2.0

```yaml
workflow_state:
  version: "2.0"
  status: "active|paused|completed|blocked"
  current_phase: "plan|explore|design|implement|build|validate|test|requirements|document|complete"
  started_at: "ISO timestamp"
  updated_at: "ISO timestamp"

goal:
  original_request: "string"
  refined_requirements: []
  acceptance_criteria: []  # NEW: acceptance criteria for requirements
  accepted: true

# NEW: Hierarchical task structure
tasks:
  - id: "task-1"
    description: "Main task"
    parent_id: null  # null for root tasks
    status: "pending|in_progress|completed|blocked|failed"
    complexity: "low|medium|high"
    estimated_effort: "hours"
    actual_effort: "hours"
    assigned_agent: "agent-name"
    dependencies: ["task-2"]
    dependents: ["task-3"]
    progress: 0-100
    subtasks: ["task-1-1", "task-1-2"]
    blockers: []
    artifacts: []
    milestone: true|false

# NEW: Agent assignment tracking
agents:
  - name: "planner"
    type: "agent"
    status: "idle|working|completed|blocked"
    current_task: "task-id"
    assigned_tasks: ["task-1", "task-2"]
    completed_tasks: []
    capabilities: ["planning", "task_decomposition"]
    started_at: "ISO timestamp"
    last_activity: "ISO timestamp"

# NEW: Dependency graph
dependencies:
  graph:
    "task-1": ["task-2", "task-3"]
    "task-2": ["task-4"]
  parallel_ready: ["task-4", "task-5"]
  critical_path: ["task-4", "task-2", "task-1"]

# NEW: Progress tracking
progress:
  total_tasks: 10
  completed_tasks: 5
  blocked_tasks: 1
  in_progress_tasks: 2
  overall_percentage: 50
  milestones_completed: 2
  milestones_total: 5
  estimated_completion: "ISO timestamp"

# NEW: Worktree management
worktrees:
  - id: "worktree-1"
    path: "/path/to/worktree"
    branch: "feature/test-automation"
    base_branch: "main"
    purpose: "playwright-testing"
    status: "active|archived|cleaned"
    created_at: "ISO timestamp"
    tasks: ["task-5", "task-6"]

# NEW: Build artifacts
build:
  status: "pending|running|success|failed"
  attempts: 0
  max_attempts: 3
  last_build_at: "ISO timestamp"
  artifacts: []
  errors: []

# NEW: Test results
testing:
  playwright:
    status: "pending|running|passed|failed"
    screenshots_dir: "/path/to/screenshots"
    test_results: []
    coverage: 0
  unit_tests:
    status: "pending|passed|failed"
    results: []
    coverage: 0

# NEW: Requirements validation
requirements_validation:
  status: "pending|in_progress|passed|failed"
  acceptance_criteria: []
  validation_results: []
  gaps: []

phases:
  plan: { status, tasks, blockers, started_at, completed_at }
  explore: { status, tasks, blockers, started_at, completed_at }
  design: { status, tasks, blockers, started_at, completed_at }
  implement: { status, tasks, blockers, started_at, completed_at }
  build: { status, tasks, blockers, started_at, completed_at }  # NEW
  validate: { status, tasks, blockers, started_at, completed_at }
  test: { status, tasks, blockers, started_at, completed_at }
  requirements: { status, tasks, blockers, started_at, completed_at }  # NEW
  document: { status, tasks, blockers, started_at, completed_at }

decisions_made: []
agent_history: []
next_actions: []
```

## Reading State

To read the current state:

1. Check if file exists
2. Parse YAML frontmatter
3. Validate version
4. Migrate if needed (v1.0 → v2.0)
5. Return state object

## Writing State

To save state:

1. Update state object with v2.0 fields
2. Convert to YAML
3. Write to .local.md with frontmatter
4. Validate structure

```markdown
---
workflow_state:
  version: "2.0"
  status: "active"
  current_phase: "plan"
# ... rest of v2.0 state
---

# Claude-Bot State

This file contains the persistent state for the Claude-Bot autonomous workflow v2.0.
Do not edit manually - use /bot-status, /bot-resume, or /bot-stop commands.
```

## Migration from v1.0 to v2.0

When loading v1.0 state:

1. Backup existing state file
2. Add new v2.0 fields with defaults
3. Convert flat tasks to hierarchical structure
4. Initialize agent tracking
5. Initialize dependency graph
6. Update version to "2.0"

Run migration script:
```bash
${CLAUDE_PLUGIN_ROOT}/scripts/state-migrate.sh migrate
```

## Validation

A valid v2.0 state must have:

**Required v1.0 fields:**
- `workflow_state` with `status`, `current_phase`, `version`
- `goal` with `original_request`
- `phases` with entries for each of 9 phases

**New v2.0 fields:**
- `tasks` - array of task objects (can be empty initially)
- `agents` - array of agent tracking objects
- `dependencies` - dependency graph structure
- `progress` - progress tracking object

## State Transitions

Valid status transitions (unchanged):
- `active` → `paused` (user stops)
- `active` → `blocked` (blocker detected)
- `paused` → `active` (resume)
- `blocked` → `active` (resolution provided)
- `active` → `completed` (all phases done)

Valid phase transitions (updated):
- Must complete current phase before moving to next
- New phases: `build`, `requirements`
- Can resume from any non-completed phase

## Utility Scripts

### State Management

```bash
# Load state
${CLAUDE_PLUGIN_ROOT}/scripts/state-load.sh

# Save state (pass YAML content)
${CLAUDE_PLUGIN_ROOT}/scripts/state-save.sh "$STATE_YAML"

# Validate state
${CLAUDE_PLUGIN_ROOT}/scripts/state-validate.sh

# Migrate to v2.0
${CLAUDE_PLUGIN_ROOT}/scripts/state-migrate.sh migrate
```

### Task Management

```bash
# Create hierarchical task
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh create "description" "parent_id" "complexity" "agent"

# Assign task to agent
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh assign "task_id" "agent_name"

# Update progress
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh progress "task_id" "percentage"

# Find ready tasks
${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh ready
```

### Dependency Resolution

```bash
# Build dependency graph
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh build-graph

# Find tasks ready for execution
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh find-ready

# Check for circular dependencies
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh check-circular

# Get critical path
${CLAUDE_PLUGIN_ROOT}/scripts/dependency-resolver.sh critical-path
```

### Progress Tracking

```bash
# Calculate overall progress
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh calculate

# Get milestone progress
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh milestones

# Generate progress bar
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh bar

# Detailed progress view
${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh detail
```

## Check for Active Workflow

```bash
# Returns true/false
if [ -f ".claude/claude-bot.local.md" ]; then
  VERSION=$(grep "version:" .claude/claude-bot.local.md | head -1 | awk '{print $2}')
  STATUS=$(grep "status:" .claude/claude-bot.local.md | head -1 | awk '{print $2}')

  if [[ "$STATUS" =~ (active|paused|blocked) ]]; then
    echo "true"
  fi
fi
echo "false"
```

## Get Current Phase

```bash
# Returns phase name
awk '/^current_phase:/ {print $2}' .claude/claude-bot.local.md
```

## Update Single Field

```bash
# Update status
sed -i '' 's/^status: .*/status: paused/' .claude/claude-bot.local.md

# Update current phase
sed -i '' 's/^current_phase: .*/current_phase: build/' .claude/claude-bot.local.md
```

## Backup and Cleanup

**Backup before migration:**
```
.claude/claude-bot.local.md.backup.20250113_100000
```

**Archive when completed:**
```
.claude/claude-bot.completed.2025-01-13.md
```

**Cleanup old states:**
```bash
# Remove archived states older than 30 days
find .claude -name "claude-bot.completed.*" -mtime +30 -delete
```
