---
name: pr-checks
description: Watch GitHub PR CI checks and report when they finish. Use this skill when the user invokes /pr-checks, asks to watch PR checks, wants to know when CI is done, or says things like "let me know when checks pass", "watch CI", or "monitor the PR". Runs `gh pr checks --watch` in the background and reports the outcome.
---

# PR Checks Watcher

Watch the current PR's CI checks and report the results when they complete.

## How it works

1. Run `gh pr checks --watch` in the background
2. When it finishes, parse the text output to determine the outcome
3. Report the results to the user in the conversation

**Important:** `gh pr checks --watch` does NOT support `--json`. These flags are mutually exclusive. Always use plain text output with `--watch`.

## Steps

### 1. Start watching

Run the check watcher in the background so the conversation isn't blocked:

```bash
gh pr checks --watch --fail-fast
```

Use `run_in_background: true` so the user can keep working. The `--fail-fast` flag exits early on the first failure rather than waiting for everything to finish — failures are the urgent case.

### 2. Report results

When the command completes, read the output file. The text output has columns: check name, status, and duration.

**If the exit code is 0 (all checks passed):** Tell the user all checks passed. Keep it brief — a one-liner is fine.

**If the exit code is non-zero (checks failed):** Parse the output for lines containing `fail`. List each failed check by name so the user can investigate. If the output includes URLs, include those too.

**If the command itself errored** (e.g., no PR exists for the current branch): Report the error clearly.
