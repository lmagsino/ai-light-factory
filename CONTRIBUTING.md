# Contributing

Thank you. AI Light Factory gets better in one way: someone runs it on real work, sees a stage miss something, and puts the check where it should have been.

## The best contributions

1. **A retro from a real run.** Open an issue with your `/alf:dev-loop retro` output, or the relevant part of it. Say what parked, what slipped through to you, and which stage should have caught it. Leave out anything you cannot share.
2. **A mechanical check that replaces a sentence.** If a SKILL.md says "always do X" and a script could verify X, that is a great PR.
3. **Adapters.** Flag platforms for the Verifier, test-runner detection for setup, or trackers other than GitHub Issues.

## Making a change

- Read [AGENTS.md](AGENTS.md) for the rules on skills and scripts.
- Explain in the PR body what happened, which stage should have caught it, and what you changed. Changes to the line are reviewed like code, because they are code.
- Run the checks listed in AGENTS.md.
- Keep the guardrails intact. PRs that let the dev loop merge, mark ready, approve, or run more than two lanes will not be accepted. Fork for that, and call it something else.

## Dogfooding

You can build AI Light Factory with itself: write a short PRD for your change, then run the line on this repo. Draft PRs opened this way are welcome, and should say so in the description.
