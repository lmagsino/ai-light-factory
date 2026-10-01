# Retro: put the check where it should have been

Run with `/alf:dev-loop retro [run-id]`.

**Input:** `$ARGUMENTS`, a run id (`.factory/runs/<id>`) or a milestone. With no argument, use the most recent run.
**Output:** `.factory/retros/<run-id>.md`, plus the stats table in chat.

A factory exists so that the same mistake cannot be made twice quietly. That only holds if each mistake leads to a check in the stage that should have caught it. Every defect in a dev loop tends to be found by watching it run, not by reviewing the skill, so this stage reads what actually happened.

## 1. Numbers first

Run `${CLAUDE_PLUGIN_ROOT}/bin/alf-stats --run <id>` and put the table at the top. Report failures next to successes.

## 2. Collect what went wrong

From `state.json`, the ledger, `judged-r*.md` files, PR bodies and any verdict:
- every PARK row, and why
- every CHECK, DIED, SILENT or NOT_RUN worker
- findings marked *Not addressed*, and human review comments on the drafts that the dev loop should have caught
- Verifier FAIL and NOT RUN rows
- spend outliers: a ticket costing more than three times the median

## 3. For each one, three questions

1. **Which stage should have caught it?** Decisions (`grill-with-docs`: an undecided question, a missing ADR), plan (`agent-skills:plan`: a missing dependency, a task too big), tickets (`to-tickets`: a missing edge or criterion), the readiness gate, Developer, Reviewer, Guardian, or Verifier.
2. **Why didn't it?** Was the information missing, did the skill have no instruction for it, or did the skill have one that was not followed?
3. **What check goes there?** Make it concrete: a new readiness-gate rule, a row in `.factory/matrix.md`, a new ADR, a sentence in a seat contract, or a guard in a script. Prefer a mechanical check (script or file) over a sentence in a prompt. A rule that is written is not yet a rule that is running.

## 4. Write the retro

```
# Retro: <run-id>
<stats table>

| # | What happened | Should have been caught by | Why it wasn't | Check to add | Where |
```

End with the **top three checks** to add, in order of how much rework each would have saved. Offer to make the changes, and do not make them unasked. Factory changes are reviewed like code.
