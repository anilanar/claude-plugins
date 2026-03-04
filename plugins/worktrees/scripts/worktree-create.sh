#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')

MAIN_REPO="$(git rev-parse --show-toplevel)"
WORKTREE_DIR="$MAIN_REPO/.claude/worktrees/$NAME"

# Record the parent branch (what HEAD points to now) so merge skill can find it
PARENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Create git worktree — reuse existing branch or create new
if git show-ref --verify --quiet "refs/heads/worktree/$NAME" 2>/dev/null; then
  echo "Branch worktree/$NAME exists, reusing" >&2
  git worktree add "$WORKTREE_DIR" "worktree/$NAME" >&2
else
  echo "Creating new branch worktree/$NAME from HEAD ($PARENT_BRANCH)" >&2
  git worktree add -b "worktree/$NAME" "$WORKTREE_DIR" HEAD >&2
fi

# Store parent branch in git config so /worktrees:merge knows where to merge back
# Uses custom config key instead of upstream tracking to avoid git push side effects
git config "branch.worktree/$NAME.worktree-parent" "$PARENT_BRANCH"

# Symlink git-ignored config files that exist in the main repo
for f in .mcp.json .env .env.local; do
  [ -f "$MAIN_REPO/$f" ] && ln -sf "$MAIN_REPO/$f" "$WORKTREE_DIR/$f"
done

if [ -f "$MAIN_REPO/.claude/settings.local.json" ]; then
  mkdir -p "$WORKTREE_DIR/.claude"
  ln -sf "$MAIN_REPO/.claude/settings.local.json" "$WORKTREE_DIR/.claude/settings.local.json"
fi

echo "$WORKTREE_DIR"
