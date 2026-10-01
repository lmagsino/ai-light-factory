# Install and configure

## Requirements

- git 2.31 or later, an authenticated [`gh`](https://cli.github.com/), `jq`, and `python3`
- bash. The scripts are written for macOS's stock bash 3.2 as well as Linux, and CI runs the smoke tests on both.
- at least one coding-agent CLI, ideally two from different vendors, so the Reviewer never shares the Developer's blind spots

## Install

AI Light Factory ships as a Claude Code plugin. The orchestrator runs there today, and every seat can be any agent.

```text
/plugin marketplace add lmagsino/ai-light-factory
/plugin install alf@ai-light-factory
```

Then, inside your project, run `/alf:setup`. It detects your test, dev-server, e2e and feature-flag commands, asks which agents to use in each seat, and writes `.factory/config.json`.

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

The reference setup, which is what the author runs, is Claude Code in the Developer, Guardian and Verifier seats and Codex in the Reviewer seat.

## Recommended companion skills

AI Light Factory owns the line: the stages, seams, band and guardrails. For the craft inside each seat, it works well alongside these MIT-licensed skill packs:

| Pack | Use it for |
|---|---|
| [Matt Pocock's skills](https://github.com/mattpocock/skills) | `grill-with-docs` interviews (the style the Architect borrows), `to-spec`, `tdd` |
| [Addy Osmani's agent-skills](https://github.com/addyosmani/agent-skills) | incremental implementation, TDD and code-review discipline inside the Developer seat |

## The skills

| Stage | Skill | Cadence | Writes |
|---|---|---|---|
| 0 | `/alf:setup` | once per repo | `.factory/config.json`, the AGENTS.md seams block, labels |
| 1 | `/alf:architect` | once per project | `.factory/decisions/…md`: numbered cards, each with the trap it leaves |
| 2 | `/alf:plan` | once per project | `.factory/plans/…md`: precedent verdict, XS/S tickets, edges, lane model |
| 2 | `/alf:tickets` | once per plan | GitHub milestones and issues, readiness labels |
| 3 | `/alf:loop` | per milestone | draft PRs, the board, the ledger |
| 3 | `build` · `review` · `guardian` | per ticket | dispatched by the loop into seats |
| 4 | `/alf:verify` | per milestone | `.factory/verdicts/…md` |
| – | `/alf:retro` | after a run | `.factory/retros/…md`, stats |
