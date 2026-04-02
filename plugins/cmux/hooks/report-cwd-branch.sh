#!/bin/bash
set -euo pipefail

# Receives PostToolUse JSON on stdin. Reads the new cwd and reports
# it (plus the git branch) to cmux over its Unix socket so the sidebar
# stays in sync when Claude Code enters/exits worktrees.

[[ -S "${CMUX_SOCKET_PATH:-}" ]] || exit 0
[[ -n "${CMUX_TAB_ID:-}" ]]     || exit 0
[[ -n "${CMUX_PANEL_ID:-}" ]]   || exit 0

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -n "$CWD" ]] || exit 0

# Report cwd
printf 'report_pwd "%s" --tab=%s --panel=%s' \
  "$CWD" "$CMUX_TAB_ID" "$CMUX_PANEL_ID" \
  | nc -w 1 -U "$CMUX_SOCKET_PATH" >/dev/null 2>&1 || true

# Report git branch
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
if [[ -n "$BRANCH" ]]; then
  DIRTY_OPT=""
  FIRST=$(git -C "$CWD" status --porcelain -uno 2>/dev/null | head -1 || true)
  [[ -n "$FIRST" ]] && DIRTY_OPT="--status=dirty"
  printf 'report_git_branch %s %s --tab=%s --panel=%s' \
    "$BRANCH" "$DIRTY_OPT" "$CMUX_TAB_ID" "$CMUX_PANEL_ID" \
    | nc -w 1 -U "$CMUX_SOCKET_PATH" >/dev/null 2>&1 || true
else
  printf 'clear_git_branch --tab=%s --panel=%s' \
    "$CMUX_TAB_ID" "$CMUX_PANEL_ID" \
    | nc -w 1 -U "$CMUX_SOCKET_PATH" >/dev/null 2>&1 || true
fi
