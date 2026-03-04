#!/bin/bash
set -euo pipefail

input=$(cat)
worktree_path=$(echo "$input" | jq -r '.worktree_path')

branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
git worktree remove "$worktree_path" --force 2>/dev/null || rm -rf "$worktree_path"
if [ -n "$branch" ]; then
  git config --unset "branch.$branch.worktree-parent" 2>/dev/null || true
  git branch -D "$branch" 2>/dev/null || true
fi
