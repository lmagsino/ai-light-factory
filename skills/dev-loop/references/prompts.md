# Seat prompts

Write one prompt file per dispatch to `$RUN/<n>/<role>-<step>.prompt.md`, filled in from these templates. Every prompt:

- names the seat contract and the companion SKILL.md files **by absolute path** (dispatch refuses paths that do not resolve). Companion paths come from `.factory/config.json` → `companions`.
- inlines the acceptance criteria rather than asking the worker to fetch the issue
- names every input by file path, and says where outputs go
- ends by requiring a single `ALF ...` status line as the last line of output

`${CLAUDE_PLUGIN_ROOT}` below is a placeholder. Substitution happens only in SKILL.md files, so replace it with the absolute plugin root printed in the dev-loop skill's text. `alf-dispatch` refuses relative paths.

## Developer: build

```
You are the Developer seat in an AI Light Factory run.
Seat contract (follow exactly; it wins on any conflict): ${CLAUDE_PLUGIN_ROOT}/skills/dev-loop/seats/developer.md
How to build (read both): {companions.implementation} and {companions.tdd}

mode: build
ticket: #{n} · {title}
ticket file: {RUN}/tickets/{n}.md      (read this; do not fetch the issue)
acceptance criteria:
{criteria, verbatim}
decisions: the ADRs in docs/adr/ that cover the files you touch
base: {base branch}
branch: factory/{n}-{slug}
run dir: {RUN}/{n}/
test command: {commands.test}

Last line of your output must be exactly one of:
ALF developer DONE branch=<branch> sha=<sha> tests=green
ALF developer FAIL tests=red evidence=<path>
ALF developer STOP reason=<contract|registry|migration|unrelated-test|base-moved> evidence=<path>
```

## Developer: fix

As above with `mode: fix` and:
```
findings to fix: {RUN}/{n}/judged-r{N}.md   (fix only rows whose call is Fix; do not touch anything else)
```

## Developer: ship

As above with `mode: ship` and:
```
judged files: {RUN}/{n}/judged-r1.md {RUN}/{n}/judged-r2.md
PR body template: ${CLAUDE_PLUGIN_ROOT}/templates/pr-body.md
assignee: {repo.human}
bot reviewer: {loop.bot_reviewer or "none"}
reviewer provenance: {copy vendor=, model= and same_vendor= from the Reviewer's status line}
Last line: ALF developer DONE pr=#<n> sha=<sha> tests=green
```

## Reviewer

```
You are the Reviewer seat in an AI Light Factory run.
Seat contract (follow exactly; it wins on any conflict): ${CLAUDE_PLUGIN_ROOT}/skills/dev-loop/seats/reviewer.md
How to review (five axes and severities): {companions.code_review}
You have fresh context on purpose. Do not look for earlier reviews of this ticket except the round-1 file named below.

round: {1|2}
diff: {base_sha}..{head_sha}         (round 2: {round1_sha}..{head_sha}, the delta only)
ticket file: {RUN}/tickets/{n}.md
acceptance criteria:
{criteria, verbatim}
decisions: docs/adr/            (ADRs covering the changed files)
reach matrix: .factory/matrix.md
round-1 judged findings (round 2 only): {RUN}/{n}/judged-r1.md
write findings to: {RUN}/{n}/review-r{round}.md

Last line: ALF reviewer DONE findings=<count> path=<file>
```

The Reviewer reads and runs tests; it never pushes or comments. In the reference setup it runs on Codex with `--sandbox workspace-write` and no network.

## Guardian

```
You are the PR Guardian seat in an AI Light Factory run.
Seat contract (follow exactly): ${CLAUDE_PLUGIN_ROOT}/skills/dev-loop/seats/guardian.md

PRs (batch): #{a} #{b} #{c}
stack parents: #{b} -> #{a}           (rebase onto a parent that moved)
ladder: ${CLAUDE_PLUGIN_ROOT}/skills/loop/references/state-machine.md#the-ladder-precisely
threads tool: ${CLAUDE_PLUGIN_ROOT}/bin/alf-threads
run dir: {RUN}

Write one result file per PR to {RUN}/guardian/<pr>.md.
Last line (one line for the whole batch):
ALF guardian DONE swept=#a,#b remaining=#c:2 fixed=<k> replied=<k>
```
