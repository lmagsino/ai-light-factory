---
name: plan
description: Stage 2 of the AI Light Factory. Turns a settled decisions file into a plan with a precedent verdict, milestones, XS/S tickets, real blocking edges, a lane model and shared-file hotspots, written to .factory/plans/. Use after /alf:architect, when someone asks to plan, size, estimate or break down a feature into tickets. It does not create issues; /alf:tickets does that.
license: MIT
---

# Planner: decisions → milestones, tickets, edges

**Input:** `$ARGUMENTS`, a decisions file in `.factory/decisions/` (and the PRD it cites).
**Output:** `.factory/plans/YYYY-MM-DD-<feature>.md`, in the format of `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`.
**Gate after this stage:** the human confirms *these are the right tickets*.

This stage catches the plan that cannot be true: two statements in the same document that contradict each other. It can only do that after writing the dependency graph down as real edges, which is the first thing that forces the two to be compared. Nothing checks this stage's arithmetic. A wrong blocking edge silently produces a wrong stack, and the band follows it without complaint. Run it at high effort.

## 1. Classify before you estimate

Cost follows precedent, not scope. Before sizing anything, answer in writing: **how much of this already exists?** Read `.factory/precedents.md` if it exists.

- **What is the same:** the precedent it matches, with named files and a count.
- **What is new, itemised:** each capability with no precedent, plus evidence that it is absent (the search that returned nothing). Do not write "this one is complex". Name the three missing things.
- **Why that costs more:** each new capability tied to the milestones it adds.

Search the whole codebase before calling anything new. The nearest precedent is often outside the domain, and finding one turns a build into a copy.

**A new shape is an escalation, not a section.** If the verdict is *new shape*, write the short escalation paragraph (name the shape, list what is new, state the delta) and tell the human to send it *with* the estimate. Never carry a per-ticket velocity across a precedent boundary.

## 2. Milestones and tickets

- A milestone is something you could demo. A ticket is a thin vertical slice that can be tested on its own.
- **Sizes:** XS = 0.125 days, S = 0.5 days. Anything bigger gets split now, not by the band later.
- Every ticket has acceptance criteria as checkboxes, the decision cards it relies on (or "none"), its blockers (or "none"), and a test plan. The band's readiness gate (`alf-ready`) rejects tickets that lack any of these, so write them now.
- If a ticket cannot be written because a decision was never taken, **stop and send it back to the Architect.** Do not invent the decision in a ticket.

## 3. Edges

- Write the graph as real blocking edges, and draw it as a mermaid graph in the plan.
- Keep **starts after** separate from **completes after**. A single "depends on" column makes independent milestones look serial. (A milestone may start on the foundation alone even though it completes after something else.)
- The edges are also the stacking order: the band bases a ticket's branch on its blocker's open PR. Edges that are wrong produce stacks that are wrong.

## 4. Design for parallel before anything is built

- **Shared-file hotspots:** find files that several milestones would all edit, such as one query file, one handler, or one registry. Each one serialises the plan. Add an early foundation ticket that splits each hotspot into regions (one section or module per area), so milestones can build side by side.
- **Lane model:** total days at 1 lane, wall-clock at 2 lanes, and the dependency floor (critical path) with unlimited lanes. If one milestone is the floor on its own, splitting that milestone's tickets across lanes matters more than adding lanes.
- **Keep the tail short.** Move work that does not depend on the finished body out of the final phase.
- **Name the plan's own limits.** One human can review about two lanes of PRs. Concurrent lanes need separate test databases, or their failures look like real bugs.

## 5. External gates and risks

List what blocks a ticket from outside the repo (credentials, partner sandboxes, data exports) as edges. Add a short risk table.

## Done when

The plan file is written, every ticket passes the readiness checklist on paper, and the human has confirmed the tickets. Commit it, then say: `/alf:tickets .factory/plans/<file>.md`. That step creates issues, so it has its own gate.
