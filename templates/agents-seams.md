<!-- alf:seams:start -->
## Software factory seams (AI Light Factory)

Each stage writes one artifact at a known path, and the next stage reads it rather than re-deriving it. If a stage is wrong, fix its document and re-run the stage.

| Stage | Skill | Writes |
|---|---|---|
| Decisions | `grill-with-docs` (Matt Pocock) | ADRs in `docs/adr/`, terms in `GLOSSARY.md` |
| Plan | `agent-skills:plan` (Addy Osmani) | `tasks/plan.md` |
| Tickets | `to-tickets` (Matt Pocock) | GitHub issues with acceptance criteria and `Blocked by` edges |
| Dev loop | `/alf:dev-loop` | draft PRs with a decision log in the body |
| Verify | `/alf:verify` | `.factory/verdicts/YYYY-MM-DD-<scope>.md`, summarised on each PR |

- Settings: `.factory/config.json`. Reach matrix: `.factory/matrix.md`.
- Test command: `{test}`. Dev server: `{dev_server}` at `{dev_url}`.
- Agents in this repo never merge, mark a PR ready, or approve. A human does.
<!-- alf:seams:end -->
