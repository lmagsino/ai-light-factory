<h1 align="center">AI Light Factory</h1>

<p align="center">
  <b>A light software factory.</b><br>
  PRD in, reviewed draft PRs out. The agents draft. You merge.
</p>

<p align="center">
  <a href="https://github.com/lmagsino/ai-light-factory/actions/workflows/validate.yml"><img alt="validate" src="https://github.com/lmagsino/ai-light-factory/actions/workflows/validate.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/line-dark.svg">
    <img alt="The line: you write a PRD; the Architect settles decisions; the Planner writes tickets with real edges; a build band where one agent builds and an agent from another vendor reviews opens draft PRs; the Verifier checks every flag state; you merge." src="docs/assets/line-light.svg" width="100%">
  </picture>
</p>

## What is a light factory?

A *dark* factory ships code that no human has read. A *light* factory keeps you in the loop and moves your judgement to where it pays off. You settle the decisions and approve the plan up front. Agents build and review unattended. You read every diff before it merges.

AI Light Factory never marks a PR ready, never approves, and never merges. The tools enforce that, not the prompt.

## Why I built this

I'm a tech lead. Over the past year my work moved from "an engineer with an AI pair" to "an engineer running a line of agents". Running a line like this on a production codebase taught me three things:

- **The bottleneck moves.** Agents write code faster than anyone can read it, so the guardrails belong on decisions, review and verification.
- **Unlimited parallelism is a trap.** Run wide open, it burns a week of model budget in days, and nobody can review that much. Two lanes is the ceiling.
- **A reviewer from the same vendor shares the builder's blind spots.** Its misses are silent.

This is that line, rebuilt from scratch for open source, with each lesson turned into a default. — **Leo Magsino Jr**

## How it works

| Stage | What happens | You decide |
|---|---|---|
| **1&nbsp;·&nbsp;Architect** | Reads the PRD and everything it links, then settles every open decision with you, one question at a time | *Do the decisions hold?* |
| **2&nbsp;·&nbsp;Planner** | Splits the work into small tickets with real dependency edges, then creates the issues | *Right tickets? Create them?* |
| **3&nbsp;·&nbsp;Build&nbsp;band** | Up to two tickets at a time. One agent builds test-first, an agent from another vendor reviews, and a draft PR opens only when the tests pass | Nothing. It runs unattended |
| **4&nbsp;·&nbsp;Verifier** | Runs the app and checks every feature-flag state, reporting PASS, FAIL or NOT RUN | *Merge.* That step is always yours |

## Guardrails

- **Decisions before code.** A ticket without criteria, edges and a size never reaches an agent.
- **Stops at a draft PR.** Merge, ready and approve are blocked for every worker, whatever agent it runs.
- **Green tests or no PR.**
- **A second vendor reviews,** with fresh context, for at most two rounds.
- **Every call is in the PR body:** what was fixed, what was left for you, and what was dropped and why.
- **Bounded:** two lanes, a ticket budget, and per-seat caps.
- **NOT RUN is reported, never hidden.** Silence doesn't count as a pass.

How each one is enforced: [docs/guardrails.md](docs/guardrails.md).

## The rules

1. **Never guess for the human.** Wait for a decision instead of inventing one.
2. **Questions belong on the ticket,** not in a run.
3. **No evidence, no block.** The search that returns nothing is the evidence.
4. **Stack on open work.** An unmerged dependency is a base branch, not a blocker.
5. **Two review rounds, then a human.**

And one habit: **check the effect, not the message.** More in [docs/rules.md](docs/rules.md).

## Bring your own agents

