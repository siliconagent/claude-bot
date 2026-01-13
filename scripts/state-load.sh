#!/bin/bash
# state-load.sh - Load workflow state from .local.md file

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "No active workflow state found."
  exit 0
fi

# Extract and output YAML frontmatter
awk '/^---/{flag++;next} flag{print}' "$STATE_FILE"
