Closes #{issue}{stack_note}

## What changed

{two to five lines, in terms of behaviour, not files}

## Acceptance criteria

- [x] …

## Decision log

Everything the dev loop decided without you. A finding that is neither fixed nor listed here has been lost.

| # | Source | Severity | Finding | Call | Where |
|---|---|---|---|---|---|
| R1.1 | Reviewer, round 1 | Critical | … | Fixed | `abc1234` |
| R1.4 | Reviewer, round 1 | Important (~60 lines) | … | Not addressed: larger than the ladder allows | |
| R1.6 | Reviewer, round 1 | Suggestion | … | Dropped: {reason} | |

## Reach

- **Outward contract changed:** no | yes, {what}. Owes the Verifier a proof before merge.
- **Paths:** shared ×{n}, specific ×{n}, registry ×{n} (from `.factory/matrix.md`)
- **Deliberate deviations touched:** none | D4, scope respected

## Not addressed

{the larger Important findings left for you, one line each, or "nothing"}

## Tests

- `{test command}`: green. Log kept at `{run-dir}/…` rather than pasted here.

## Provenance

- **Built by:** {vendor} / {model} / {effort}
- **Reviewed by:** {vendor} / {model} / {effort}. {cross-vendor ✓ | ⚠ same-vendor review}
- **Rounds:** {1 | 2} {(round 2 skipped: round 1 kept nothing)}

---
Opened as a draft by [alf](https://github.com/lmagsino/ai-light-factory). It does not mark ready, merge, or approve. A human does.
