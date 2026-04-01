# tdd

A Claude Code plugin that enforces Test-Driven Development using isolated subagents. Each TDD phase (Red, Green, Refactor, Review) runs in its own context window, preventing the LLM from unconsciously designing tests around an implementation it's already planning. An adversarial reviewer with fresh context verifies that tests actually cover the requirement. This is the key insight: context isolation makes LLM-driven TDD honest.

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

Memory accumulates across sessions and can be committed to git. Review `.claude/memory/` periodically to prune stale entries.

## Design philosophy

1. **Context isolation** — Each phase runs in a separate subagent. The test writer never sees implementation plans. This prevents the LLM from "cheating" by writing tests that match the implementation it's already decided on.

2. **Sequential phases** — Red must complete before Green starts. Green must complete before Refactor starts. No parallelism — this is inherently sequential work.

3. **Human-in-the-loop** — Agents escalate architectural decisions, ambiguity, and scope questions to you. They present options with tradeoffs and their recommendation, but you make the call.

## License

MIT
