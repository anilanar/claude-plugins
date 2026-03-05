---
name: install
description: Add WorktreeCreate/WorktreeRemove hooks to the current project's .claude/settings.json so that git-ignored files (.mcp.json, .env, .claude/settings.local.json) are symlinked into worktrees automatically.
user_invocable: true
---

# Worktree Install

Add worktree hooks to the current project. This skill:

1. Writes the worktree lifecycle scripts into the project's `.claude/scripts/` directory
2. Reads `.claude/settings.json` in the current project (creates it if missing)
3. Adds `WorktreeCreate` and `WorktreeRemove` hook entries pointing to those scripts
4. Does NOT overwrite existing hooks — merges the worktree hooks alongside any existing hook config

## Scripts to install

Write these two files into the project.

### `.claude/scripts/worktree-create.sh`

```bash
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
```

### `.claude/scripts/worktree-remove.sh`

```bash
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
```

## Hook configuration to add

Add the following under the `"hooks"` key in `.claude/settings.json`, merging with any existing hooks. Use **relative paths** — hooks run from the project root:

```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/worktree-create.sh",
            "timeout": 600
          }
        ]
      }
    ],
    "WorktreeRemove": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/scripts/worktree-remove.sh"
          }
        ]
      }
    ]
  }
}
```

## Instructions

1. Create the directory `.claude/scripts/` in the project if it doesn't exist.
2. Write both scripts above to `.claude/scripts/worktree-create.sh` and `.claude/scripts/worktree-remove.sh`.
3. Make both scripts executable (`chmod +x`).
4. Read the project's `.claude/settings.json` (use `$CLAUDE_PROJECT_DIR/.claude/settings.json`). If it doesn't exist, start with `{}`.
5. If `WorktreeCreate` hooks already exist, tell the user and skip — don't duplicate.
6. Otherwise, add both `WorktreeCreate` and `WorktreeRemove` hooks to the file. Use relative paths as shown above.
7. Write the updated file, preserving all existing content.
8. Tell the user to restart Claude Code for the hooks to take effect.
