# Claude-Bot Plugin

Autonomous multi-agent workflow plugin for Claude Code that replicates Auto-Claude functionality entirely in the terminal.

## Features

- **7-Phase Autonomous Workflow**: Plan → Explore → Design → Implement → Validate → Test → Document
- **Auto-Trigger Detection**: Automatically detects goal-oriented requests
- **State Persistence**: Full state saved across context compaction and session restarts
- **Parallel Agent Execution**: Multiple agents work simultaneously for exploration and validation
- **Blocker Handling**: Pauses workflow and prompts user when blockers are detected

## Installation

```bash
# Install the plugin
cc --plugin-dir /path/to/claude-bot
```

## Usage

### Auto-Trigger
Simply state your goal and Claude-Bot will detect it:
```
I need to build an authentication system
```

### Manual Commands

- `/bot-start [goal]` - Start autonomous workflow with a goal
- `/bot-status` - Display current workflow state and progress
- `/bot-resume` - Resume interrupted workflow from saved state
- `/bot-stop` - Gracefully stop workflow and save state

## Workflow Phases

| Phase | Agent | Purpose |
|-------|-------|---------|
| 1 | Planner | Creates task breakdown from requirements |
| 2 | Explorer | Analyzes codebase (3-4 parallel instances) |
| 3 | Architect | Designs architecture (3 sequential approaches) |
| 4 | Implementer | Creates/modifies files |
| 5 | Validator | Code review (3 parallel focuses) |
| 6 | Tester | Runs tests and builds |
| 7 | Documenter | Generates documentation |

## State File

State is persisted to `.claude/claude-bot.local.md` with YAML frontmatter containing:
- Current workflow status and phase
- Goal and requirements
- Phase progress and blockers
- Decisions made and agent history
- Next actions

## Architecture

```
claude-bot/
├── .claude-plugin/plugin.json      # Plugin manifest
├── commands/                       # User commands
├── agents/                         # Agent definitions
├── skills/                         # Workflow and state skills
├── hooks/                          # Event handlers
└── scripts/                        # State management utilities
```

## License

MIT
