# Guardrails, and how each one is enforced

Plenty of tools have an agent write code. AI Light Factory is about the guardrails around the agents. Wherever possible each one is a script, a shim, a hook or a file, not a sentence a model might skip.

| Property | How it is enforced |
|---|---|
| **Decisions before code.** The band never asks you anything, because nothing is left to ask. | `alf-ready` rejects any ticket without checkbox acceptance criteria, decision-card references, explicit `Blocked by` edges, an XS or S size, and a test plan. A rejected ticket goes back up the line, not into a worktree. |
| **It stops at a draft PR, whatever agent is in the seat.** | Every worker runs with `bin/shims` first on its PATH. Its `git` and `gh` calls pass through the guard, which refuses merge, ready, approve, non-draft PRs, pushes to the integration branch, and force-pushes without a lease. Claude Code sessions get the same check as a `PreToolUse` hook (Bash and MCP), and that hook also covers the orchestrator while a run is live. Your own sessions are untouched. |
| **No PR without green tests.** | The Developer's ship step squashes, re-runs the full suite, and opens the draft only from green. Red means FAIL plus evidence, and no PR. |
| **A different vendor reviews.** | The Reviewer seat runs on a different vendor from the Developer, with fresh context. Its findings file must start with a canary line, or the review counts as *not run*. If both seats share a vendor, the PR says ⚠ *same-vendor review*. |
| **Every call is in the PR body.** | Findings are judged by a severity ladder: Critical and High are fixed; Medium is fixed when small, otherwise listed for you; Low is dropped with a reason. The decision log records each call. |
| **Bounded spend.** | `alf-seat` refuses a third lane (`band.lanes` above 2 is rejected) and refuses new lanes once `--budget` tickets have a PR. Claude seats run with `--max-budget-usd` and `--max-turns`. Every worker is bounded by a wait timeout that turns silence into a board row, and review stops after two rounds. |
| **The Verifier checks the world, not the documents.** | It drives the running app in every flag state (off; on with the setting off; on with the setting on), and records each journey as PASS, FAIL, NOT RUN or N/A with an artefact. An OFF row that was not run makes the whole verdict *not verified*. |
| **Skills cannot fail silently.** | Dispatch refuses a prompt whose SKILL.md path is not absolute or does not exist. A worker that ends without an `ALF` status line is recorded as NOT RUN, never as a pass. |
| **Clean-up never loses work.** | Seats are named worktrees (`Developer`, `Developer-2`, `Reviewer`…). The sweep runs at the start of every run and never removes a tree with uncommitted or unpushed work. |

`scripts/smoke.sh` tests every guardrail that lives in code against fixtures, including a non-Claude agent trying to push to `main`, merge, and open a non-draft PR.

## The board

While the band runs, the board is the only thing you need to read. It is ordered by what needs you, and it checks that every claimed worker is actually alive before printing it:

```text
2026-10-01-m1-export-foundation  Thu 01 Oct 21:14
-------------------------------------------------------------------------------------------------------------------------------
FLAG   TICKET                     PR / SHA           SEAT         STATE                              NEXT
-------------------------------------------------------------------------------------------------------------------------------
PARK   T1.4 #61 Currency rounding #64 a19f003        -            round 2: High survives             needs you
LANE   T1.5 #62 CSV writer        -                  Reviewer     review round 1                     judge findings
LANE   T1.6 #63 Column registry   -                  Developer-2  building                           review
SWEEP  T1.3 #60 Export job        #66 3bf66cd        Guardian     1 bot thread                       verify push
WAIT   T1.7 #65 Retry policy      -                  -            blocked by #63                     -
DONE   T1.2 #59 Export schema     #58 77e01ab        -            draft, swept                       you read it
-------------------------------------------------------------------------------------------------------------------------------
2 advancing · 1 sweeping · 1 needs you · 0 ready · 1 waiting · 0 skipped · 1 done    lanes 2/2 · guardian 1/2 · drafted 3/4 · $11.40 · tip #66
```
