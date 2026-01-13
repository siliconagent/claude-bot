#!/bin/bash
# pre-compact.sh - Preserve state before context compaction

# This hook runs before context compaction
# It ensures the workflow state is properly saved

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Verify state file is valid
"${CLAUDE_PLUGIN_ROOT}/scripts/state-validate.sh"

# State is already being maintained by the coordinator
# This hook ensures it's flushed before compaction

exit 0
