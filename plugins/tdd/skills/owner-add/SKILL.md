---
name: owner-add
description: "Add a new domain owner to an existing owner setup — generates agent, feature registry, and notes for one domain"
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

# Owner Add — Add a Single Domain Owner

You add one new domain owner to a project that already has owner infrastructure set up.

## Prerequisites

- `.tdd-owners/domains.md` must exist (run `/tdd:owner-bootstrap` first if not)
- The user provides a domain name and scope description, or you help them define one

## Input

The user invokes this with a domain name and optionally a scope description:

```
/tdd:owner-add auth — Sessions, OAuth providers, permissions, API key management
```

If the user only provides a name, ask them for a one-paragraph scope description before proceeding.

## Step 1: Check for conflicts

Read `.tdd-owners/domains.md` and verify:
- The domain name doesn't already exist
- The scope doesn't heavily overlap with an existing domain (if it does, ask the user if they want to expand the existing domain instead)

## Step 2: Explore the domain

Use an Explore agent to analyze the domain's code and git history. Use the same exploration prompt as the bootstrap skill:

```
Explore the "{domain-name}" domain in {project root directory}.
The scope is: {scope description}

Your task:
1. Find all source modules that belong to this domain
2. Find all test files for this domain
3. Read test files to infer behavioral contracts and invariants
4. Read source files to identify key exports, public APIs, and their callers
5. Run: git log --oneline --follow -- {key files} to understand evolution
6. Run: git log --oneline --grep='{domain name}' to find domain-specific commits
7. Look for fix/revert commits touching this domain

Produce a feature registry with this format per feature:

## {feature-name}
- **modules**: {comma-separated file paths}
- **behavior**: {one sentence — user perspective}
- **invariants**: {bulleted list — specific, not vague}
- **tests**: {file paths, or "none"}
- **edge-cases**: {tricky scenarios}

Be specific with invariants. Include cross-domain contracts.
```

**Present the feature registry to the user for review.** Wait for confirmation.

## Step 3: Generate files

After the user confirms the feature registry:

1. **Write feature registry** to `.tdd-owners/features/{domain-name}.md`

2. **Generate owner agent** at `.claude/agents/owner-{domain-name}.md` using the same template as the bootstrap skill (see `/tdd:owner-bootstrap` Step 5 for the full template). Replace `{DOMAIN_NAME}` and `{SCOPE_DESCRIPTION}` with actual values.

3. **Create notes file** at `.tdd-owners/notes/{domain-name}.md`:

```markdown
# {domain-name} — Owner Notes

_This file is maintained by the owner-{domain-name} agent. It records experiential observations about this domain — coupling patterns, pitfalls, and things future changes should watch for._
```

4. **Append to `domains.md`** — add the new domain entry to `.tdd-owners/domains.md`:

```markdown

## {domain-name}
Agent: owner-{domain-name}
Scope: {scope description}
```

## Step 4: CLAUDE.md integration (ambient owner awareness)

This step is idempotent and mirrors Step 7 of `/tdd:owner-bootstrap`. Its purpose is to make owner awareness ambient in every Claude Code session, so Claude Code consults owners proactively outside the TDD cycle. Users who ran `/tdd:owner-bootstrap` before this feature existed will get the integration the next time they add a domain.

### 4a. Ensure `.tdd-owners/CLAUDE.md` exists

If `.tdd-owners/CLAUDE.md` does not exist, write it with the exact static content defined in `/tdd:owner-bootstrap` Step 7a (the "Domain Owners" meta-instructions, including the "Consult an owner BEFORE", "Do NOT consult for", and "After making changes" sections). Do not customize it per-domain — it refers to `.tdd-owners/domains.md` for the current list.

If the file already exists, leave it alone.

### 4b. Ensure project root CLAUDE.md imports it

1. Check whether `CLAUDE.md` exists at the project root.
2. If it exists and already contains the exact line `@.tdd-owners/CLAUDE.md`, skip — nothing to do.
3. Otherwise, ask the user before modifying:

   ```
   To make owner guidance ambient in every Claude Code session, I'd like to add this
   import line to your project CLAUDE.md:

       @.tdd-owners/CLAUDE.md

   This loads the "when to consult owners" guidance automatically. You can remove it
   any time by deleting that line.

   Add it? [y/N]
   ```

4. On confirmation:
   - If `CLAUDE.md` does not exist, create it with just `@.tdd-owners/CLAUDE.md`.
   - If it exists, append a blank line followed by `@.tdd-owners/CLAUDE.md`.

5. If the user declines, note this in the Step 5 confirmation and continue — owners are still functional, just not ambient.

## Step 5: Confirm

```
Added domain owner: {domain-name}

Files created:
- .claude/agents/owner-{domain-name}.md
- .tdd-owners/features/{domain-name}.md
- .tdd-owners/notes/{domain-name}.md
{if .tdd-owners/CLAUDE.md was newly written this run:}
- .tdd-owners/CLAUDE.md

Updated:
- .tdd-owners/domains.md

Project CLAUDE.md: {one of}
- @.tdd-owners/CLAUDE.md import appended
- already contained the import (no change)
- created with @.tdd-owners/CLAUDE.md import
- user declined import — add `@.tdd-owners/CLAUDE.md` to CLAUDE.md manually to enable ambient owner awareness

The TDD workflow and /tdd:notify-owner will now include
this domain automatically. Outside the TDD cycle, Claude Code
will consult owner-{domain-name} proactively via MODE: CONSULT.
```
