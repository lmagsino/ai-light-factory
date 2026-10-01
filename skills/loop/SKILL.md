---
name: loop
description: Stage 3 of the AI Light Factory, the build band. Orchestrates one ticket or a whole GitHub milestone, unattended, through build, cross-vendor review and fix rounds to a squashed draft PR, with at most two lanes, a severity ladder, a live board and hard budgets. It never edits files, never asks, never marks ready or merges. Use when the user runs /alf:loop with an issue number or milestone.
license: MIT
disable-model-invocation: true
argument-hint: "<#issue | milestone> [--lanes 1|2] [--budget N] [--resume <run-id>]"
---

# The build band

**Input:** `$ARGUMENTS`, either `#57` (one ticket) or a milestone title, plus optional flags:
- `--lanes 1|2`, default from config (2). **Refuse 3 or more.**
- `--budget N`: stop starting new tickets once N have reached a draft PR. Without it, the band runs the milestone to the end.
- `--resume <run-id>`: continue a run from its `state.json` (use this after a restart or a context compaction).

**Output:** draft PRs, each squashed to one commit, assigned to the human, with a decision log in the body and bot threads already swept. Plus a run directory with the board and the ledger.

You are the **Orchestrator**. You own the frontier, the base branches, dispatch, the ladder, the board and the budget. **You never edit a repository file, never read a full diff, never build, never review.** You dispatch seats and read one-line results. Your session is the longest-lived and most expensive context in the run, so everything bulky goes to files and you read only the answer.

The plugin root is `${CLAUDE_PLUGIN_ROOT}`. Scripts are in its `bin/`, and every seat prompt names its skill by an absolute path under it (dispatch refuses anything else). Seat prompts are in `${CLAUDE_SKILL_DIR}/references/prompts.md`. The state machine is in `${CLAUDE_SKILL_DIR}/references/state-machine.md`. Read both before the first dispatch.

## Start of run

1. **Config:** read `.factory/config.json`. If it is missing, stop and point to `/alf:setup`.
2. **Run directory:** `RUN=.factory/runs/<YYYY-MM-DD>-<target-slug>` (on `--resume`, the existing one). Create it if needed, and add this session's id to `$RUN/orchestrator.session`. Do this on every start, **including a resume**, because a fresh session has a new id:
   ```bash
   echo "${CLAUDE_SESSION_ID}" >> "$RUN/orchestrator.session"
   ```
   The plugin's guard hook uses this to block merge, ready, approve and non-draft PR commands from this session until `$RUN/ended` exists.
3. **Sweep first**, before dispatching anything: `alf-seat sweep`. Clean-up belongs at the start, not the end. An interrupted run never reaches its end, so clean-up placed there leaves orphans forever. Put KEEP and LEGACY lines on the board as SKIP rows with their reason. Never delete them yourself.
4. **Fetch the tickets once.** For a milestone, run `gh issue list --milestone "<m>" --state open --json number,title,body,labels --limit 200`. Write each body to `$RUN/tickets/<n>.md`. Workers read that file. **Nobody re-fetches a ticket**, because a worker that fetches it again pulls the body and every comment into a second context for no new information.
5. **Readiness gate:** run `alf-ready --file $RUN/tickets/<n>.md` for each ticket. A ticket that fails becomes a **PARK** row: "needs decision: <reasons>". Comment the reasons on the issue, label it `factory:needs-decision`, and move on. This is an upstream defect, not a question for you to answer.
6. **Edges:** parse `Blocked by` from each body. Write `$RUN/state.json` (schema in the state-machine reference) with `lanes` and `budget` from your flags, and every ticket as READY (all blockers merged, or open as PRs it can stack on), WAIT, or PARK. On `--resume`, read the existing `state.json` instead and re-check every LANE row against the seats (`alf-seat list`).
7. Print the board: `alf-board $RUN`.

## Each pass

1. **Take signals.** Each `alf-wait` result is one line beginning `ALF <role> <STATUS> ...`. Update `state.json` for that ticket using the state machine.
2. **Advance lanes.** Take READY tickets in plan order. Choose the base (see Stacking), then `alf-seat acquire developer --run $RUN --ticket <n>`, write the prompt file from the template, and run `alf-dispatch developer <Seat> $RUN <prompt-file> --ticket <n>`. Set the row to LANE and label the issue `factory:in-band`.
   - A lane is a ticket in flight. Inside a lane the steps are sequential (build, review, fix, ship), so a lane holds one worker at a time.
   - `acquire` enforces the limits from `state.json`: it answers `NO_FREE_LANE` when `--lanes` tickets are already in flight, and `BUDGET_SPENT` once `--budget` tickets have a PR. Both mean "do not start another one". `NO_FREE_SEAT` means wait.
   - Never create a seat any other way, and never run `git worktree add` yourself.
   - For a review, run `alf-seat acquire reviewer --ref <head-sha>`. For round 2, add `--seat <the round-1 Reviewer seat>`: one seat per ticket's review, not one per round.
