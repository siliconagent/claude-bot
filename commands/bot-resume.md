---
description: Resume interrupted workflow
---

# Resume Claude-Bot Workflow

Resume a workflow that was paused, blocked, or interrupted.

## Usage

```
/bot-resume [resolution]
```

## Arguments

- **resolution** (optional): Resolution to provided blockers
  - Required if workflow is blocked
  - Examples: "Use JWT tokens", "Prioritize performance over simplicity"

## When to Use

- After the workflow detected a blocker
- After context compaction interrupted the workflow
- After manually pausing with /bot-stop
- When starting a new session with an incomplete workflow

## Example

```
/bot-resume Use JWT tokens with refresh token rotation
```

## Notes

- Loads state from `.claude/claude-bot.local.md`
- Continues from the last active phase
- If blocked without resolution, will prompt for input
- If completed, will show summary and ask for new goal
