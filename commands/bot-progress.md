---
description: Display detailed progress view
---

# Bot Progress Command

Display detailed progress of the autonomous workflow.

## Usage

```
/bot-progress
```

## Output

```markdown
╔══════════════════════════════════════════╗
║        Claude-Bot Progress              ║
╚══════════════════════════════════════════╝

📊 Overall Progress: [████████████░░░░░░░░] 60%

Status: Active
Phase: 5/9 - Build
Started: 2 hours ago

📈 Task Breakdown:
  ✅ Completed:   12 tasks
  🔄 In Progress:  3 tasks
  ⏳ Pending:     5 tasks
  🚫 Blocked:     0 tasks

🏆 Milestones:
  ✅ Planning Complete
  ✅ Design Approved
  ✅ Implementation Done
  🔄 Building...
  ⏳ Testing
  ⏳ Documentation

⏱️  Time Tracking:
  Elapsed: 2h 15m
  Est. Remaining: 1h 30m
  ETA: Today 3:45 PM

🤖 Active Agents:
  • builder: Building project (task-8) [85%]
  • validator-1: Code review (waiting for build)
  • validator-2: Code review (waiting for build)

🔗 Critical Path:
  task-1 → task-2 → task-8 → task-9 → task-10
  (4h total effort, 2h remaining)
```

## Implementation

Run `${CLAUDE_PLUGIN_ROOT}/scripts/progress-calculator.sh detail` to generate progress view.
