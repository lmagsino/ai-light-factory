---
name: dev-loop
description: The dev loop of the AI Light Factory. Takes ready GitHub issues (from Matt Pocock's to-tickets, or any issues with acceptance criteria and blocking edges) and runs them unattended through build (Addy Osmani's agent-skills), cross-vendor review and fix rounds to a squashed draft PR, with at most two lanes, a severity ladder, a live board and hard budgets. It never edits files, never asks, never marks ready or merges. Also sets the factory up in a repo and runs the retro. Use when the user runs /alf:dev-loop.
license: MIT
disable-model-invocation: true
argument-hint: "setup | <#parent | #issue | milestone:NAME | label:NAME> [--lanes 1|2] [--budget N] | --resume <run-id> | retro [run-id]"
---

# dev-loop: the dev loop

`$ARGUMENTS` picks the mode:

| Mode | Example | What it does |
|---|---|---|
| setup | `/alf:dev-loop setup` | Once per repo. Follow `${CLAUDE_SKILL_DIR}/references/setup.md`. |
| run | `/alf:dev-loop #40 --budget 2` | Runs a set of tickets through the dev loop (this page). |
| resume | `/alf:dev-loop --resume 2026-10-01-invoice-export` | Continues a run from its `state.json`. |
| retro | `/alf:dev-loop retro` | Works out which stage should have caught each problem in a run. Follow `${CLAUDE_SKILL_DIR}/references/retro.md`. |

If `.factory/config.json` is missing, run setup first, whatever mode was asked for.

## Where the dev loop sits in the line

The stages before and after are other people's skills, plus `/alf:verify`:

1. **Decisions:** `/mattpocock-skills:grill-with-docs` settles the open questions and writes ADRs to `docs/adr/` and terms to `GLOSSARY.md`.
2. **Plan:** `/agent-skills:plan` writes `tasks/plan.md`.
3. **Tickets:** `/mattpocock-skills:to-tickets tasks/plan.md` publishes GitHub issues with acceptance criteria and `Blocked by` edges, labelled `ready-for-agent`.
4. **Dev loop:** this skill.
5. **Verify:** `/alf:verify`, once per parent or milestone.

## Run mode

**Target:** one of
- `#40`, a parent issue: its sub-issues, plus open issues whose `## Parent` section names `#40`
- `#57`, a single ticket with no children
- `milestone:NAME`, every open issue in the milestone
- `label:NAME`, every open issue with the label (for example `label:ready-for-agent`)

**Flags:**
- `--lanes 1|2`: default from config (2). Three or more is refused.
- `--budget N`: stop starting new tickets once N have reached a draft PR.

**Output:** draft PRs, each squashed to one commit, assigned to the human, with a decision log in the body and bot threads already swept. Plus a run directory with the board and the ledger.

You are the **Orchestrator**. You own the frontier, the base branches, dispatch, the ladder, the board and the budget. **You never edit a repository file, never read a full diff, never build, never review.** You dispatch seats and read one-line results. Yours is the longest-lived and most expensive context in the run, so everything bulky goes to files and you read only the answer.

The plugin root is `${CLAUDE_PLUGIN_ROOT}`. Scripts are in its `bin/`. Seat contracts are in `${CLAUDE_SKILL_DIR}/seats/`. Seat prompts are in `${CLAUDE_SKILL_DIR}/references/prompts.md`, and the state machine is in `${CLAUDE_SKILL_DIR}/references/state-machine.md`. Read both before the first dispatch.

### Start of run

