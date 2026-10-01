# Install and configure

## Requirements

- git 2.31 or later, an authenticated [`gh`](https://cli.github.com/), `jq`, and `python3`
- bash. The scripts are written for macOS's stock bash 3.2 as well as Linux, and CI runs the smoke tests on both.
- at least one coding-agent CLI, ideally two from different vendors, so the Reviewer never shares the Developer's blind spots

## Install

AI Light Factory installs as a Claude Code plugin, next to the two skill packs it builds on:

```text
/plugin marketplace add lmagsino/ai-light-factory
/plugin install alf@ai-light-factory

/plugin marketplace add mattpocock/skills
/plugin install mattpocock-skills@mattpocock

/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

Then, inside your project:

```text
/setup-matt-pocock-skills      # point Matt Pocock's ticket skills at GitHub Issues
/alf:dev-loop setup            # name the seams, pick agents per seat, find the companion skills
```

## Which skill runs each stage

| Stage | Skill | From | Writes |
|---|---|---|---|
| 1. Decisions | `/mattpocock-skills:grill-with-docs` | Matt Pocock | ADRs in `docs/adr/`, terms in `GLOSSARY.md` |
| 2. Plan | `/agent-skills:plan` | Addy Osmani | `tasks/plan.md` |
| 3. Tickets | `/mattpocock-skills:to-tickets` | Matt Pocock | GitHub issues with acceptance criteria and `Blocked by` edges |
| 4. Dev loop | `/alf:dev-loop` | AI Light Factory | draft PRs, the board, the ledger |
| └ Developer seat | follows agent-skills' `incremental-implementation` and `test-driven-development` | Addy Osmani | one squashed commit, a draft PR |
| └ Reviewer seat | follows agent-skills' `code-review-and-quality`, plus the dev loop's reach questions | Addy Osmani | findings with evidence |
| └ PR Guardian seat | the dev loop's own contract | AI Light Factory | thread replies, fixes, rebased stacks |
| 5. Verify | `/alf:verify` | AI Light Factory | `.factory/verdicts/…md` |

The seats read the agent-skills SKILL.md files **by absolute path**, which `/alf:dev-loop setup` records in `.factory/config.json` → `companions`. That is what lets a non-Claude agent in a seat follow them, and `alf-dispatch` refuses to start a seat if one of those paths does not exist.

## Choosing agents per seat

There are four seats: Developer, Reviewer, Guardian and Verifier. Each one is set in `.factory/config.json`:

```json
"seats": {
  "developer": { "vendor": "claude", "model": "opus", "effort": "high", "max_usd": 8 },
  "reviewer":  { "vendor": "codex",  "effort": "high" },
  "guardian":  { "vendor": "claude", "model": "opus", "effort": "high", "max_usd": 4 },
  "verifier":  { "vendor": "other",  "command": "your-agent -p \"$(cat \"$ALF_PROMPT_FILE\")\"" }
}
```

- `claude` and `codex` are built in, with model, effort, turn and dollar flags wired up.
- Any other CLI agent works through `command`. The prompt arrives on stdin and as a file path in `$ALF_PROMPT_FILE`. The agent runs in the seat's worktree, and must end its output with the `ALF ...` status line that the prompt asks for.
- Whatever the agent, its `git` and `gh` calls go through the guard shims, so it cannot merge, mark ready, approve, or push to your integration branch.
- Keep the Reviewer on a different vendor from the Developer. If they match, every PR is marked *same-vendor review*.

The reference setup is Claude Code in the Developer, Guardian and Verifier seats, and Codex in the Reviewer seat.
