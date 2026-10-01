# The rules

AI Light Factory runs on five rules and one habit. I arrived at them by running agent lines on real codebases and watching where they went wrong. Each rule exists because breaking it cost something.

## 1. Never guess for the human

The line may stop and wait for you. It never fills a gap in your decisions with its own guess, because a guess that reads as a decision gets built, reviewed and merged exactly as written.

*Inside the build band* this is narrowed on purpose. Review findings are settled by the severity ladder, not by asking you, and every call is written into the PR body. The real review is the one you do on the draft, so the band can decide routine findings as long as it shows its work. The five stop conditions still halt a lane.

## 2. Questions belong on the ticket

A question about *what the work should be* is a planning defect, not a runtime event. It goes back to the Architect and onto the ticket. It does not go into a run. Inside the band the number of questions is zero: anything the band wants to ask is recorded on the board and on the issue, and the run carries on.

## 3. No evidence, no block

A claim that something is missing or broken is checked against the repo before anyone acts on it. "I think the export queue doesn't exist" is not a block. The search that returns nothing is. This applies to the Architect's contradictions, the Reviewer's findings and the Developer's stop reasons alike.

## 4. Stack on open work

A dependency on an unmerged PR is not a blocker. Branch off it, review against it, and base the PR on it. Four places must agree on the base (the commit count, the branch point, the review diff and the PR base), or the review reads the parent's commits as if they were part of this change.

## 5. Two review rounds, then a human

If two rounds of review have not converged, a third will not either. The band stops after round two and parks the lane for you. It skips round two entirely when round one kept nothing.

## The habit: check the effect, not the message

Treat your own agents' reports the way you treat code: verify before you believe. After any step that changes something outside the session, look at the result itself. Run `gh pr view` instead of trusting "PR created!", and `gh issue view` instead of trusting "ticket updated".

## Why the Architect is named for a job a human does

Because of rule 1. The Architect skill puts each decision to you and waits. It looks facts up in the codebase rather than asking you, but the decisions are yours. Every stage is named for what it produces, not for who produces it.
