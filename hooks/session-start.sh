#!/bin/bash
# session-start.sh - Detect incomplete workflow and offer resume

# This hook runs at session start
# It checks for incomplete workflows and notifies the user

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

# Check if workflow is active or paused
STATUS=$(awk '/^workflow_state:/,/^goal:/' "$STATE_FILE" | grep "status:" | cut -d: -f2 | xargs)

if [[ "$STATUS" == "active" ]] || [[ "$STATUS" == "paused" ]] || [[ "$STATUS" == "blocked" ]]; then
  # Output resume prompt - this will be shown to the user
  cat << 'EOF'

🤖 Claude-Bot: Incomplete workflow detected!

You have an active workflow that was interrupted.
Use /bot-status to see current state or /bot-resume to continue.
EOF
fi

exit 0
