# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A collection of Claude Code plugins. The root `.claude-plugin/marketplace.json` acts as a local plugin registry (marketplace name: "anilanar"), and each plugin lives under `plugins/<name>/`.

## Plugin Structure

Each plugin has `.claude-plugin/plugin.json` (metadata) and optionally `hooks/` and/or `skills/` directories — not every plugin has both.

### Key conventions

- **plugin.json** — `name`, `version`, `description`. Version must stay in sync with the matching entry in marketplace.json.
- **hooks.json** — Keyed by event type (`SessionStart`, `Stop`, `Notification`, `PostToolUse`, etc.). `PostToolUse` hooks use a `matcher` field to filter by tool name. Commands use `${CLAUDE_PLUGIN_ROOT}` for paths relative to the plugin root.
- **Shell scripts** — Receive JSON on stdin (parsed with `jq`), use `set -euo pipefail`, output results on stdout (diagnostics to stderr).
- **SKILL.md** — YAML frontmatter (`name`, `description`, `user_invocable`, optional `model` and `allowed-tools`) followed by the skill prompt in markdown.
- **marketplace.json** — Root-level registry listing all plugins with name, description, version, and relative source path. Keep versions in sync with each plugin's plugin.json.

## Current Plugins

- **worktrees** (`plugins/worktrees/`) — Skills-only plugin (no hooks.json). The `install` skill writes worktree lifecycle hooks and scripts into the *target project's* `.claude/` directory. The `uninstall` skill reverses this. The `merge` skill handles merging worktree branches into parent branches with rebase and fast-forward-only merge. Supports stacked branches via `git config branch.<name>.worktree-parent`.
- **cmux** (`plugins/cmux/`) — Skills and hooks plugin. Skills provide topology control, browser automation, and markdown viewing. Hooks report cwd and git branch to the cmux sidebar via Unix socket when Claude Code enters/exits worktrees (`PostToolUse` on `EnterWorktree`/`ExitWorktree`).
- **tdd** (`plugins/tdd/`) — TDD workflow plugin with skills and agents. Runs a strict Red-Green-Refactor cycle where each phase is an isolated subagent. Agents escalate architectural decisions to the user.

## No Build/Test System

This repo has no package manager, build step, or test framework. Changes are validated by reading the scripts and skill definitions directly.
