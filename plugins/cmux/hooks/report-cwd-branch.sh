#!/bin/bash
set -euo pipefail

# Receives hook JSON on stdin. Reads the cwd and reports it (plus the
# git branch) to cmux over its Unix socket so the sidebar stays in sync
# when Claude Code enters/exits worktrees or starts in one.
#
# cmux uses a newline-delimited protocol — each command must end with \n.
# We send both commands over a single connection for reliability.

[[ -S "${CMUX_SOCKET_PATH:-}" ]] || exit 0
[[ -n "${CMUX_TAB_ID:-}" ]]     || exit 0
[[ -n "${CMUX_PANEL_ID:-}" ]]   || exit 0

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -n "$CWD" ]] || exit 0

CMDS="report_pwd \"${CWD}\" --tab=${CMUX_TAB_ID} --panel=${CMUX_PANEL_ID}"
CMDS+=$'\n'

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
if [[ -n "$BRANCH" ]]; then
  DIRTY_OPT=""
  FIRST=$(git -C "$CWD" status --porcelain -uno 2>/dev/null | head -1 || true)
  [[ -n "$FIRST" ]] && DIRTY_OPT="--status=dirty"
  CMDS+="report_git_branch ${BRANCH} ${DIRTY_OPT} --tab=${CMUX_TAB_ID} --panel=${CMUX_PANEL_ID}"
  CMDS+=$'\n'
else
  CMDS+="clear_git_branch --tab=${CMUX_TAB_ID} --panel=${CMUX_PANEL_ID}"
  CMDS+=$'\n'
fi

printf '%s' "$CMDS" | nc -w 1 -U "$CMUX_SOCKET_PATH" >/dev/null 2>&1 || true
