---
name: notify-owner
description: "Route a discovery or observation to the right domain owner — used during bug fixes, code review, or exploration"
user_invocable: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - Agent
---

# Notify Owner — Route Knowledge to Domain Owners

You route ad-hoc discoveries to the right domain owner. This is used outside the TDD cycle — during bug fixes, code review, exploration, or any time someone discovers something a domain owner should know about.

> **NOTIFY vs CONSULT.** `/tdd:notify-owner` is **post-hoc**: you already know something the owner should record (e.g. an undocumented invariant you just discovered). If instead you want **pre-hoc advice** — "I'm about to do X in your domain, what should I watch for?" — invoke the owner subagent directly with `MODE: CONSULT`. The owner will return `ADVICE` with relevant invariants, cautions, and recommendations. CONSULT is read-only; NOTIFY writes to the owner's notes and registry.

## Prerequisites

- `.tdd-owners/domains.md` must exist

## Input

The user invokes this with an observation and optionally a domain name:

```
/tdd:notify-owner baselines — carry-forward logic silently skips deleted files, this is intentional but undocumented
```

```
/tdd:notify-owner The billing webhook handler assumes idempotency but doesn't actually check for duplicate event IDs
```

## Step 1: Determine target domain(s)

If the user specified a domain name, verify it exists in `.tdd-owners/domains.md`.

If not specified:
1. Read `.tdd-owners/domains.md`
2. Based on the observation content and the domain scope descriptions, determine which domain(s) are affected
3. If ambiguous, present the domain list and ask the user which one(s) to notify

## Step 2: Notify the owner(s)

For each target domain, spawn its owner agent in NOTIFY mode:

```
Agent: owner-{domain-name}
Prompt:
  MODE: NOTIFY
  DOMAIN: {domain-name}
  OBSERVATION: {the user's observation, verbatim}
  CONTEXT: {any additional context — e.g., which file the user was looking at, what they were debugging}
```

## Step 3: Report back

Present the owner's response to the user:

```
Notified owner-{domain-name}:
  Assessment: {owner's assessment}
  Changes: {what the owner recorded, or "nothing — not relevant"}
```

If multiple domains were notified, show each response.
