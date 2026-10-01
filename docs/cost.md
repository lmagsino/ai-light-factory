# Cost

## Pay at creation, not at inspection

A defect that survives to a human costs a review, a fix, a re-review and a round trip: three or four agent sessions. Preventing it costs the extra thinking of one effort step on one session. **Model is the expensive dial and effort is the cheap one.** So savings come from putting cheap seats on a smaller model, never from making a seat that judges think less.

## Seats

Every seat is configurable: any coding-agent CLI can fill it (`vendor` plus a `command` in `.factory/config.json`). The defaults below are the reference setup: Claude Code builds, Codex reviews.

| Seat | Default | Where it runs | Why |
|---|---|---|---|
| Decisions (`grill-with-docs`) | your session, highest effort | your session | Nothing re-examines it until the Verifier, on the most expensive rework path. |
| Plan and tickets (`agent-skills:plan`, `to-tickets`) | your session, high | your session | Its arithmetic is checked by nothing. A wrong edge produces a wrong stack. |
| Orchestrator | your session, **medium** | your session | It follows procedure rather than making judgements. The only medium seat. |
| Developer | `opus`, high | `claude -p` in a seat | Writes the code. |
| Reviewer | Codex default model, high | `codex exec` in a seat | A different vendor from the Developer, so its blind spots differ. A missed defect is a silent pass. |
| Guardian | `opus`, high | `claude -p` in a seat | Writes code that reaches the PR with no reviewer after it except you. |
| Verifier | `opus`, high | `claude -p` or your session | The last stage before merge. |

**The three upstream seats run in your session.** `/model` and `/effort` decide them, and no skill can enforce that. If you lower your session default to save tokens, all three follow it silently. That is the most expensive silent change available in this line. The dev loop's seats are pinned in `.factory/config.json`, so they cannot drift.

## Defaults that keep a week's allowance inside a week

Running many large-model workers at once burns an allowance much faster than linearly, because each worker's context grows, and so does the coordinator's from tracking them all. These defaults exist to prevent that.

| Default | Why |
|---|---|
| **Two lanes, hard ceiling** | Two is enough for a second ticket to be genuinely in flight while cost stays readable. It is also about what one human can review. `--lanes 3` is refused. |
| **One growing coordinator context, kept lean** | Workers report one status line and a file path, not their output. The orchestrator never reads a diff. |
| **Restart per milestone** | `state.json` is the memory. `/alf:dev-loop --resume <run>` in a fresh session beats one session that re-reads its whole history every turn. |
| **Wait in the background, not in turns** | `alf-wait` runs as a background shell. A turn spent waiting re-sends the whole context and decides nothing. |
| **Output to files** | Test runs, diffs, traces and logs go to files, and the agent reads only the result. Anything pasted stays in context for every later turn. |
| **Batch the Guardian** | One session sweeps about five PRs. Most of a short session is startup cost. |
| **Never batch the Reviewer or Developer** | Fresh context is the Reviewer's product. Two tickets in one Developer session is the bundling defect. |
| **Budgets** | `--budget N` tickets per run. Per-seat `max_usd` and `max_turns` are passed to Claude seats; other agents are bounded by the wait timeout and by their own settings. |

## Measure it

`alf-stats` reports sessions per ticket and cost per drafted ticket. Only Claude seats report dollars; count other agents' seats by sessions. If sessions per ticket climb well above four (build, review, ship, plus the occasional fix and second round), run `/alf:dev-loop retro`. Something upstream is leaking work into the dev loop.
