# Demo: reproducing the results table

The results in the README come from running AI Light Factory end to end on a real project, like this:

1. Pick a real repository with a test suite and a dev server, and write a PRD for a feature of about 10–20 tickets.
2. Run the line: `/alf:dev-loop setup` → `grill-with-docs` → `agent-skills:plan` → `to-tickets` → `/alf:dev-loop #<parent> --budget 2` (first run), then `/alf:dev-loop #<parent>` for the rest → `/alf:verify #<parent>`.
3. Review and merge the drafts yourself, as you normally would. **Merging is the measurement**: `alf-stats` counts a draft as a success only once a human has merged it.
4. Run `alf-stats` and paste the table. Run `/alf:dev-loop retro` and link to it.

## What to publish

- The stats table, **including parked tickets and their reasons**.
- Two or three PRs as examples: one clean, one with a decision log full of calls, and one that parked.
- One verdict file, with its NOT RUN rows left in.
- What you changed in the factory after the retro. That is the evidence that the line learns.

## What not to publish

- Anything from a codebase you do not own, or that your employer has not cleared.
- Costs as if they were constants. They depend on the model, the codebase and the week. Publish them as an order of magnitude, with the date.
