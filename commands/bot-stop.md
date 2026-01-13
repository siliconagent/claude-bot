---
description: Stop workflow and save state
---

# Stop Claude-Bot Workflow

Gracefully stop the current workflow and save its state.

## Usage

```
/bot-stop
```

## What It Does

- Saves current workflow state to `.claude/claude-bot.local.md`
- Stops any running agents
- Updates status to "paused"
- Returns control to user

## When to Use

- When you need to interrupt the workflow
- Before closing your session
- When you want to switch to manual work
- When the workflow is going in the wrong direction

## Example

```
/bot-stop
```

Output:
```
Workflow paused. State saved.
Use /bot-resume to continue or /bot-start for a new goal.
```

## Notes

- State is preserved across sessions
- Use /bot-status to see what was saved
- Use /bot-resume to continue later
- Workflow can be resumed even after context compaction
