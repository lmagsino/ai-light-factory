# Verdict: {scope}

- **Date:** {YYYY-MM-DD}
- **Scope:** milestone {M} | feature {name} | PRs #…
- **Build:** `{sha}` on `{branch}`
- **Overall:** VERIFIED | NOT VERIFIED | FAILED

An OFF row that was not run makes the overall verdict NOT VERIFIED, however green the rest is.

## Claim 1: it does what was promised

- Every planned ticket has a PR: yes | no, missing: …
- Outcome driven in the running app: see the journeys table below

## Claim 2: nothing else broke

Flows that go through the changed files, found by search rather than by guessing:

| Flow | Found via | Verdict | Evidence |
|---|---|---|---|

Flows not run, named: …

## Claim 3: the flag makes false safe

- **Flag:** `{key}` on {platform}
- **Gate:** setting `{name}`, defaults {true|false}. With no setting the matrix has two states, not three.

Read the OFF rows first. They say whether it is safe to merge. The ON rows only say whether it was worth merging.

| Journey | Flag state | Expected | Verdict | Evidence |
|---|---|---|---|---|
| {journey} | off | identical to before | PASS | `traces/1.zip` |
| {journey} | on, setting off | still the old behaviour | PASS | `traces/2.zip` |
| {journey} | on, setting on | the new behaviour in full | PASS | `traces/3.zip` |
| {journey} | on, setting on | … | NOT RUN | no fixture for {x} |

Every cell is PASS, FAIL, NOT RUN with a reason, or N/A with a reason. None are blank.

## Failures

For each FAIL: expected, actual, trace path, and whether the code is wrong (back to the Developer) or the plan is wrong (back to grill-with-docs, as a new ADR).
