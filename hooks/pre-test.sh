#!/bin/bash
# pre-test.sh - Prepare test environment with worktree and server

set -e

echo "Pre-test hook: Preparing test environment"

# Create worktree for testing
WORKTREE_ID="${CLAUDE_PLUGIN_ROOT}/scripts/worktree-manager.sh create test-playwright playwright-testing"

# Start dev server
SERVER_ID="${CLAUDE_PLUGIN_ROOT}/scripts/server-control.sh start"

echo "Test environment ready"
echo "Worktree: $WORKTREE_ID"
echo "Server: $SERVER_ID"
