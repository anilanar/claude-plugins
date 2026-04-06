# tdd

A Claude Code plugin that enforces Test-Driven Development using isolated subagents. Each TDD phase (Red, Green, Refactor, Review) runs in its own context window, preventing the LLM from unconsciously designing tests around an implementation it's already planning. An adversarial reviewer with fresh context verifies that tests actually cover the requirement. Domain owners catch behavioral regressions that tests don't cover. Context isolation makes LLM-driven TDD honest.

## Installation

```sh
claude plugin marketplace add anilanar/tdd
claude plugin install tdd@anilanar
```

## Usage

The plugin activates automatically on implementation requests, or you can invoke it explicitly:

```
/tdd Add credit balance validation before processing diffs
```

```
> Implement a rate limiter for the /api/submit endpoint
```

```
> Add support for webhook signature verification
```

For large features, the orchestrator decomposes the work into small increments — each one a complete Red-Green-Refactor-Review cycle. It presents the breakdown for your approval before starting.

## Domain owners

Domain owners are per-project agents that each own a conceptual area of the codebase. They serve three purposes:

1. **Consult** — Before making non-trivial changes, fixing bugs, or making decisions in a domain, the main Claude Code session proactively asks the relevant owner for advice. The owner returns relevant invariants, cautions, and recommendations from its feature registry and notes — like a teammate you'd ask before touching their code.
2. **Review** — After a change passes the full test suite, owners check whether their domain's behavioral invariants still hold, catching regressions that existing tests don't cover.
3. **Maintain** — After a successful change, owners update their own feature registries so domain knowledge never goes stale.

Domains are conceptual, not directory-shaped. A "baselines" domain might span CLI code, API endpoints, git integration, and storage layers. The orchestrator reasons semantically about which domains a change affects.

### Proactive consultation (outside the TDD cycle)

The TDD cycle handles REVIEW and MAINTAIN automatically. CONSULT works in any session, not just TDD ones — bug fixes, refactors, exploration, code review, architecture questions.

To make this ambient, `/tdd:owner-bootstrap` and `/tdd:owner-add` write a static `.tdd-owners/CLAUDE.md` with "when to consult" guidance, and (with your confirmation) append a one-line `@.tdd-owners/CLAUDE.md` import to your project root `CLAUDE.md`. Claude Code loads that import at session start, so every session knows owners exist and when to invoke them. The owner's `description` frontmatter also invites proactive consultation, which drives Claude Code's subagent routing.

Owners respond in CONSULT mode with one of three statuses:

- **`ADVICE`** — relevant invariants, cautions, recommendations, and file references
- **`OUT_OF_SCOPE`** — the question isn't in this domain (the cheap-decline path, so owners don't improvise)
- **`INSUFFICIENT_CONTEXT`** — the owner needs more information before advising

CONSULT is **read-only** — owners never modify files in this mode. To record a discovery *after* the fact, use `/tdd:notify-owner` instead.

To disable ambient consultation, delete the `@.tdd-owners/CLAUDE.md` line from your project `CLAUDE.md`. The owners themselves still work — they just won't be invoked automatically.

### Setting up owners

```
/tdd:owner-bootstrap
```

The bootstrap skill analyzes your git history (co-change patterns, commit message themes, fix/revert patterns) to propose domain boundaries. You review and adjust the proposals, then it generates feature registries and owner agents for each domain.

### Adding an owner later

```
/tdd:owner-add auth — Sessions, OAuth providers, permissions, API key management
```

### Notifying an owner of a discovery

During bug fixes, code review, or exploration, you may discover something a domain owner should know about:

```
/tdd:notify-owner baselines — carry-forward logic silently skips deleted files, this is intentional but undocumented
```

### File layout

After bootstrap, your project will have:

```
.tdd-owners/
  domains.md                        # Domain descriptions (orchestrator reads this)
  CLAUDE.md                         # Static "when to consult owners" guidance
  features/{domain}.md              # Feature registries per domain
  notes/{domain}.md                 # Per-domain experiential notes
.claude/
  agents/
    owner-{domain}.md               # Per-domain agent definitions
CLAUDE.md                           # Your project CLAUDE.md, with
                                    # `@.tdd-owners/CLAUDE.md` appended
```

Owner data lives outside `.claude/` so owner agents can write to it without triggering Claude Code's stricter "configuration change" permission prompts. The agent definitions themselves stay under `.claude/agents/` because that's where Claude Code loads them from. The `@.tdd-owners/CLAUDE.md` import is the only change bootstrap makes to your project root CLAUDE.md, and it always asks before modifying it.

## How escalation works

Agents escalate when they hit decisions that need human judgment:

- **Ambiguous requirements** — "should this validate email format or just non-empty?"
- **Architecture decisions** — "this needs a new service; here are 3 approaches"
- **Scope questions** — "this would touch 8 files; should I narrow the scope?"

When an agent escalates, the orchestrator stops and presents you with the agent's findings, options, and recommendation. You decide, and the cycle resumes with your decision as context.

The reviewer can also return `CHANGES_REQUESTED` with specific file:line issues. You'll see the issues and decide whether to fix them. Fixes re-enter the GREEN phase and get reviewed again, up to 3 rounds before escalating to you.

## How memory works

Each agent uses `memory: project` scope. They remember:

| Agent | Remembers |
|-------|-----------|
| **Test writer** | Test conventions, domain edge cases, project structure |
| **Implementer** | Module coupling, initialization patterns, gotchas |
| **Refactorer** | Code smells, architectural boundaries, tech debt |
| **Reviewer** | Recurring issues, quality standards, false positive calibration |
| **Owner** (per domain) | Cross-domain coupling, invariant calibration, domain boundary ambiguities |

Memory accumulates across sessions and can be committed to git. Review `.claude/memory/` periodically to prune stale entries.

## Design philosophy

1. **Context isolation** — Each phase runs in a separate subagent. The test writer never sees implementation plans. This prevents the LLM from "cheating" by writing tests that match the implementation it's already decided on.

2. **Sequential phases** — Red must complete before Green starts. Green must complete before Refactor starts. No parallelism — this is inherently sequential work.

3. **Human-in-the-loop** — Agents escalate architectural decisions, ambiguity, and scope questions to you. They present options with tradeoffs and their recommendation, but you make the call.

4. **Deterministic gates first, LLM gates second** — The full test suite runs before spending tokens on owner reviews. Cheap checks catch most regressions; owners catch the rest.

5. **Owners maintain their own docs** — The agent that just reviewed a change is the one that updates the feature registry — while it has full context. This solves the documentation staleness problem.

6. **Memory compounds** — Each owner invocation makes the next one better. Owners accumulate experiential knowledge about coupling patterns, false positives, and domain boundaries.

## License

MIT
