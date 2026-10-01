# Precedent map

The most expensive estimating mistake is sizing new work against the last thing that looked like it. Two projects with the same ticket count can differ fivefold in cost, because one is a variation on machinery that exists and the other needs machinery that does not.

List the two or three shapes of work this codebase already knows how to do, and the questions that sort new work into one of them.

## Shape: {name}

- **Looks like:** one-line description
- **Examples:** named files or PRs, and a count ("eleven existing providers")
- **A new one costs:** {n} tickets / {d} days, measured on the examples
- **It is this shape if:** yes/no questions
- **It is not this shape if:** the tell that it only looks similar

## Rules

- Never carry a per-ticket velocity across a precedent boundary. It was measured on machinery the new work does not have.
- Search the whole codebase before calling a capability new. The nearest precedent is often outside the domain, and finding one turns a build into a copy.
