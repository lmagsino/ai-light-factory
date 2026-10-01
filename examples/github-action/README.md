# Label-triggered dev loop (experimental)

`alf-ticket.yml` runs **one** `factory:ready` issue through the dev loop inside GitHub Actions:

1. **Readiness gate.** An incomplete ticket is relabelled `factory:needs-decision`, and the job stops before any model runs.
2. **The dev loop, with one lane and a budget of one.** Build, then a cross-vendor review if `OPENAI_API_KEY` is set, then up to two fix rounds, then a squashed draft PR, opened only from green tests.
3. **Time budget:** `timeout-minutes: 60`. **Turn budget:** `--max-turns 300`. Per-seat dollar caps come from your `.factory/config.json`.

It is experimental because the dev loop was designed for a terminal, where the human is one board away. In CI, check the job log and the issue comments for PARK reasons.

Status: **untested.** It is a starting point, not a supported path. The local `/alf:dev-loop` is the supported path. If you get it working, a PR with what you changed is very welcome.
