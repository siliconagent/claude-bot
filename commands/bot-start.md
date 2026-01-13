---
description: Start autonomous 7-phase workflow
---

# Start Claude-Bot Workflow

Start the autonomous multi-agent workflow for the given goal.

## Usage

```
/bot-start [goal]
```

## Arguments

- **goal** (required): The development goal to work on (e.g., "Add user authentication", "Create REST API")

## Workflow Phases

The coordinator will orchestrate the following phases:

1. **Plan**: Break down the goal into tasks
2. **Explore**: Analyze the codebase (parallel agents)
3. **Design**: Create architecture design (sequential approaches)
4. **Implement**: Write/modify code
5. **Validate**: Review code quality (parallel agents)
6. **Test**: Run tests and builds
7. **Document**: Generate documentation

## Example

```
/bot-start Add JWT authentication to the API
```

## Notes

- Use /bot-status to check progress
- Use /bot-resume if workflow is interrupted
- Use /bot-stop to save and exit
- The workflow pauses on blockers requiring user input
