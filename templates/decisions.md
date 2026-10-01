# Decisions: {topic}

- **Date:** {YYYY-MM-DD}
- **Status:** open | settled
- **Source set, read in full:** list every document, linked page and ticket body you read. "Listed" is not "read".

## Contradictions found

Anything the PRD assumes that the codebase contradicts. Surfaced, not worked around.

| # | The PRD says | The code says | Evidence (file:line, or the search that returned nothing) | Resolved by |
|---|---|---|---|---|

## Deliberate deviations

Code that will look like a bug and is not. Review question 3 reads this list, so each one needs a scope: where the exception applies, and where it must never be copied.

| # | Deviation | Why | Applies to | Must not be copied into |
|---|---|---|---|---|

## Cards, beside what they change

Group the cards under the PRD section they change, so the *why* sits next to the *what* and cannot drift from it.

### {PRD section name}

#### D1 · {short title}
- **Question:**
- **Alternatives:** A) … B) … C) …
- **Decision:**
- **Why:**
- **Trap it leaves behind:** what a later reader, or a later agent, could get wrong because of this decision
- **Changes:** PRD section / files / tickets this touches
