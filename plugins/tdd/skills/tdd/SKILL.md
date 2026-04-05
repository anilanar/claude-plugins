---
name: tdd
description: "Run a TDD Red-Green-Refactor-Review cycle with isolated subagents. Auto-triggers on feature implementation requests."
user_invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Write
  - Edit
  - Bash
  - Agent
---

# TDD Workflow — Red-Green-Refactor Orchestrator

You orchestrate a strict Test-Driven Development cycle using isolated subagents. Each phase runs in a separate context window to prevent implementation knowledge from leaking into test design.

## When to activate

Activate when the user's request implies **new implementation work**:
- "implement", "add feature", "build", "create", "add support for"
- New endpoints, new modules, new behaviors, new integrations

Do NOT activate for:
- Bug fixes (the bug itself defines the test)
- Documentation changes
- Configuration or infrastructure changes
- Questions or exploration
- Refactoring existing code without new behavior

## Phase violations — NEVER do these

1. **Never** write implementation before a failing test exists
2. **Never** skip the refactor phase — even if the answer is "no changes needed"
3. **Never** skip the review phase
4. **Never** resolve escalations autonomously — always present them to the user and wait
5. **Never** pass implementation plans or reasoning between agents — only pass test files and outputs
6. **Never** let the reviewer edit files — it has Read and Bash only
7. **Never** loop more than 3 times on review feedback without escalating to the user

## Workflow

### Step 0: Understand and decompose

Before entering the cycle:

1. Confirm your understanding of the requirement with the user
2. If the feature is large, decompose it into **small, testable increments** — each increment should be one Red-Green-Refactor cycle
3. Present the breakdown to the user for approval
4. Each increment should be small enough that the test-writer can write 1-3 focused tests

### Step 1: RED — Write a failing test

Invoke the `tdd-test-writer` agent with:
- The requirement (or current increment's requirement)
- Any escalation context from previous attempts

```
Agent: tdd-test-writer
Prompt: Write a failing test for: <requirement>
```

**Gate:** Check the agent's status:
- `RED_CONFIRMED` → proceed to Step 2
- `NEEDS_CONTEXT` with a `BEHAVIORS` list → this is a **behavior enumeration checkpoint**. Present the behavior list to the user and ask: "Are these the right behaviors? Anything missing?" Once confirmed (or amended), re-run the test-writer with the approved behavior list as context.
- `NEEDS_CONTEXT` (other) → present the agent's findings to the user, wait for response, then re-run with context
- `BLOCKED` → present the blocker to the user, wait for resolution

Capture from the output: `TEST_FILE`, `TEST_COMMAND`, `FAILURE_OUTPUT`

### Step 2: GREEN — Make it pass

Invoke the `tdd-implementer` agent with:
- The test file path and failure output (NOT the test-writer's reasoning)
- The test command
- Any escalation context from previous attempts

```
Agent: tdd-implementer
Prompt: Make this failing test pass.
  Test file: <TEST_FILE>
  Test command: <TEST_COMMAND>
  Failure output: <FAILURE_OUTPUT>
```

**Gate:** Check the agent's status:
- `GREEN_CONFIRMED` → proceed to Step 3
- `NEEDS_CONTEXT` → present the agent's options/tradeoffs to the user, wait for decision, then re-run with context
- `BLOCKED` → present the blocker to the user, wait for resolution

Capture from the output: `FILES_CHANGED`

### Step 3: REFACTOR — Improve quality

Invoke the `tdd-refactorer` agent with:
- The files changed in Step 2
- The test file path
- The test command
- Any escalation context from previous attempts

```
Agent: tdd-refactorer
Prompt: Evaluate and optionally refactor the GREEN phase output.
  Files changed: <FILES_CHANGED>
  Test file: <TEST_FILE>
  Test command: <TEST_COMMAND>
```

**Gate:** Check the agent's status:
- `REFACTORED` or `CLEAN` → proceed to Step 4
- `NEEDS_CONTEXT` → present the agent's findings to the user, wait for decision, then re-run with context
- `BLOCKED` → present the blocker to the user, wait for resolution

### Step 4: REVIEW — Adversarial verification

Invoke the `tdd-reviewer` agent with:
- The test file path
- All implementation files from GREEN/REFACTOR phases
- The original feature requirement

Do NOT pass any reasoning, notes, or status messages from previous agents. The reviewer evaluates the code cold.

```
Agent: tdd-reviewer
Prompt: Review this TDD cycle output.
  Requirement: <original requirement>
  Test file: <TEST_FILE>
  Implementation files: <FILES_CHANGED>
```

**Gate:** Check the agent's status:
- `APPROVED` → cycle complete for this increment
- `CHANGES_REQUESTED` → present the reviewer's issues to the user. Ask: "Should I fix these? Any you want to skip?" On approval, re-enter GREEN phase with the reviewer's issues as context, then run REVIEW again (skip REFACTOR in fix rounds). Maximum 3 review rounds — after that, present remaining issues and ask the user how to proceed.
- `NEEDS_CONTEXT` → present to the user, wait for decision

### Step 5: Next increment or finish

If there are more increments:
- Summarize what was just completed
- Proceed to Step 1 with the next increment

If all increments are done, proceed to the summary.

## Summary

After all increments are complete, present:

1. **What was built** — files created/modified, behaviors added
2. **Escalation decisions** — what was escalated and how the user resolved each one
3. **Tech debt noted** — issues the refactorer identified but deferred
4. **Test coverage** — list of test cases written across all increments

## Handling escalations

When an agent returns `NEEDS_CONTEXT` or `BLOCKED`:

1. **Stop immediately** — do not attempt to resolve it yourself
2. **Present clearly** — show the user what the agent found, what decision is needed, and what options exist
3. **Wait** — let the user decide
4. **Resume** — re-invoke the same agent with the user's decision as additional context

Format escalations like:

```
🔴 The <phase> agent needs your input:

<agent's explanation>

Options:
1. <option A> — <tradeoff>
2. <option B> — <tradeoff>
3. <option C> — <tradeoff>

The agent leans toward option <N> because <reason>.

What would you like to do?
```
