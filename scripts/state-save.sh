#!/bin/bash
# state-save.sh - Save workflow state to .local.md file

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

# Ensure directory exists
mkdir -p "$STATE_DIR"

# Save state
# Usage: state-save.sh "<state_yaml_content>"
if [ -n "$1" ]; then
  cat > "$STATE_FILE" << EOF
---
$1
---

# Claude-Bot State

This file contains the persistent state for the Claude-Bot autonomous workflow.
Do not edit manually - use /bot-status, /bot-resume, or /bot-stop commands.
EOF
  echo "State saved to $STATE_FILE"
else
  echo "Error: No state content provided" >&2
  exit 1
fi
