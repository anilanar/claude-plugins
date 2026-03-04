---
name: uninstall
description: Remove WorktreeCreate/WorktreeRemove hooks from the current project's .claude/settings.local.json.
user_invocable: true
---

# Worktree Uninstall

Remove worktree hooks from the current project.

## Instructions

1. Read the project's `.claude/settings.local.json` (use `$CLAUDE_PROJECT_DIR/.claude/settings.local.json`). If it doesn't exist, tell the user there's nothing to remove.
2. If `WorktreeCreate` or `WorktreeRemove` keys exist under `"hooks"`, remove them.
3. If the `"hooks"` object is now empty after removal, remove the `"hooks"` key entirely.
4. Write the updated file, preserving all other content.
5. Tell the user to restart Claude Code for the change to take effect.
