---
description: Display current workflow state
---

# Claude-Bot Status

Display the current state of the autonomous workflow.

## Usage

```
/bot-status
```

## Output

Displays:
- Current workflow status (active, paused, completed, blocked)
- Current phase and progress
- Original goal
- Blockers (if any)
- Recent agent activity
- Next actions

## Example Output

```
🤖 Claude-Bot Status

Status: Active
Phase: 3/7 - Design

Goal: Add JWT authentication to the API

Progress:
  ✅ Phase 1: Plan (completed)
  ✅ Phase 2: Explore (completed)
  🔄 Phase 3: Design (in progress)
  ⏳ Phase 4: Implement (pending)
  ⏳ Phase 5: Validate (pending)
  ⏳ Phase 6: Test (pending)
  ⏳ Phase 7: Document (pending)

Recent Activity:
  • architect-1 completed: Token-based approach
  • architect-2 running: Session-based approach

Next Actions:
  • Complete architect-2
  • Present options to user
```

## Notes

- Works even if workflow is paused or blocked
- Use /bot-resume to continue a paused workflow
