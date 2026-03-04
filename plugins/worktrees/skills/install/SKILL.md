---
name: install
description: Add WorktreeCreate/WorktreeRemove hooks to the current project's .claude/settings.local.json so that git-ignored files (.mcp.json, .env, .claude/settings.local.json) are symlinked into worktrees automatically.
user_invocable: true
---

# Worktree Install

Add worktree hooks to the current project. This skill:

1. Reads `.claude/settings.local.json` in the current project (creates it if missing)
2. Adds `WorktreeCreate` and `WorktreeRemove` hook entries pointing to the shared scripts in `~/Development/claude-plugins/plugins/worktrees/scripts/`
3. Does NOT overwrite existing hooks — merges the worktree hooks alongside any existing hook config

## Hook configuration to add

Add the following under the `"hooks"` key in `.claude/settings.local.json`, merging with any existing hooks:

```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$HOME/Development/claude-plugins/plugins/worktrees/scripts/worktree-create.sh",
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
            "command": "$HOME/Development/claude-plugins/plugins/worktrees/scripts/worktree-remove.sh"
          }
        ]
      }
    ]
  }
}
```

## Instructions

1. Read the project's `.claude/settings.local.json` (use `$CLAUDE_PROJECT_DIR/.claude/settings.local.json`). If it doesn't exist, start with `{}`.
2. If `WorktreeCreate` hooks already exist, tell the user and skip — don't duplicate.
3. Otherwise, add both `WorktreeCreate` and `WorktreeRemove` hooks to the file, preserving all existing content.
4. Write the updated file.
5. Tell the user to restart Claude Code for the hooks to take effect.
