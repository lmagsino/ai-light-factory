# Setup: once per repo

Until the seams are named, the stages cannot hand over, and that is the only thing that separates a factory from a set of prompts. Look facts up instead of asking. Ask only what the repo cannot tell you, **one question at a time**.

## 1. The companion skill packs

The line uses two MIT-licensed packs for every stage except the dev loop and the Verifier.

| Pack | Install in Claude Code | Used for |
|---|---|---|
| Matt Pocock's skills | `/plugin marketplace add mattpocock/skills` then `/plugin install mattpocock-skills@mattpocock` | `grill-with-docs` (decisions), `to-tickets` (GitHub issues) |
| Addy Osmani's agent-skills | `/plugin marketplace add addyosmani/agent-skills` then `/plugin install agent-skills@addy-agent-skills` | `plan`, and the build and review skills the seats follow |

1. Check with `claude plugin list`. If a pack is missing, give the user the two commands above and wait.
2. Matt's ticket skills need their own one-time setup, which points them at GitHub Issues. If it has not been done in this repo, tell the user to run `/setup-matt-pocock-skills` and choose GitHub.
3. **Find the agent-skills SKILL.md files the seats read by path.** A seat may run a different agent (Codex, for example), which cannot see Claude's plugins, so the dev loop hands every seat absolute file paths:
   ```bash
   find ~/.claude/plugins -path '*agent-skills*' -name SKILL.md \( -path '*incremental-implementation*' -o -path '*test-driven-development*' -o -path '*code-review-and-quality*' \) 2>/dev/null
   ```
   If any of the three is not found, clone the pack to a fixed place and use those paths instead:
   ```bash
   git clone --depth 1 https://github.com/addyosmani/agent-skills ~/.alf/companions/agent-skills
   ```
   Record the three absolute paths in `.factory/config.json` → `companions` (`implementation`, `tdd`, `code_review`).

## 2. Detect

- `git remote get-url origin` and `gh auth status`. The tracker is GitHub Issues. If `gh` is missing or unauthenticated, stop and say so.
- **Integration branch:** `git symbolic-ref refs/remotes/origin/HEAD`.
- **Setup command:** what installs dependencies in a fresh checkout (`npm ci`, `pnpm install --frozen-lockfile`, `bundle install`, `uv sync`…). Seats are separate worktrees, and `alf-seat` runs this in a seat whenever its lockfiles change.
- **Test command:** prefer the one CI runs (look in `package.json`, `Makefile`, `Gemfile`, `pyproject.toml`, `go.mod`, `Cargo.toml`, and the CI workflows).
- **Dev server and URL:** `dev` / `start` scripts, `Procfile.dev`, `bin/dev`, `docker-compose.yml`. Note the port.
- **E2E:** `playwright.config.*`, `cypress.config.*`. If there is none, say plainly that `/alf:verify` will report its browser legs as NOT RUN until a harness exists.
- **Feature flags:** search for `launchdarkly`, `flipper`, `unleash`, `growthbook`, `openfeature`, `flagsmith`, or an env-var convention. Record how flags are toggled locally.
- **Agents per seat:** each seat (Developer, Reviewer, Guardian, Verifier) can be any coding-agent CLI. `claude` and `codex` are built in. Any other agent gets a `command`: the prompt arrives on stdin and as a file path in `$ALF_PROMPT_FILE`. Ask which agents the user has, and check each with `--version`. Keep the Reviewer on a different vendor from the Developer, or every PR is marked *same-vendor review*.
- **Who gets the PRs:** `gh api user --jq .login`.

## 3. Write

1. `.factory/config.json` from `${CLAUDE_PLUGIN_ROOT}/templates/config.json`, filled in, including `companions`. Leave models as aliases (`opus`, `sonnet`) or empty for the agent's default.
2. Add these lines to `.gitignore`: `.factory/runs/` and `.factory/ledger.jsonl`.
3. **AGENTS.md:** insert `${CLAUDE_PLUGIN_ROOT}/templates/agents-seams.md` (filled in) between its `alf:seams` markers, replacing any previous block. Create AGENTS.md if it is missing. If a CLAUDE.md exists and does not already contain `@AGENTS.md`, add that line at its top and say so.
4. Copy `${CLAUDE_PLUGIN_ROOT}/templates/matrix.md` to `.factory/matrix.md` unless it exists. Offer to draft it from the codebase: the Reviewer's question about shared code paths depends on it, and it is the one question nobody can answer from a diff.
5. Create the labels (idempotent):
   ```bash
   gh label create factory:ready          --color 0E8A16 --force --description "Passed the readiness gate"
   gh label create factory:needs-decision --color D93F0B --force --description "Missing a decision; back to grill-with-docs"
   gh label create factory:in-loop        --color 1D76DB --force --description "A dev-loop lane is working on it"
   gh label create factory:parked         --color FBCA04 --force --description "The dev loop stopped; needs a human"
   ```

## 4. Report

Print a short table of what was detected and written, and what is missing with the consequence of each. Finish with the line in order:

```text
/mattpocock-skills:grill-with-docs docs/prd.md     # decisions -> docs/adr/, GLOSSARY.md
/agent-skills:plan                                 # tasks/plan.md
/mattpocock-skills:to-tickets tasks/plan.md        # GitHub issues with Blocked by
/alf:dev-loop #<parent> --budget 2                 # the dev loop
/alf:verify #<parent>                              # every flag state
```
