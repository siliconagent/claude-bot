#!/bin/bash
# state-validate.sh - Validate state file structure

set -e

STATE_DIR="${CLAUDE_PLUGIN_ROOT}/../.claude"
STATE_FILE="${STATE_DIR}/claude-bot.local.md"

if [ ! -f "$STATE_FILE" ]; then
  echo "false"
  exit 0
fi

# Check for required fields
REQUIRED_FIELDS=("workflow_state" "goal" "phases")
YAML_CONTENT=$(awk '/^---/{flag++;next} flag{print}' "$STATE_FILE")

for field in "${REQUIRED_FIELDS[@]}"; do
  if ! echo "$YAML_CONTENT" | grep -q "^$field:"; then
    echo "false"
    exit 0
  fi
done

# Check workflow_state.status
if ! echo "$YAML_CONTENT" | grep -q "^workflow_state:"; then
  echo "false"
  exit 0
fi

echo "true"
