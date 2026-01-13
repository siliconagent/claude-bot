---
description: Core autonomous workflow orchestration
---

# Autonomous Workflow Skill

This skill implements the 7-phase autonomous development workflow.

## Workflow Phases

The workflow progresses through these phases:

1. **Plan** - Break down goal into tasks
2. **Explore** - Analyze codebase (parallel)
3. **Design** - Create architecture (sequential)
4. **Implement** - Write code
5. **Validate** - Review code (parallel)
6. **Test** - Run tests
7. **Document** - Generate docs

## State File Location

`.claude/claude-bot.local.md`

## State Schema

```yaml
workflow_state:
  version: "1.0"
  status: "active|paused|completed|blocked"
  current_phase: "plan|explore|design|implement|validate|test|document|complete"
  started_at: "ISO timestamp"
  updated_at: "ISO timestamp"

goal:
  original_request: "user's original request"
  refined_requirements: []
  accepted: true

phases:
  plan:
    status: "pending|in_progress|completed|blocked"
    tasks: []
    blockers: []
  # ... (same structure for each phase)

decisions_made: []
agent_history: []
next_actions: []
```

## Starting a Workflow

To start a new workflow:

1. Check for existing state
2. If exists and active, ask to resume or stop
3. If none or completed, create new state
4. Launch coordinator agent

## Resuming a Workflow

To resume a paused/blocked workflow:

1. Load existing state
2. Check current_phase
3. Apply any resolution provided
4. Launch coordinator to continue

## Phase Execution Rules

### Parallel Phases (Explore, Validate)

Use separate Task calls in a single message:

```xml
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Explore focus area 1</parameter>
</invoke>
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Explore focus area 2</parameter>
</invoke>
```

Wait for all to complete, then consolidate results.

### Sequential Phases (Design)

Launch one agent, wait for result, launch next:

```xml
<invoke name="Task">
<parameter name="subagent_type">general-purpose</parameter>
<parameter name="prompt">Design approach 1</parameter>
</invoke>
```

After result, launch approach 2 (can see approach 1's work).

### Linear Phases (Plan, Implement, Test, Document)

Launch single agent, wait for completion.

## Blocker Handling

When an agent detects a blocker:

1. Save state with blocker info
2. Update workflow_state.status = "blocked"
3. Update phase status = "blocked"
4. Present blocker to user
5. Wait for /bot-resume with resolution

## State Persistence

Save state after:
- Each phase completion
- Each agent completion
- Blocker detection
- Before major transitions

Load state when:
- /bot-resume is called
- Session starts (via hook)

## Agent History Format

```yaml
agent_history:
  - agent: "planner"
    phase: "plan"
    started_at: "ISO timestamp"
    completed_at: "ISO timestamp"
    status: "completed"
    summary: "Brief result summary"
```

## Completion

Workflow is complete when:
- All 7 phases are completed
- No blockers remain
- Documentation is generated

Set:
- workflow_state.status = "completed"
- current_phase = "complete"

Present summary to user.