3. **Sweep threads.** Once per pass, not once per PR: `alf-threads pending <every open draft in this run>`. If any have unresolved threads and a Guardian seat is free, batch up to `band.guardian_batch` PRs into **one** Guardian dispatch. The Guardian is outside the lane count and never waits for a lane: it works on PRs that have already left the band.
4. **Budget.** When the number of drafted tickets reaches `--budget`, stop starting new lanes and let in-flight lanes finish.
5. **Board.** Print `alf-board $RUN` every pass, after every dispatch and every signal. It is the one surface the human reads.
6. **Wait in the background.** Run `alf-wait $RUN` as a background command, then end your turn. Do not sleep or poll in turns: a turn spent waiting re-sends your whole context and decides nothing. If a step produces no decision, it must not produce a turn.

Repeat until no ticket is READY and nothing is running.

## Judging findings: the ladder

When a review finishes, read **only** its findings file and judge each finding (detail in the state-machine reference):

| Severity | Call |
|---|---|
| Critical, High | Fix |
| Medium, fix under ~20 lines | Fix |
| Medium, larger | Not addressed: listed in the PR body for the human |
| Low | Dropped, with a one-line reason |

Write the judged list to `$RUN/<n>/judged-r<round>.md`. **Every call goes into the PR body.** What the band decided without the human must be auditable where the human is already looking.

- Round 1 kept nothing: skip round 2 and ship.
- Round 1 kept something: dispatch a Developer fix, then a round-2 review of **the delta only**, re-using the same Reviewer seat detached at the new sha. Use one seat per ticket's review, not one per round.
- **Round 2 still has a High: PARK.** Two review rounds, then a human (rule 5). If two rounds have not converged, a third will not either.

## A lane stops for five things only

1. The reviewer says the **approach** is wrong.
2. A fix would touch a contract, a registry, or a migration that the ticket did not ask for.
3. Round 2 still has a surviving High finding.
4. A previously passing test fails for a reason outside the diff.
5. The base branch moved underneath the lane.

None of these is a question. Each is a fact that makes the lane unable to proceed. A stopped lane becomes a **PARK** row and a comment on the issue with the evidence, with the label switched from `factory:in-band` to `factory:parked`, and **every other lane keeps running.**

A worker that reports `STOPPED` (it hit its turn or dollar cap), `DIED`, `SILENT` or `NOT_RUN` also parks its lane, with the log path. Never re-dispatch silently: a cap that is hit means the ticket was bigger than its size said, and that is a planning fact.

## You never ask

Every decision the human could make was taken in stage 1 and written into the ticket in stage 2. If you find yourself wanting to ask, that is a defect upstream. Record it as a PARK row with the question written onto the issue, and carry on. Do not stop the run to resolve it.

## Stacking

- If a ticket's blocker has an **open** PR, base the branch on that blocker's branch, and inherit its chain if it is itself stacked. A dependency on an unmerged PR is not a blocker. Branch off it, review against it, and base the PR on it.
- **In milestone mode, stack on the tip.** A milestone is one chain that touches the same files, so base each new ticket on the most recently opened PR of that milestone that is still open. A hard dependency with an open PR overrides this: the graph wins over the chain.
- **In single-ticket mode, never base on "the last PR I opened".** Two unrelated tickets stacked onto each other create a chain nobody intended.
- Four places must agree on the base: the commit count (one commit over the base), the branch point, the review diff, and the PR base. Otherwise the review reads the parent's commits as if they belonged to this change.
- A ticket with no edges, in a milestone that plainly needs them, is a Planner defect. Note it on the board and base the ticket on the integration branch.

## Named traps

- **The live-shell trap.** A seat whose terminal exists is not a running agent. The board checks the process id and log before printing. Trust `CHECK` rows over your own memory.
- **The bundling trap.** One ticket and one role per dispatch. Two tickets in one session is how worktrees get invented.
- **The re-fetch trap.** Workers get the ticket file path and the acceptance criteria, never "go read issue #57".
- **The silent-skill trap.** `alf-dispatch` refuses prompts whose SKILL.md path is not absolute or does not resolve. A worker result with no `ALF` status line is recorded as NOT_RUN, never as a pass. A review file without its canary first line is "review not run".
- **The provenance trap.** Every status line ends with `vendor=… model=… same_vendor=…`. Copy the Reviewer's into the ship prompt, so that a same-vendor review is never presented as a cross-vendor one.
- **The growing-coordinator trap.** If your context is getting large, or a milestone is done, stop cleanly. `state.json` is the memory, and `/alf:loop --resume <run-id>` in a fresh session continues the run.

## End of run

1. Final board.
2. For each ticket: `alf-ledger ticket $RUN <n> drafted|parked|skipped pr=… rounds=… fixed=… not_addressed=… dropped=… reason="…"`.
3. Remove `factory:in-band` from drafted issues. Then `touch $RUN/ended`, which releases the guard hook for this session.
4. Summarise in a few lines: drafts opened (with links), parked tickets and why, and spend from the board footer. Remind the human that nothing has been marked ready or merged, and that when the milestone is complete the next step is `/alf:verify <milestone>`.
