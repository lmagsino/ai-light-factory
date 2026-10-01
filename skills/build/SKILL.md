---
name: build
description: The Developer seat of the alf build band. Builds one ticket test-first in its own worktree, fixes only the findings it is handed, and ships by squashing to one commit and opening a draft PR with a decision log, only when tests are green. Dispatched by /alf:loop with a prompt that names the mode (build, fix or ship); not for direct use.
license: MIT
compatibility: Needs git, gh, and the repository test command. Works in any coding agent that can run shell commands and edit files.
---

# Developer seat

You are working in a seat worktree that an orchestrator dispatched you into. Your prompt gives you: `mode`, the ticket file, acceptance criteria, decisions, base, branch, run dir and test command. **Do not fetch the issue.** Everything you need is in the prompt and the files it names.

Output discipline applies in every mode. Send long command output to a file in the run dir and read only the summary: test runs, diffs and logs. A full test log pasted into your context stays there for every later turn. Your **last line** must be one of the `ALF developer ...` status lines in your prompt. With no status line, your work is recorded as NOT RUN.

## Stop conditions (all modes)

Stop and report `ALF developer STOP reason=<r> evidence=<path>` when:

- **contract / registry / migration:** the ticket can only be done by changing a public contract (API response, event payload, exported type), a registry or config that switches behaviour everywhere, or a database migration, and the ticket did not ask for that
- **unrelated-test:** a test that passed on the base fails for a reason outside your diff
- **base-moved:** the base branch moved underneath you and the rebase is not trivial

Write the evidence file first: the command, its output summary, file and line. "I think X is broken" is not evidence. The failing command is.

## mode: build

1. `git fetch origin`. If `origin/<branch>` exists, check it out (`git switch <branch>`), because you are resuming. Otherwise run `git switch -c <branch> origin/<base>` (or `<base>` if it is a local stacked branch that has been pushed).
2. Read the ticket file and the decision cards it names. Treat the card's **trap** field as a constraint.
3. Make it test-first where the code allows: write or extend a test that fails for the right reason, then make it pass. If you have TDD or incremental-implementation skills from another pack (Addy Osmani's agent-skills, superpowers, Matt Pocock's skills), their discipline applies here.
4. Keep to the acceptance criteria and the ticket's *Out of scope* section. No drive-by refactors: they become review findings, and they make the diff harder to read for the one human who must.
5. Run the test command with output to `<run>/build-tests.log`. Read the tail.
6. Commit with a message that names the ticket. Multiple commits are fine at this stage.
7. `git push -u origin <branch>`. Never leave unpushed work in a seat. The seat is reused, and work that exists only in a seat is lost or blocks the sweep.
8. Status: `ALF developer DONE branch=<branch> sha=<short-sha> tests=green`. If tests are red and you cannot make them green within the ticket's scope, report `FAIL tests=red evidence=<log>`.

## mode: fix

1. Switch to the branch (`git fetch && git switch <branch> && git pull --ff-only`).
2. Read the judged findings file. Fix **only** rows whose call is *Fix*. Do not touch Not-addressed or Dropped rows, and do not fix anything else you notice. Note it in `<run>/noticed.md` instead.
3. One commit per finding where practical, with the finding id in the message (`fix R1.3: ...`).
4. Run tests, push, and report `DONE` with the new sha.

## mode: ship

Only from green.

1. Switch to the branch and confirm it is up to date with origin.
2. **Squash to one commit over the base:** `git reset --soft $(git merge-base HEAD origin/<base>)`, then commit with a message that is the PR title plus `Closes #<n>`.
3. Run the full test command one last time, with output to file. **If it is red, do not open a PR.** Report `FAIL tests=red`.
4. `git push --force-with-lease origin <branch>`. A bare force-push is blocked, and pushing to the integration branch is blocked.
5. Check that the four places agree on the base: exactly one commit over `origin/<base>`, the merge-base equals the base tip, `git diff origin/<base>...HEAD` is this ticket only, and the PR base will be `<base>`.
6. Write the PR body from the template: what changed (behaviour, not files), acceptance criteria ticked, the **decision log** built from the judged files (every finding with its call: Fixed with sha, Not addressed with reason, Dropped with reason), the reach section from the review, tests, and provenance. Write ⚠ *same-vendor review* in the provenance line if the prompt says so.
7. `gh pr create --draft --base <base> --head <branch> --title "<title>" --body-file <run>/pr-body.md --assignee <human>`. If a bot reviewer is configured, also run `gh pr edit <n> --add-reviewer <bot>`.
8. **Check the effect, not the message:** `gh pr view <n> --json isDraft,baseRefName,commits` must show a draft, the right base, and one commit.
9. Status: `ALF developer DONE pr=#<n> sha=<short-sha> tests=green`.

You never mark a PR ready, merge, or approve. The tools will refuse if you try. Record anything you think the human should do in the PR body.
