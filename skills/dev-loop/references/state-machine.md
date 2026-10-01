# Dev loop state machine

## state.json

```json
{
  "run": "2026-10-01-m1-account-sync",
  "target": "M1 · Account sync",
  "mode": "milestone",
  "lanes": 2,
  "budget": 2,
  "integration_branch": "main",
  "tip": "#58",
  "tickets": [
    {
      "id": 57, "key": "T1.2", "title": "Sync account status",
      "flag": "LANE", "state": "review round 1", "next": "judge findings",
      "seat": "Reviewer", "branch": "factory/57-sync-account-status",
      "base": "factory/56-account-model", "pr": null, "sha": "a19f003",
      "round": 1, "kept": 0, "blocked_by": [56], "notes": ""
    }
  ]
}
```

Write it after every signal. It is what `--resume` reads, what the board prints, and what `alf-seat acquire` reads to enforce `lanes` and `budget`.

Each dispatch has its own status file, `seats/<Seat>.<n>.json`. The board reads the latest one for each seat.

## Flags (board order)

| Flag | Meaning |
|---|---|
| PARK | stopped for one of the five reasons, failed the readiness gate, or a worker did not report; needs the human |
| LANE | in a lane: building, reviewing, fixing, or shipping |
| SWEEP | draft open, the Guardian is working its threads |
| READY | buildable now, waiting for a free lane |
| WAIT | blocked by an edge |
| SKIP | out of this run: already in human review, legacy seat, closed |
| DONE | draft open and swept; the human's turn |

## Transitions

| From | Signal | To | Action |
|---|---|---|---|
| WAIT | every blocker merged, or open as a PR to stack on | READY | |
| READY | `acquire` returns a seat (not NO_FREE_LANE / BUDGET_SPENT) | LANE `building` | dispatch `build`; label `factory:in-loop` |
| LANE `building` | `ALF developer DONE ... tests=green` | LANE `review round 1` | acquire Reviewer seat at `--ref <sha>`; dispatch `review` (round 1, full diff vs base) |
| LANE `building` | `... FAIL tests=red` | PARK | "tests red after build" + evidence path |
| LANE `review round N` | `ALF reviewer DONE findings=K path=F` | LANE `judging` | read F only; apply the ladder; write judged-rN.md |
| LANE `review round N` | findings file's first line is not `alf-review v1 <sha>` | PARK | "review not run: the reviewer did not follow the skill". Never treat it as a clean review |
| LANE `review round N` | `APPROACH: wrong` in the findings file | PARK | stop reason 1 |
| LANE `judging` | kept = 0 | LANE `shipping` | dispatch `build` in mode `ship` |
| LANE `judging` | kept > 0, N = 1 | LANE `fixing` | dispatch `build` in mode `fix` with judged-r1.md |
| LANE `judging` | Critical kept, N = 2 | PARK | stop reason 3 ("round 2: Critical survives") |
| LANE `judging` | only small Important kept, N = 2 | LANE `fixing` then `shipping` | fix, then ship without a round 3 |
| LANE `fixing` | `DONE ... tests=green` | LANE `review round 2` | `acquire reviewer --seat <round-1 seat> --ref <new sha>`; review the delta only |
| LANE `shipping` | `ALF developer DONE pr=#P sha=S` | SWEEP or DONE | record pr and sha; update `tip`; request the bot reviewer if configured |
| SWEEP | `ALF guardian DONE swept=#P,...` with #P not in `remaining` | DONE | |
| SWEEP | #P listed in `remaining` | SWEEP | picked up again on a later pass; after two passes with the same thread left, PARK it |
| any LANE | `DIED` / `SILENT` / `NOT_RUN` | PARK | "worker did not report: <log path>"; never retry silently |
| any LANE | `STOPPED reason=error_max_turns` or a budget stop | PARK | "hit its cap: the ticket is bigger than its size"; a planning fact |
| any LANE | developer reports `STOP reason=contract|registry|migration|unrelated-test|base-moved` | PARK | stop reasons 2, 4 and 5 |

## The ladder, precisely

For each finding in the reviewer's file:

1. **No evidence → drop.** A finding must cite a line, a failing command, or a search result. "Might be an issue" with nothing behind it is dropped with the reason "no evidence".
2. **Critical → fix.**
3. **Important → fix** when the reviewer's `est_lines` is under `ladder.fix_important_under_lines` (default 20). Otherwise **Not addressed**, listed for the human.
4. **Suggestion → dropped**, with a one-line reason ("naming preference", "style, no behaviour change").
5. **Reach findings** (outward contract changed, shared or registry path, deviation touched) are never dropped. If a fix is not small, the finding becomes *Not addressed* and is listed first in the PR body.

Write `judged-rN.md` as a table: id, severity, call, reason, finding. The Developer's fix dispatch reads only the *Fix* rows.

## Seats

| Role | Seats | Notes |
|---|---|---|
| Developer | Developer, Developer-2 | one ticket per dispatch; pushes before it leaves the seat |
| Reviewer | Reviewer, Reviewer-2 | detached at the head sha; its own worktree, because mutation testing writes to the working tree |
| Guardian | Guardian, Guardian-2 | outside the lane count; batches up to 5 PRs per session |
| Verifier | Verifier | one only: it binds the app's port |

A healthy busy run has two or three live workers, not six: a lane cannot use a Developer and a Reviewer at the same time, and the Guardian only runs when a queue has built up.
