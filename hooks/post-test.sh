#!/bin/bash
# post-test.sh - Cleanup test environment after testing

set -e

echo "Post-test hook: Cleaning test environment"

# Stop dev server
${CLAUDE_PLUGIN_ROOT}/scripts/server-control.sh stop

# Check test results and decide whether to archive or clean worktree
TEST_STATUS=$(cat ${STATE_DIR:-.claude}/claude-bot.test.status 2>/dev/null || echo "unknown")

if [[ "$TEST_STATUS" == "passed" ]]; then
  # Clean worktree on success
  ${CLAUDE_PLUGIN_ROOT}/scripts/worktree-manager.sh clean test-playwright
  echo "Worktree cleaned"
else
  # Archive worktree on failure for debugging
  ${CLAUDE_PLUGIN_ROOT}/scripts/worktree-manager.sh archive test-playwright
  echo "Worktree archived for debugging"
fi

echo "Test environment cleanup complete"
