---
name: verify
description: Stage 4 of the AI Light Factory. Proves a milestone, feature or PR set behaves correctly where it will actually run, by driving the running app end to end (Playwright) in every feature-flag state and recording each journey as PASS, FAIL, NOT RUN or N/A with an artefact. Checks that every planned ticket has a PR and that nothing else broke. Use when a milestone's PRs are drafted, or when someone asks to verify, QA or prove a feature before merge.
license: MIT
compatibility: Needs the app's dev server command and, for browser legs, a Playwright harness. Without one, browser legs are reported as NOT RUN.
---

# Verifier: prove it works where it will run

**Input:** `$ARGUMENTS`, one of: a milestone title, a named feature, or a PR list (`#57 #58 #61`). The scope decides what "promised" means.
**Output:** `.factory/verdicts/YYYY-MM-DD-<scope>.md` (format: `${CLAUDE_PLUGIN_ROOT}/templates/verdict.md`), plus a short comment on each PR in scope linking it.
**Cadence:** once per milestone or phase, not once per PR. Until a phase is nearly done there is usually nothing end to end to exercise, and verifying per ticket produces theatre.

Every earlier stage checks internal consistency: the code matches the ticket, the ticket matches the plan. This is the only stage that checks the world. A line without it catches bugs. A line with it also catches **wrong premises**, which cost an order of magnitude more. An implementation can match its spec exactly and still be wrong about the world.

There is one Verifier at a time, because it binds the app's port. Take the lock with `${CLAUDE_PLUGIN_ROOT}/bin/alf-seat acquire verifier`, which also gives you a clean worktree to run the app from, and release it when you finish. If the lock is taken, wait.

## Three claims, and they are not the same claim

### 1. It does what was promised
- **Every planned ticket has a PR.** Compare the plan file (or the milestone's issues) against the PRs. A dropped ticket leaves nothing to review, so no per-PR check ever notices it. List any that are missing.
- **The milestone's outcome, driven in the running app.** Drive the outcome the PRD describes, not each ticket's slice (the band already checked those).

### 2. Nothing else broke
- Find the flows that actually go through the changed files: search for callers, routes and jobs that reach them. Do not guess.
- Run them. **Name every flow you did not run.** "Regression: passed" with no list usually means the new feature was run twice.

### 3. The flag makes false safe
Not "is there a kill switch", but: **does OFF behave exactly as though the milestone never shipped?** This is the claim nobody tests, and the one that ships incidents. On release day, almost every account is in the OFF state.

A flag paired with an account setting is **two gates, not one**, so the matrix has three states:

| State | Must show | A failure means |
|---|---|---|
| Flag OFF | identical to before the milestone | the change leaks past its gate. Ship-blocking |
| Flag ON, setting OFF | still the old behaviour | a call site reads the flag alone, so the whole cohort is switched on without opting in |
| Flag ON, setting ON | the new behaviour, in full | the milestone did not deliver |

With no setting, there are two states. Whether the setting defaults to false decides whether the middle row is a real test or N/A. Look it up; do not assume.

Toggle flags the way `.factory/config.json` → `flags` says. Platform notes are in `${CLAUDE_SKILL_DIR}/references/flags.md`. Toggle only the gate under test: on some platforms "disable" also clears every targeting rule, which destroys the partial rollout you were trying to test against.

## Driving the app

- Start it with `commands.dev_server`, and wait until `commands.dev_url` answers.
- **Write the journey the PRD describes, not the code paths the diff touched.** A test derived from the implementation passes on an implementation that does the wrong thing correctly, which is exactly the failure this stage exists to catch.
- **Every PASS carries an artefact:** a trace, a screenshot, or a file and line. Without one, a verdict is an opinion.
- **Reference artefacts; never read them.** A page, a trace and its console are the largest things in the factory, and this seat runs on the largest model. Assert against the page, record the verdict and the artefact path, and open a trace only to explain a FAIL. Send command output to files.
- If there is no Playwright harness, say so. Report the browser legs as NOT RUN, and offer to add a minimal harness as its own ticket. Budget for it once rather than being surprised by it every milestone.

## Verdicts

Make one row per journey **per flag state**, not one row per journey with a note about flags. No blank cells. Every pair is:

| Verdict | Meaning |
|---|---|
| PASS | run, and it did the thing, with the artefact |
| FAIL | run, and it did not, with the trace and expected vs actual |
| NOT RUN | could not be reached, and why |
| N/A | does not apply, and why |

**NOT RUN is a result, not a hole in the report.** Silence reads as a pass. A verdict table with no NOT RUN rows on a real milestone is usually a report that stopped looking.

**Read the OFF rows first.** They say whether it is safe to merge; the ON rows only say whether it was worth merging. An OFF row that was not run makes the overall verdict **NOT VERIFIED**, however green the rest is.

## Failures route back up the line

For each FAIL, decide which stage should have caught it, and say so:
- **The code is wrong** (it does not behave as the plan said, and the code is the reason): goes back to the Developer as a new ticket, or a fix on the PR.
- **The plan is wrong** (it behaves as planned, and the plan was wrong about the world): goes back to `/alf:architect`. This is the expensive path, and the reason this stage exists.

## Finish

Commit the verdict file. Comment on each PR in scope: overall verdict, its own rows, and a link to the file. Do not mark anything ready. The human reads the verdict and merges.