Every seat (Developer, Reviewer, Guardian, Verifier) is an agent you choose. Any coding-agent CLI that takes a prompt can fill one. I run Claude Code for building and Codex for review, but those are just what I use. See [docs/install.md](docs/install.md#choosing-agents-per-seat).

## Quick start

```text
/plugin marketplace add lmagsino/ai-light-factory
/plugin install alf@ai-light-factory
```

```text
/alf:setup                          # once per repo
/alf:architect docs/prd.md          # settle the decisions
/alf:plan                           # tickets with real edges
/alf:tickets                        # asks "create these?"
/alf:loop "M1" --budget 2           # unattended, two lanes max
/alf:verify "M1"                    # every flag state
```

Requirements: git, an authenticated `gh`, `jq` and `python3`. The orchestrator runs as a Claude Code plugin today. Full setup: [docs/install.md](docs/install.md).

<!-- Results from real runs go here, failures included. See docs/demo.md. -->

## Skills

| Skill | When | What it does |
|---|---|---|
| `/alf:setup` | once per repo | Finds your test, dev-server, e2e and feature-flag commands, picks an agent for each seat, and writes `.factory/config.json` and the seams block in AGENTS.md. |
| `/alf:architect` | once per project | Reads the PRD and everything it links, then settles each open decision with you, one question at a time. Writes numbered decision cards, each naming the trap it leaves behind. |
| `/alf:plan` | once per project | Checks how much of the work already exists, then writes milestones, XS/S tickets, real blocking edges and a lane model. |
| `/alf:tickets` | once per plan | Does a dry run, asks "create these?", then opens the GitHub milestones and issues and gates each one. |
| `/alf:loop` | per milestone | Runs the unattended build band: up to two tickets at a time through build, cross-vendor review and fixes, to a draft PR. Prints the board as it goes. |
| `build` | dispatched by the loop | The Developer seat. Builds test-first, fixes only the findings it is handed, squashes, and opens a draft PR only from green tests. |
| `review` | dispatched by the loop | The Reviewer seat, from another vendor. Checks correctness plus three reach questions: outward contracts, shared code paths, and deliberate deviations. |
| `guardian` | dispatched by the loop | The PR Guardian. Answers and resolves review threads and rebases stacked PRs. Never marks a PR ready. |
| `/alf:verify` | per milestone | Drives the running app in every feature-flag state, and records each journey as PASS, FAIL, NOT RUN or N/A with evidence. |
| `/alf:retro` | after a run | Works out which stage should have caught each problem, proposes the check to add there, and prints the run's stats. |

Every skill is a `SKILL.md` in the open [Agent Skills](https://agentskills.io/specification) format, so the seat skills run in any agent that reads it.

## Docs

[The line](docs/the-line.md) · [Guardrails](docs/guardrails.md) · [Rules](docs/rules.md) · [Install and agents](docs/install.md) · [Cost](docs/cost.md) · [Comparison](docs/comparison.md) · [Demo](docs/demo.md)

## Sources and inspiration

- Addy Osmani, [Software Factories, Light and Dark](https://addyosmani.com/blog/software-factories/): the light versus dark factory distinction this project is built on.
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills): engineering skills for incremental builds, TDD and code review that pair well with the Developer and Reviewer seats.
- [addyosmani/factory](https://github.com/addyosmani/factory): a reference light factory built on a GitHub issue queue.
- [mattpocock/skills](https://github.com/mattpocock/skills): `grill-with-docs`, whose one-question-at-a-time interview the Architect borrows, and `to-tickets`.
- [Agent Skills specification](https://agentskills.io/specification): the open `SKILL.md` format every skill here follows.
- Claude Code [plugins](https://code.claude.com/docs/en/plugins-reference) and [hooks](https://code.claude.com/docs/en/hooks): how AI Light Factory installs and how its guard hook works.
- [Codex CLI](https://developers.openai.com/codex/skills): the second-vendor reviewer in the reference setup.
- [awesome-software-factories](https://github.com/varun1505/awesome-software-factories): the wider landscape. See [docs/comparison.md](docs/comparison.md) for how this project differs.

## About

Built by **Leo Magsino Jr**, a tech lead working on how teams ship with fleets of coding agents without losing the plot.
[GitHub](https://github.com/lmagsino)

The term *light software factory* comes from Addy Osmani, and the Architect's interview style from Matt Pocock's `grill-with-docs`. See [CREDITS.md](CREDITS.md). Licensed [MIT](LICENSE).
