#!/usr/bin/env bash
# PostToolUse hook for EnterWorktree.
# Creates a cmux workspace and moves claude there.
# User opens neovim manually with `nv` when ready.
#
# PostToolUse stdin schema:
#   { "tool_name": "EnterWorktree", "tool_input": {...}, "tool_response": {...}, "cwd": "..." }

set -euo pipefail

CMUX=/Applications/cmux.app/Contents/Resources/bin/cmux

# Skip if not running inside cmux
if [ -z "${CMUX_SURFACE_ID:-}" ]; then
  exit 0
fi

INPUT=$(cat)

# The cwd after EnterWorktree is the worktree path
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$WORKTREE_PATH" ]; then
  exit 0
fi

WORKTREE_NAME=$(basename "$WORKTREE_PATH")

# Create new workspace (comes with a default surface we'll close)
WS_REF=$($CMUX new-workspace --name "$WORKTREE_NAME" --cwd "$WORKTREE_PATH" | awk '{print $2}')

# Get the default surface before moving claude in
DEFAULT_SURFACE=$($CMUX list-pane-surfaces --workspace "$WS_REF" | head -1 | awk '{print $2}')

# Move claude into the new workspace
$CMUX move-surface --surface "$CMUX_SURFACE_ID" --workspace "$WS_REF"

# Close the default surface
$CMUX close-surface --surface "$DEFAULT_SURFACE" --workspace "$WS_REF"

# Switch to the new workspace
$CMUX select-workspace --workspace "$WS_REF"
