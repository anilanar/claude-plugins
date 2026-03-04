---
name: merge
description: Merge the current worktree branch into its parent branch and push. Supports stacked branches — merges into the upstream tracking branch (not necessarily main). Use this when the user invokes /worktrees:merge from inside a worktree session and wants to land their work. Handles uncommitted changes, rebasing if the parent has moved ahead, and pushing — without ever force-pushing.
model: sonnet
allowed-tools:
  - Bash
---

Merge the current worktree branch into its **parent branch** and push. You're running inside a worktree session (working directory is somewhere under `.claude/worktrees/`).

This supports stacked branches: if the current branch tracks `feat/a`, it merges into `feat/a` — not necessarily `main`.

## Step 1: Get the current branch

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"
```

## Step 2: Find the parent branch

Run these commands **in order**, stopping at the first one that returns a non-empty value. You MUST try the git config check first — do NOT skip it.

**First**, check the custom git config key (set by the worktree-create hook). This is the primary and most reliable source:

```bash
git config "branch.$CURRENT_BRANCH.worktree-parent"
```

**Second**, only if the above returned nothing, try the upstream tracking ref:

```bash
git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null | sed 's|^origin/||'
```

**Third**, only if both above returned nothing, fall back to the main worktree's branch (read the first `branch` line from `git worktree list --porcelain`). This is typically `main`.

Store the result as `PARENT_BRANCH`.

## Step 3: Find the parent branch's worktree path

```bash
git worktree list --porcelain
```

Scan the output to find which worktree has the parent branch checked out (match the `branch refs/heads/<PARENT_BRANCH>` line). Store that path as `PARENT_WORKTREE`.

**If the parent branch is NOT checked out in any worktree**, the merge cannot proceed. Tell the user: "Parent branch `<PARENT_BRANCH>` is not checked out in any worktree. Please check it out first." Then stop.

## Step 4: Commit any uncommitted changes

Check for uncommitted work:

```bash
git status --porcelain
```

If there's anything staged or unstaged, commit it before proceeding. Look at the diff to write a meaningful commit message — don't just use "WIP". Stage everything and commit:

```bash
git add -A
git commit -m "<meaningful summary of the changes>"
```

## Step 5: Make sure the worktree branch is up to date with the parent

Fetch the latest from origin, then check whether the parent branch has moved ahead:

```bash
git fetch origin
git log HEAD..origin/<parent-branch> --oneline   # commits on parent not yet in your branch
```

If the parent has new commits, rebase your worktree branch on top of it so the eventual merge can be fast-forward:

```bash
git rebase origin/<parent-branch>
```

**Handling rebase conflicts**: If a conflict is straightforward (e.g., changes to different parts of a file, or one side clearly supersedes the other), resolve it and continue. If it's genuinely ambiguous — conflicting logic, unclear intent — pause and ask the user what they want to keep before continuing.

After resolving each conflict: `git rebase --continue`

## Step 6: Merge into the parent branch (from the parent's worktree)

The merge must happen in the worktree where the parent branch is checked out. Use `-C` to run git there without changing your current directory:

```bash
git -C <parent-worktree-path> merge --ff-only <current-branch>
```

`--ff-only` ensures you never create a merge commit — if the fast-forward fails (which it shouldn't after Step 3), stop and report the error rather than forcing anything.

## Step 7: Push

Push the parent branch from its worktree:

```bash
git -C <parent-worktree-path> push origin <parent-branch>
```

Never use `--force` or `--force-with-lease`. If the push is rejected because the remote has moved ahead, fetch and rebase (Step 5 again) rather than overriding.

## Done

Report what happened:
- The branch that was merged (`<current-branch>`)
- The parent branch it was merged into (`<parent-branch>`)
- The commit(s) it contained
- Confirmation that the push succeeded

If the parent is not `main`, remind the user that the parent branch itself may still need to be merged further up the stack.
