<!-- alf:seams:start -->
## Software factory seams (alf)

Each stage writes one artifact at a known path, and the next stage reads it rather than re-deriving it. If a stage is wrong, fix its document and re-run the stage.

| Seam | Artifact |
|---|---|
| PRD → Architect | the PRD, its linked pages, and every related issue body, read in full |
| Architect → Planner | `.factory/decisions/YYYY-MM-DD-<topic>.md` (numbered decision cards) |
| Planner → tickets | `.factory/plans/YYYY-MM-DD-<feature>.md`, then GitHub issues with `Blocked by` edges |
| Band → you | a draft PR with a decision log in its body |
| Verifier → merge | `.factory/verdicts/YYYY-MM-DD-<scope>.md`, summarised as a comment on each PR |

- Settings: `.factory/config.json`. Reach matrix: `.factory/matrix.md`. Precedent map: `.factory/precedents.md`.
- Test command: `{test}`. Dev server: `{dev_server}` at `{dev_url}`.
- Agents in this repo never merge, mark a PR ready, or approve. A human does.
<!-- alf:seams:end -->
