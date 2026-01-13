---
description: State persistence and management
---

# State Management Skill

This skill handles loading, saving, and validating workflow state.

## State File Path

`.claude/claude-bot.local.md`

## Reading State

To read the current state:

1. Check if file exists
2. Parse YAML frontmatter
3. Validate structure
4. Return state object

```yaml
# State returned as object with these fields
workflow_state:
  version: "1.0"
  status: "active|paused|completed|blocked"
  current_phase: "plan|explore|design|implement|validate|test|document|complete"
  started_at: "ISO timestamp"
  updated_at: "ISO timestamp"

goal:
  original_request: "string"
  refined_requirements: []
  accepted: true

phases:
  plan: { status, tasks, blockers }
  explore: { status, tasks, blockers }
  design: { status, tasks, blockers }
  implement: { status, tasks, blockers }
  validate: { status, tasks, blockers }
  test: { status, tasks, blockers }
  document: { status, tasks, blockers }

decisions_made: []
agent_history: []
next_actions: []
```

## Writing State

To save state:

1. Update state object
2. Convert to YAML
3. Write to .local.md with frontmatter

```markdown
---
workflow_state:
  version: "1.0"
  status: "active"
  current_phase: "plan"
  started_at: "2025-01-13T10:00:00Z"
  updated_at: "2025-01-13T10:05:00Z"
goal:
  original_request: "Add JWT auth"
  refined_requirements: []
  accepted: true
# ... rest of state
---

# Claude-Bot State

This file contains the persistent state for the Claude-Bot autonomous workflow.
Do not edit manually - use /bot-status, /bot-resume, or /bot-stop commands.
```

## Validation

A valid state must have:
- `workflow_state` with `status` and `current_phase`
- `goal` with `original_request`
- `phases` with entries for each phase

## State Transitions

Valid status transitions:
- `active` → `paused` (user stops)
- `active` → `blocked` (blocker detected)
- `paused` → `active` (resume)
- `blocked` → `active` (resolution provided)
- `active` → `completed` (all phases done)

Valid phase transitions:
- Must complete current phase before moving to next
- Can resume from any non-completed phase

## Utility Functions

### Check for Active Workflow

```bash
# Returns true/false
if [ -f ".claude/claude-bot.local.md" ]; then
  STATUS=$(grep "status:" .claude/claude-bot.local.md | head -1)
  if [[ "$STATUS" =~ (active|paused|blocked) ]]; then
    echo "true"
  fi
fi
echo "false"
```

### Get Current Phase

```bash
# Returns phase name
awk '/^current_phase:/ {print $2}' .claude/claude-bot.local.md
```

### Update Single Field

```bash
# Update status
sed -i '' 's/^status: .*/status: paused/' .claude/claude-bot.local.md
```

## Backup

Consider creating backups before major changes:
```
.claude/claude-bot.local.md.backup
```

## Cleanup

When workflow completes, consider archiving rather than deleting:
```
.claude/claude-bot.completed.2025-01-13.md
```
