# Changelog

## 0.2.0

The line now runs on two published skill packs instead of re-implementing them.

- Decisions, plan and tickets come from Matt Pocock's `grill-with-docs` and `to-tickets` and Addy Osmani's `agent-skills:plan`.
- The Developer and Reviewer seats follow agent-skills' `incremental-implementation`, `test-driven-development` and `code-review-and-quality`, read by absolute path so any agent can use them.
- `loop` becomes `/alf:dev-loop`, with `setup` and `retro` as modes. The build, review and guardian skills become seat contracts inside it.
- The readiness gate reads the issue format `to-tickets` writes, and GitHub's native "blocked by" links.
- The severity ladder uses agent-skills' Critical / Important / Suggestion.
- Dispatch checks every instruction file a seat is given, not only SKILL.md files.

## 0.1.0 (unreleased)

First public cut.

- Skills: `setup`, `architect`, `plan`, `tickets`, `loop`, `build`, `review`, `guardian`, `verify`, `retro`.
- Scripts (bash 3.2 compatible): `alf-seat`, `alf-dispatch`, `alf-wait`, `alf-board`, `alf-ready`, `alf-threads`, `alf-ledger`, `alf-stats`.
- Guard hook (`hooks/guard.py`, Bash and MCP): dev-loop workers and the running orchestrator cannot merge, mark ready, approve, open a non-draft PR, push to the integration branch, or force-push without a lease.
- Limits enforced by `alf-seat`: two seats per role, at most two lanes, and the run budget.
- Any agent per seat: `claude` and `codex` built in, any other CLI through a `command`. git and gh shims apply the guard to every worker, whatever agent it runs.
- Templates: config, decisions, plan, ticket, PR body with decision log, verdict, reach matrix, precedent map.
- Experimental: a GitHub Actions workflow that runs one `factory:ready` ticket through the dev loop.
