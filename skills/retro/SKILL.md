---
name: retro
description: Turns a finished alf run into factory fixes. Reads the run's state, ledger, parked rows, PR decision logs and verdicts, asks which stage should have caught each problem, and proposes the specific check to add there. Also prints the run's stats. Use after a run or milestone, or when someone asks what went wrong, how the factory did, or for its numbers.
license: MIT
---

# Retro: put the check where it should have been

**Input:** `$ARGUMENTS`, a run id (`.factory/runs/<id>`) or a milestone. With no argument, use the most recent run.
**Output:** `.factory/retros/<run-id>.md`, plus the stats table in chat.

A factory exists so that the same mistake cannot be made twice quietly. That only holds if each mistake leads to a check in the stage that should have caught it. Every defect in a band tends to be found by watching it run, not by reviewing the skill, so this stage reads what actually happened.

## 1. Numbers first

Run `${CLAUDE_PLUGIN_ROOT}/bin/alf-stats --run <id>` and put the table at the top. Report failures next to successes.

## 2. Collect what went wrong

From `state.json`, the ledger, `judged-r*.md` files, PR bodies and any verdict:
- every PARK row, and why
- every CHECK, DIED, SILENT or NOT_RUN worker
- findings marked *Not addressed*, and human review comments on the drafts that the band should have caught
- Verifier FAIL and NOT RUN rows
- spend outliers: a ticket costing more than three times the median

## 3. For each one, three questions

1. **Which stage should have caught it?** Architect (an undecided question), Planner (a missing edge, an oversized ticket, a hotspot), readiness gate, Developer, Reviewer, Guardian, or Verifier.
2. **Why didn't it?** Was the information missing, did the skill have no instruction for it, or did the skill have one that was not followed?
3. **What check goes there?** Make it concrete: a new readiness-gate rule, a row in `.factory/matrix.md`, a deviation in the decisions file, a sentence in a SKILL.md, or a guard in a script. Prefer a mechanical check (script or file) over a sentence in a prompt. A rule that is written is not yet a rule that is running.

## 4. Write the retro

```
# Retro: <run-id>
<stats table>

| # | What happened | Should have been caught by | Why it wasn't | Check to add | Where |
```

End with the **top three checks** to add, in order of how much rework each would have saved. Offer to make the changes, and do not make them unasked. Factory changes are reviewed like code.
