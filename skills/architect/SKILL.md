---
name: architect
description: Stage 1 of the AI Light Factory. Reads a PRD and everything linked to it, then settles every open decision with the human one question at a time, recording each as a numbered decision card beside the part of the PRD it changes. Also surfaces PRD-vs-codebase contradictions and deliberate deviations. Use with a PRD path or issue when starting a project, or when the planner or verifier sends work back because a decision was never taken.
license: MIT
---

# Architect: PRD → every decision settled

**Input:** `$ARGUMENTS`, a PRD path, an issue number, or a URL.
**Output:** `.factory/decisions/YYYY-MM-DD-<topic>.md`, in the format of `${CLAUDE_PLUGIN_ROOT}/templates/decisions.md`.
**Gate after this stage:** the human confirms *the decisions hold*.

Everything a later stage needs to decide gets decided here. The build band never asks a question, because by the time it runs there is nothing left to ask. If it ever wants to ask, a decision was missed here.

Run this stage in your own session at the highest effort you have (`/effort xhigh`). The upstream seats inherit your session's model and effort, and nothing warns you if you lowered them. Nothing re-examines this stage until the Verifier, at the end of the line, on the most expensive rework path there is.

## 1. Read the whole source set

- The PRD, every page it links (open them, do not just list them), and **every related issue body in full**. Issue bodies routinely carry reasoning that exists nowhere else.
- The parts of the codebase the PRD touches. Find where each requirement would land.
- `.factory/precedents.md` and `.factory/matrix.md`, if they exist.

Write the list of what you read at the top of the output, marking anything you could not open. Silence reads as "read".

## 2. List what is open

Something is a decision if any of these is true:
- the PRD leaves it open, or answers it two different ways
- it is assumed by the PRD and contradicted by the code (the PRD says "reuse the export queue" and no export queue exists)
- it would make a builder choose between two reasonable implementations
- it is a deliberate deviation from how the codebase usually does things

**Look facts up instead of asking.** "Does the user table have a timezone column?" is a search, not a question. Questions are for decisions: things the human owns.

Expect this stage to be subtractive. Reading everything usually makes the work look *less* blocked: eight apparently missing pieces turn out to be one, and a question that looks like an external blocker is answered in a document you already have.

## 3. Put each decision to the human, one at a time

For each open decision:
1. State the question in one sentence.
2. Give 2–3 alternatives, each with its consequence for this codebase.
3. Recommend one and say why.
4. **Wait.** Do not guess for the human and do not batch questions. (Rule 1: never guess for the human. The line may wait for you; it never fills a gap in your decisions with its own guess.)

If the user has Matt Pocock's `grill-with-docs` skill installed and prefers its interview style, it is fine to use it for this step. Write the result into alf's card format afterwards, because the later stages read these cards by path.

## 4. Record each answer as a card, beside what it changes

Group cards under the PRD section they change, not in a separate ADR folder. Separate ADR files put the *why* one hop from the *what*, and nothing keeps the two in step.

Each card has: **Question**, **Alternatives**, **Decision**, **Why**, **Trap it leaves behind**, **Changes**.

The trap is the field people skip, and the one that pays. It names what a later reader, or a later agent, could get wrong *because* of this decision. Example: "Amounts are stored in cents here, unlike the legacy export, which uses dollars. Do not copy the legacy formatter."

## 5. Record deliberate deviations with their scope

A deliberate deviation is code that will look like a bug and is not. List each one with **where it applies** and **where it must never be copied**. The Reviewer reads this list to answer review question 3 (*does this change undo a deliberate deviation?*). The risk is as often a new caller copying the exception into a context that cannot admit it as someone "fixing" it.

## 6. Contradictions are surfaced, never worked around

When the PRD and the code disagree, write the row (PRD says / code says / evidence) and put it to the human as a decision. Evidence means a file and line, or the search that returned nothing. "I think X is missing" is not evidence.

## Done when

- every open item is a card or is marked out of scope by the human
- no ticket the Planner will write needs an answer that is not in this file
- the human has said the decisions hold

Then commit the file and say: `/alf:plan .factory/decisions/<file>.md`.

## When work comes back to this stage

- **From the Planner:** a ticket could not be written because a decision was never taken. Cheap to fix here, and the last chance: after this, the band assumes everything is settled.
- **From the Verifier:** the feature does not behave as the plan said, and the plan was wrong. This is the expensive path. Add a card that says what the world turned out to be, and mark the cards it overturns as superseded rather than deleting them.
