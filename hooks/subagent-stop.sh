#!/bin/bash
# subagent-stop.sh - Capture agent results and update state

# This hook runs after any subagent completes
# It updates the workflow state with agent results

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# The agent results are passed via environment variables
# AGENT_NAME, AGENT_PHASE, AGENT_STATUS, AGENT_OUTPUT

# This is a placeholder - actual implementation would parse
# the agent results and update the state file accordingly
# The coordinator agent handles most of this logic

exit 0
