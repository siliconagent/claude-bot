---
description: Display task hierarchy and dependencies
---

# Bot Tasks Command

Display all tasks with their hierarchy, dependencies, and status.

## Usage

```
/bot-tasks [filter]
```

## Filters

- `--status pending|in_progress|completed|blocked`
- `--agent agent_name`
- `--milestone`
- `--level 0|1|2`

## Output

```markdown
📋 Task Hierarchy

📦 task-1: Implement JWT Authentication (Milestone)
   ├─ task-1-1: Setup and Dependencies ✅
   │  └─ task-1-1-1: Install JWT packages ✅
   │
   ├─ task-1-2: Create Token Model and Service 🔄 75%
   │  ├─ task-1-2-1: Create UserToken model ✅
   │  ├─ task-1-2-2: Create TokenService 🔄 75%
   │  └─ task-1-2-3: Add token validation helpers ⏳
   │     Depends on: task-1-2-1
   │
   ├─ task-1-3: Authentication Middleware ⏳
   │  ├─ task-1-3-1: Create auth middleware ⏳
   │  └─ task-1-3-2: Add route protection ⏳
   │     Depends on: task-1-3-1
   │     Depends on: task-1-2
   │
   └─ task-1-4: Testing and Documentation ⏳
      Depends on: task-1-3

📦 task-2: Protected API Endpoints (Milestone)
   ├─ task-2-1: Create user endpoints ✅
   ├─ task-2-2: Add middleware to routes ⏳
   └─ task-2-3: Test protected endpoints ⏳

📦 task-3: Documentation ⏳
   Depends on: task-1, task-2

---
Dependencies:
  • task-1-2-2 requires task-1-2-1
  • task-1-3 requires task-1-2
  • task-3 requires task-1, task-2

Parallel Ready:
  • task-1-3-1 (no dependencies)
  • task-2-1 (no dependencies)

Critical Path:
  task-1-1 → task-1-2-1 → task-1-2-2 → task-1-3 → task-3
  (Estimated: 8 hours)

Agent Assignments:
  • implementer: 5 tasks (1 active, 3 pending, 1 completed)
  • tester: 3 tasks (all pending)
  • documenter: 2 tasks (pending)
```

## Implementation

Parse task state and display hierarchy using tree format from `${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh`.