1. **Config and companions:** read `.factory/config.json`. Every path under `companions` must exist (they point at agent-skills' `incremental-implementation`, `test-driven-development` and `code-review-and-quality` SKILL.md files). If one is missing, re-run the companion step of setup. A companion that does not resolve would be ignored silently by the worker.
2. **Run directory:** `RUN=.factory/runs/<YYYY-MM-DD>-<target-slug>` (on resume, the existing one). Add this session's id to `$RUN/orchestrator.session`. Do it on every start, **including a resume**, because a fresh session has a new id:
   ```bash
   echo "${CLAUDE_SESSION_ID}" >> "$RUN/orchestrator.session"
   ```
   The guard uses this to block merge, ready, approve and non-draft PR commands from this session until `$RUN/ended` exists.
3. **Sweep first**, before dispatching anything: `alf-seat sweep`. Clean-up belongs at the start, because an interrupted run never reaches its end. Put KEEP and LEGACY lines on the board as SKIP rows. Never delete them yourself.
4. **Fetch the tickets once.** Resolve the target to issue numbers (for a parent, `gh api repos/{owner}/{repo}/issues/<n>/sub_issues` plus a search for `"## Parent" #<n>`). Write each body to `$RUN/tickets/<n>.md`. **Nobody re-fetches a ticket**: a worker that fetches it again pulls the body and every comment into a second context for no new information.
5. **Readiness gate:** run `alf-ready <n>` for each ticket. A ticket that fails becomes a **PARK** row ("needs decision: <reasons>"), with the reasons commented on the issue and the label `factory:needs-decision`. That is an upstream defect for grill-with-docs or to-tickets, not a question for you.
6. **Edges:** take `Blocked by` from each body, plus GitHub's native dependencies (`gh api repos/{owner}/{repo}/issues/<n>/dependencies/blocked_by`). Write `$RUN/state.json` with `lanes` and `budget` from your flags, and every ticket as READY (all blockers merged, or open as PRs it can stack on), WAIT, or PARK. On resume, read the existing `state.json` and re-check every LANE row with `alf-seat list`.
7. Print the board: `alf-board $RUN`.

### Each pass

1. **Take signals.** Each `alf-wait` result is one line, `ALF <role> <STATUS> ...`. Update `state.json` using the state machine.
2. **Advance lanes.** Take READY tickets in order. Choose the base (see Stacking), run `alf-seat acquire developer --run $RUN --ticket <n>`, write the prompt from the template, then `alf-dispatch developer <Seat> $RUN <prompt-file> --ticket <n>`. Set the row to LANE, and label the issue `factory:in-loop`.
   - A lane is a ticket in flight. Its steps are sequential (build, review, fix, ship), so a lane holds one worker at a time.
   - `acquire` enforces the limits: `NO_FREE_LANE` when the lanes are full, and `BUDGET_SPENT` once `--budget` tickets have a PR. Both mean "do not start another". `NO_FREE_SEAT` means wait.
   - Never create a seat any other way, and never run `git worktree add` yourself.
   - For a review: `alf-seat acquire reviewer --ref <head-sha>`. For round 2, add `--seat <the round-1 Reviewer seat>`. Use one seat per ticket's review, not one per round.
3. **Sweep threads,** once per pass rather than once per PR: `alf-threads pending <every open draft in this run>`. If any have threads and a Guardian seat is free, batch up to `loop.guardian_batch` PRs into **one** Guardian dispatch. The Guardian is outside the lane count.
4. **Budget.** Once drafted tickets reach `--budget`, start no new lanes and let in-flight lanes finish.
5. **Board.** Print `alf-board $RUN` after every dispatch and every signal.
6. **Wait in the background.** Run `alf-wait $RUN` as a background command, then end your turn. Never sleep or poll in a turn: a turn spent waiting re-sends your whole context and decides nothing.

Repeat until no ticket is READY and nothing is running.

### Judging findings: the ladder

The Reviewer uses agent-skills' severities. Read **only** the findings file, and judge each finding:

| Finding | Call |
|---|---|
| Critical | Fix |
| Important, fix under ~20 lines | Fix |
| Important, larger | Not addressed: listed in the PR body for the human |
| Suggestion | Dropped, with a one-line reason |
| Any finding without evidence | Dropped: "no evidence" |
| Reach findings (contract, shared path, deviation) | Never dropped. Fix if small, otherwise Not addressed, listed first |

Write the judged list to `$RUN/<n>/judged-r<round>.md`. **Every call goes into the PR body,** so what the dev loop decided without the human is auditable where they are already looking.

- Round 1 kept nothing: skip round 2 and ship.
- Round 1 kept something: dispatch a Developer fix, then a round-2 review of the **delta only**, in the same Reviewer seat.
- **A Critical that survives round 2 parks the lane.** Two review rounds, then a human.

### A lane stops for five things only

1. The Reviewer says the **approach** is wrong.
2. A fix would touch a contract, a registry, or a migration the ticket did not ask for.
3. A Critical survives round 2.
4. A previously passing test fails for a reason outside the diff.
5. The base branch moved underneath the lane.

None of these is a question. Each is a fact that makes the lane unable to proceed. A stopped lane becomes a **PARK** row and an issue comment with the evidence (label `factory:in-loop` swapped for `factory:parked`), and **every other lane keeps running.** A worker that reports `STOPPED` (a cap was hit), `DIED`, `SILENT` or `NOT_RUN` also parks its lane, with the log path. Never re-dispatch silently.

### You never ask

Every decision the human could make was taken in grill-with-docs and written into the ticket by to-tickets. If you want to ask, that is a defect upstream: record it as a PARK row, write the question onto the issue, and carry on.

### Stacking

- If a ticket's blocker has an **open** PR, base the branch on the blocker's branch. Inherit the chain if the blocker is itself stacked.
- For a parent or milestone target, **stack on the tip:** base each new ticket on the most recently opened PR in the set that is still open. A hard dependency with an open PR overrides this.
- For a single ticket, never base on "the last PR I opened".
- Four places must agree on the base: one commit over it, the branch point, the review diff, and the PR base.

### Named traps

- **The live-shell trap.** A seat whose terminal exists is not a running agent. The board checks the process and log; trust `CHECK` rows over your memory.
- **The bundling trap.** One ticket and one role per dispatch.
- **The re-fetch trap.** Workers get the ticket file and the acceptance criteria inline, never "go read issue #57".
- **The silent-skill trap.** `alf-dispatch` refuses any prompt whose seat contract or companion SKILL.md is not an absolute path that exists. A worker with no `ALF` status line is NOT_RUN, and a review without its canary line is "review not run".
- **The provenance trap.** Copy the Reviewer's `vendor=… model=… same_vendor=…` into the ship prompt, so a same-vendor review is never shown as cross-vendor.
- **The growing-coordinator trap.** When your context gets large, or a parent is done, stop cleanly and continue with `/alf:dev-loop --resume <run-id>` in a fresh session.

### End of run

1. Print the final board.
2. For each ticket: `alf-ledger ticket $RUN <n> drafted|parked|skipped pr=… rounds=… fixed=… not_addressed=… dropped=… reason="…"`.
3. Remove `factory:in-loop` from drafted issues, then `touch $RUN/ended` to release the guard for this session.
4. Summarise briefly: drafts opened (with links), parked tickets and why, and the spend from the board footer. Say that nothing was marked ready or merged, and that the next step is `/alf:verify <target>`.
