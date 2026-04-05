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

- **cmux** (`plugins/cmux/`) — Skills-only plugin. Skills provide topology control, browser automation, and markdown viewing.
- **tdd** (`plugins/tdd/`) — TDD workflow plugin with skills and agents. Runs a strict Red-Green-Refactor cycle where each phase is an isolated subagent. Domain owners review behavioral invariants and maintain feature registries. Agents escalate architectural decisions to the user.

## No Build/Test System

This repo has no package manager, build step, or test framework. Changes are validated by reading the scripts and skill definitions directly.
