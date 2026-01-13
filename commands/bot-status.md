---
description: Display current workflow state with v2.0 progress visualization
---

# Claude-Bot Status

Display the current state of the autonomous workflow with detailed progress tracking.

## Usage

```
/bot-status
```

## Output

Displays:
- Current workflow status (active, paused, completed, blocked)
- Current phase and progress
- Overall progress percentage with visual bar
- Milestone completion status
- Original goal
- Hierarchical task tree
- Agent activity and workload
- Blockers (if any)
- Critical path with ETA
- Recent agent activity
- Next actions

## Example Output

```
🤖 Claude-Bot Status v2.0

Status: Active
Phase: 5/9 - Build
Overall: ██████████░░░░░░░░ 50% (5/10 tasks)

Goal: Add JWT authentication to the API

📊 Progress:
  ✅ Phase 1: Plan (100%)
  ✅ Phase 2: Explore (100%)
  ✅ Phase 3: Design (100%)
  🔄 Phase 4: Implement (75%)
  🔄 Phase 5: Build (in progress)
  ⏳ Phase 6: Validate (pending)
  ⏳ Phase 7: Test (pending)
  ⏳ Phase 8: Requirements (pending)
  ⏳ Phase 9: Document (pending)

📦 Milestones:
  ✅ task-1: Authentication Setup (100%)
  🔄 task-2: Protected API Routes (60%)
  ⏳ task-3: Testing & Docs (0%)

📋 Task Hierarchy:
  📦 task-1: Authentication Setup ✅
     ├─ task-1-1: Dependencies ✅
     ├─ task-1-2: Token Service ✅
     └─ task-1-3: Auth Middleware ✅

  📦 task-2: Protected API Routes 🔄 60%
     ├─ task-2-1: User Endpoints ✅
     ├─ task-2-2: Route Protection 🔄 75%
     │  ├─ task-2-2-1: Middleware Setup ✅
     │  └─ task-2-2-2: Apply to Routes 🔄
     └─ task-2-3: Testing ⏳

🤖 Agent Activity:
  • planner: idle (completed task-1)
  • implementer: working on task-2-2-2
  • builder: idle (queued: task-3)
  • tester: idle (queued: task-2-3)
  • documenter: idle (queued: task-3)

⚡ Critical Path:
  task-2-2-2 → task-2-3 → task-3
  ETA: ~2 hours

Recent Activity:
  • implementer completed: task-2-2-1
  • builder running: npm run build (attempt 1/3)

Next Actions:
  • Complete task-2-2-2: Apply middleware to routes
  • Run validation phase
  • Start testing phase

Build Status:
  Status: 🔄 Running
  Attempt: 1/3
  Artifacts: pending

Worktrees:
  • test-playwright: active (/path/to/worktree)
```

## Implementation

Uses `${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh` for:
- Overall percentage calculation
- Milestone completion tracking
- Agent workload display
- Critical path analysis

Uses `${CLAUDE_PLUGIN_ROOT}/scripts/task-manager.sh` for:
- Hierarchical task tree
- Task status filtering
- Agent assignments

## Notes

- Works even if workflow is paused or blocked
- Use /bot-resume to continue a paused workflow
- Use /bot-progress for detailed progress metrics
- Use /bot-tasks for full task hierarchy with dependencies
