# Changelog

## 0.1.0 (unreleased)

First public cut.

- Skills: `setup`, `architect`, `plan`, `tickets`, `loop`, `build`, `review`, `guardian`, `verify`, `retro`.
- Scripts (bash 3.2 compatible): `alf-seat`, `alf-dispatch`, `alf-wait`, `alf-board`, `alf-ready`, `alf-threads`, `alf-ledger`, `alf-stats`.
- Guard hook (`hooks/guard.py`, Bash and MCP): band workers and the running orchestrator cannot merge, mark ready, approve, open a non-draft PR, push to the integration branch, or force-push without a lease.
- Limits enforced by `alf-seat`: two seats per role, at most two lanes, and the run budget.
- Any agent per seat: `claude` and `codex` built in, any other CLI through a `command`. git and gh shims apply the guard to every worker, whatever agent it runs.
- Templates: config, decisions, plan, ticket, PR body with decision log, verdict, reach matrix, precedent map.
- Experimental: a GitHub Actions workflow that runs one `factory:ready` ticket through the band.
