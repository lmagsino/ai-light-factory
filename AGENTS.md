# Working on AI Light Factory

AI Light Factory (`alf`): skills in `skills/` (Agent Skills format), scripts in `bin/`, git/gh shims in `bin/shims/`, a guard in `hooks/`, and templates in `templates/`. It installs as a Claude Code plugin; the seats can run any coding agent. Any agent that reads AGENTS.md reads this file.

## Rules for changes

- **Skills follow the Agent Skills spec.** `name` must match the directory name: lowercase letters, digits and hyphens, at most 64 characters. `description` must be at most 1024 characters, and say what the skill does and when to use it. Keep each SKILL.md under 500 lines, and move detail into `references/`.
- **Portable skills stay portable.** `review`, `build` and `guardian` can run under any agent, so use only spec frontmatter fields there (`name`, `description`, `license`, `compatibility`, `metadata`). Claude-only fields (`disable-model-invocation`, `argument-hint`) are fine in `loop` and `tickets`, which always run in Claude Code.
- **Prefer a mechanical check to a sentence.** If a rule can live in a script (`bin/`) or the hook, put it there and have the skill call it.
- **Scripts:** bash that runs on macOS's bash 3.2 (no `${x,,}`, no `mapfile`, no associative arrays), with `set -euo pipefail`, and only `jq`, `git`, `gh` and python3 stdlib. They must pass `shellcheck`. Every script prints usage from its header comment.
- **Every rule cites its reason.** A rule with no *why* gets deleted by the next person who finds it inconvenient.
- **Every factory change cites the run that motivated it**, in the PR body: what happened, which stage should have caught it, and the check you added.

## Checks

```bash
python3 scripts/validate_skills.py       # frontmatter against the spec
shellcheck -x bin/alf-*.sh bin/alf-{seat,dispatch,wait,board,ready,threads,ledger} bin/shims/* scripts/smoke.sh
bash scripts/smoke.sh                     # seats, dispatch, wait, board, limits, ledger, stats and the guard, against fixtures
claude plugin validate . --strict         # when the claude CLI is available
```
