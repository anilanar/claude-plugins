# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A collection of Claude Code plugins. The root `.claude-plugin/marketplace.json` acts as a local plugin registry, and each plugin lives under `plugins/<name>/`.

## Plugin Structure

Each plugin follows this layout:

```
plugins/<name>/
  .claude-plugin/plugin.json   # Plugin metadata (name, version, description)
  hooks/hooks.json              # Hook definitions (WorktreeCreate, WorktreeRemove, etc.)
  scripts/                      # Shell scripts invoked by hooks
  skills/                       # Skill definitions (one directory per skill)
    <skill-name>/SKILL.md       # Skill prompt with YAML frontmatter
```

### Key conventions

- **hooks.json** uses `${CLAUDE_PLUGIN_ROOT}` to reference scripts relative to the plugin root.
- **Shell scripts** receive JSON on stdin (parsed with `jq`), use `set -euo pipefail`, and output the result on stdout (diagnostics go to stderr).
- **SKILL.md** files have YAML frontmatter (`name`, `description`, `user_invocable`, optional `model` and `allowed-tools`) followed by the skill prompt in markdown.
- **marketplace.json** at the repo root lists all plugins with name, description, version, and relative source path.

## Current Plugins

- **worktrees** — Git worktree lifecycle: creates worktrees with symlinked git-ignored config files (`.mcp.json`, `.env`, `.claude/settings.local.json`), tears them down, and merges worktree branches back into parent branches. Supports stacked branches via a custom git config key `branch.<name>.worktree-parent`.

## No Build/Test System

This repo has no package manager, build step, or test framework. Changes are validated by reading the scripts and skill definitions directly.
