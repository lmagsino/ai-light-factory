---
name: tickets
description: Writes a confirmed alf plan into GitHub as milestones and issues with Blocked-by edges, after a dry run and an explicit "create these" confirmation, then runs the readiness gate on each issue. Idempotent. Use only when the user asks to create, push or sync the plan's tickets.
license: MIT
disable-model-invocation: true
---

# Tickets: plan → GitHub issues

**Input:** `$ARGUMENTS`, a plan file in `.factory/plans/`.
**Output:** GitHub milestones and issues; the plan file updated with each ticket's issue number.

This is the only stage that changes something outside the repo before any code exists. Its gate is not "is this the right plan?" (that was approved one stage earlier). It is **"create these"**. Undoing a wrong run means deleting dozens of issues by hand, and anything already linked to them (a branch, a PR, another issue's blocker) breaks.

## 1. Dry run

Parse the plan and print:
- milestones to create (and which already exist)
- issues to create, with title, size and blockers
- issues that already exist: each issue body carries a hidden marker `<!-- alf:T1.2 -->`, so search with `gh issue list --search "alf:T1.2 in:body" --state all`
- edge count, and any edge that points at a ticket not in the plan (a planning defect, so stop)

Then ask exactly one question: **"Create these N issues in M milestones?"** Wait for yes.

## 2. Create

In dependency order (blockers first), so `Blocked by` can name real issue numbers:

1. Create missing milestones: `gh api repos/{owner}/{repo}/milestones -f title="M1 · Account sync"`.
2. For each ticket, render `${CLAUDE_PLUGIN_ROOT}/templates/ticket.md` with the marker, context, acceptance criteria, decisions, `Blocked by` (as `#n`), size, test plan, out of scope, and `Open questions: none`. Create it with `gh issue create --milestone ... --body-file ...`.
3. GitHub's native issue dependencies are optional. The `Blocked by` section in the body is the source of truth that the band reads.

Create issues one at a time and check each result. After any step with an outward effect, check the effect, not the message: `gh issue view <n>`.

## 3. Gate every issue

Run `${CLAUDE_PLUGIN_ROOT}/bin/alf-ready <n> --label` on each new issue. Issues that fail are labelled `factory:needs-decision`. List them with their reasons. Each one is a planning defect to fix now, not a question for the band later.

## 4. Write back

Add the issue number next to each ticket in the plan file (`T1.2 · #57`), commit it, and print the next command: `/alf:loop <milestone> --budget 2`. Suggest a budget of 2 for a first run. A rule that is written down is not yet a rule that is running, and a small budget is how you find out which rules are.
