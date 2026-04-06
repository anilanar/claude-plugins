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

## Step 4: Confirm

```
Added domain owner: {domain-name}

Files created:
- .claude/agents/owner-{domain-name}.md
- .tdd-owners/features/{domain-name}.md
- .tdd-owners/notes/{domain-name}.md

Updated:
- .tdd-owners/domains.md

The TDD workflow and /tdd:notify-owner will now include
this domain automatically.
```
