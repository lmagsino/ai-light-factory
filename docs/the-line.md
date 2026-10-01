# The line

## What a factory is for

Not speed. A factory exists so that **the same mistake cannot be made twice quietly**. Each stage produces a written artifact at a known path, and the next stage reads it rather than re-deriving it. When something goes wrong, you can say which stage should have caught it, and put the check there (`/alf:dev-loop retro` does exactly this).

The alternative is one long agent session that reads, decides, plans, builds and reviews without ever writing down what it concluded. That works until it doesn't, and when it doesn't, there is nothing to inspect.

## Three cadences, not one pass

| Cadence | Stages |
|---|---|
| Once per project | decisions (`grill-with-docs`), plan (`agent-skills:plan`), tickets (`to-tickets`) |
| Once per ticket, continuously through a parent or milestone | the dev loop (`/alf:dev-loop`) |
| Once per parent, milestone or phase | the Verifier (`/alf:verify`) |

Mixing these up is the common failure. A Verifier run per ticket produces theatre, because until a phase is nearly done there is usually nothing end to end to exercise. Re-opening decisions per ticket produces a plan that contradicts itself.

## Gates

A solid gate is a decision you make before the next stage runs:

| After | You decide |
|---|---|
| `grill-with-docs` | the decisions hold |
| `agent-skills:plan` | this is the right plan |
| `to-tickets` | these are the right tickets, with the right blocking edges |
| dev loop | you read the draft PR |
| Verifier | you merge |

## Rework paths

| Path | When |
|---|---|
| Reviewer → Developer | a review round. The Developer fixes its own findings, for at most two rounds |
| Verifier → Developer | it does not behave as planned, and the code is why |
| Verifier → `grill-with-docs` | it does not behave as planned, and the plan was wrong. The expensive path, and the reason the Verifier exists. The correction becomes a new ADR |
| readiness gate → `grill-with-docs` | a ticket cannot be built because a decision was never taken. Cheap here, and the last chance |

## What each stage is really for

None of them is mainly for what its name suggests. This becomes visible only by running the line and looking at what each stage actually caught.

| Stage | Its real value | |
|---|---|---|
| Decisions | **Corrective** | It catches the requirement that would have been implemented exactly as written and merged, because it read as a decision already made. It is also *subtractive*: reading everything usually makes the work look less blocked, not more. |
| Plan and tickets | **Arithmetical** | It catches the plan that is internally inconsistent, and it can only do that after the graph is written down as real edges. |
| Dev loop | **Compressive** | Its value is not that it writes code; you could do that. It is that a ticket reaches you already reviewed, swept and squashed, so your attention goes to the diff rather than to the process. |
| Verifier | **Falsifying** | The only stage whose job is to find out that the plan was wrong. Everything before it checks internal consistency. This one checks the world. |

## The three review questions

A general code review asks whether code is correct, tested, secure and readable. These ask something else: **what does this change reach that its author was not thinking about?**

| # | Question | Catches | Answered by |
|---|---|---|---|
| 1 | Does it change an outward contract? | a payload, API response, event shape, public column, or flag meaning that something outside depends on | judgement. If yes, it owes the Verifier a proof |
| 2 | Does it touch code other paths run through? | correct in the case you tested, silently wrong in the others | a lookup in `.factory/matrix.md` (shared / specific / registry) |
| 3 | Does it undo a deliberate decision? | code that looks like a bug, is not, and breaks when "fixed" | a lookup in the ADRs in `docs/adr/` |

Question 2 is where the matrix earns its keep. It is the only one you cannot answer by reading the diff, which is why most teams answer it by guessing.

## What to build first, in an existing repo

1. **Name the seams** with `/alf:dev-loop setup`, and point Matt Pocock's skills at GitHub with `/setup-matt-pocock-skills`. Until both are done, the stages cannot hand over.
2. **Write the reach matrix.** It is the only review question that cannot be answered from the diff.
3. **Add a Playwright harness** before the first verified milestone, or the Verifier will honestly report its browser legs as NOT RUN.
