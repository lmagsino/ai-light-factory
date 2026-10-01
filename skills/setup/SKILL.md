---
name: setup
description: One-time setup of the alf software factory in a repository. Names the seams (where each stage writes), detects the test, dev-server, e2e and feature-flag commands, writes .factory/config.json, adds the seams block to AGENTS.md, and creates the factory labels. Use when someone says "set up alf", "set up the factory", or before the first /alf:architect in a repo.
license: MIT
---

# Set up the line in this repo

Until the seams are named, the stages cannot hand over, and that is the only thing that separates a factory from five prompts. This takes about an hour the first time, mostly answering questions the code cannot answer.

Look facts up instead of asking. Ask only what the repo cannot tell you, **one question at a time**.

## 1. Detect

Run these and keep the answers:

- `git remote get-url origin` and `gh auth status`. The default tracker is GitHub Issues. If `gh` is missing or unauthenticated, stop and say so.
- **Integration branch:** `git symbolic-ref refs/remotes/origin/HEAD`.
- **Setup command:** what installs dependencies in a fresh checkout (`npm ci`, `pnpm install --frozen-lockfile`, `bundle install`, `uv sync`…). Seats are separate worktrees, and `alf-seat` runs this in a seat whenever its lockfiles change. Without it, every new seat's tests fail for want of dependencies.
- **Test command:** look in `package.json` scripts, `Makefile`, `justfile`, `Gemfile` / `.rspec`, `pyproject.toml` / `pytest.ini`, `go.mod`, `Cargo.toml`, and CI workflow files. Prefer the command CI runs.
- **Dev server and URL:** `dev` / `start` scripts, `Procfile.dev`, `bin/dev`, `docker-compose.yml`. Note the port.
- **E2E:** `playwright.config.*`, `cypress.config.*`. If `@playwright/test` is installed but there is no config and no specs, say so plainly: the Verifier will report its browser legs as NOT RUN until a harness exists.
- **Feature flags:** search dependencies and code for `launchdarkly`, `flipper`, `unleash`, `growthbook`, `openfeature`, `flagsmith`, or an env-var convention. Record the platform and how flags are toggled locally.
- **Agents per seat:** every seat (Developer, Reviewer, Guardian, Verifier) can be any coding-agent CLI. `claude` and `codex` are built in, with model, effort and budget flags. Any other agent gets a `command`: the prompt arrives on stdin and as a file path in `$ALF_PROMPT_FILE`, so `your-agent -p "$(cat "$ALF_PROMPT_FILE")"` fits most CLIs. Check the agent's own docs for its non-interactive flag. Ask which agents the user has, and check each with `--version`.
- **Second vendor:** the Reviewer should come from a different vendor than the Developer. A reviewer that shares the builder's training shares its blind spots. If only one vendor is available, say so: every PR will be marked *same-vendor review*.
- **Who gets the PRs:** `gh api user --jq .login`.

## 2. Ask what is left

Typically only:
1. Confirm the integration branch and test command, if there was any doubt.
2. Which GitHub login draft PRs are assigned to (default: the current user).
3. Whether a review bot should be requested on each draft (for example Copilot), and its reviewer name.

## 3. Write

1. `.factory/config.json` from `${CLAUDE_PLUGIN_ROOT}/templates/config.json`, filled in. The template's reference setup is Claude Code building and Codex reviewing; change `vendor` and `command` per seat for other agents. Leave models as aliases (`opus`, `sonnet`) or empty for the agent's default, so the config does not rot when model versions change.
2. Create `.factory/decisions/`, `.factory/plans/`, `.factory/verdicts/`.
3. Add these lines to `.gitignore`: `.factory/runs/` and `.factory/ledger.jsonl`. Decisions, plans and verdicts are committed. Runs and the ledger are not.
4. **AGENTS.md:** insert `${CLAUDE_PLUGIN_ROOT}/templates/agents-seams.md` (filled in) between its `alf:seams` markers, replacing any previous block. Create AGENTS.md if it is missing. Codex reads AGENTS.md. Claude Code reads CLAUDE.md first, so if a CLAUDE.md exists and does not already contain `@AGENTS.md`, add that line at its top and tell the user you did.
5. Copy `${CLAUDE_PLUGIN_ROOT}/templates/matrix.md` to `.factory/matrix.md` and `${CLAUDE_PLUGIN_ROOT}/templates/precedents.md` to `.factory/precedents.md`, unless they already exist.
6. Create the labels (idempotent):
   ```bash
   gh label create factory:ready          --color 0E8A16 --force --description "Passed the readiness gate; the band may build it"
   gh label create factory:needs-decision --color D93F0B --force --description "Missing a decision; goes back to the Architect"
   gh label create factory:in-band        --color 1D76DB --force --description "A alf lane is working on it"
   gh label create factory:parked         --color FBCA04 --force --description "The band stopped; needs a human"
   ```

## 4. Offer the two documents that pay most

Say that these exist and offer to draft them now by reading the codebase. Do not write them unasked.

- **The reach matrix** (`.factory/matrix.md`). It classifies paths as shared, specific or registry. It is the only review question a reviewer cannot answer from the diff, and the one most teams answer by guessing.
- **The precedent map** (`.factory/precedents.md`). Two or three named shapes of work, with the questions that classify new work into one. It stops an estimate being borrowed across a boundary it should not cross.

## 5. Report

Print a short table of what was detected and written, and list what is missing, with the consequence of each. For example: "no e2e harness: the Verifier's browser legs will be NOT RUN". Finish with the next command: `/alf:architect <path-to-PRD>`.
