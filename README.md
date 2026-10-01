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
    <img alt="The line: you write a PRD; grill-with-docs settles the decisions; agent-skills plan writes the plan; to-tickets publishes tickets with blocking edges; the dev loop, where one agent builds, an agent from another vendor reviews, and a PR Guardian answers review threads, opens draft PRs; verify checks every flag state; you merge." src="docs/assets/line-light.svg" width="100%">
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

The line is built from good skills that already exist, plus the two pieces they don't cover: an unattended dev loop and a verifier.

| Stage | Skill | What happens | You decide |
|---|---|---|---|
| **1&nbsp;·&nbsp;Decide** | `grill-with-docs`<br><sub>Matt Pocock</sub> | Settles every open decision with you, one question at a time, and records them as ADRs | *Do the decisions hold?* |
| **2&nbsp;·&nbsp;Plan** | `agent-skills:plan`<br><sub>Addy Osmani</sub> | Splits the work into small, verifiable tasks with dependencies | *Is this the right plan?* |
| **3&nbsp;·&nbsp;Tickets** | `to-tickets`<br><sub>Matt Pocock</sub> | Publishes GitHub issues with acceptance criteria and blocking edges | *Right tickets, right edges?* |
| **4&nbsp;·&nbsp;Dev&nbsp;loop** | `/alf:dev-loop`<br><sub>this repo</sub> | Up to two tickets at a time. One agent builds test-first, an agent from another vendor reviews, and a draft PR opens only when the tests pass | Nothing. It runs unattended |
| **5&nbsp;·&nbsp;Verify** | `/alf:verify`<br><sub>this repo</sub> | Runs the app and checks every feature-flag state, reporting PASS, FAIL or NOT RUN | *Merge.* That step is always yours |

## Guardrails

- **Decisions before code.** A ticket without acceptance criteria and blocking edges never reaches an agent.
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

Install AI Light Factory and the two skill packs it builds on:

```text
/plugin marketplace add lmagsino/ai-light-factory
/plugin install alf@ai-light-factory
/plugin marketplace add mattpocock/skills
/plugin install mattpocock-skills@mattpocock
/plugin marketplace add addyosmani/agent-skills
/plugin install agent-skills@addy-agent-skills
```

Then run the line:

```text
/setup-matt-pocock-skills                         # once: point Matt's ticket skills at GitHub
/alf:dev-loop setup                               # once per repo: seams, agents, companion paths
/mattpocock-skills:grill-with-docs docs/prd.md    # 1. decide
/agent-skills:plan                                # 2. plan
/mattpocock-skills:to-tickets tasks/plan.md       # 3. tickets
/alf:dev-loop #<parent-issue> --budget 2          # 4. dev loop, unattended
/alf:verify #<parent-issue>                       # 5. every flag state
```

Requirements: git, an authenticated `gh`, `jq` and `python3`. The dev loop runs as a Claude Code plugin today, and its seats can be any agent. Full setup: [docs/install.md](docs/install.md).

<!-- Results from real runs go here, failures included. See docs/demo.md. -->

## Skills

**From this repo.** These two are the part no existing pack covered:

| Skill | When | What it does |
|---|---|---|
| `/alf:dev-loop` | per parent issue or milestone | Runs the unattended dev loop: up to two tickets at a time through build, cross-vendor review and fixes, to a draft PR, with a live board. Its seats are a Developer, a Reviewer from another vendor, and a PR Guardian that answers review threads and never marks a PR ready. Also has `setup` and `retro` modes. |
| `/alf:verify` | per parent issue or milestone | Drives the running app in every feature-flag state, and records each journey as PASS, FAIL, NOT RUN or N/A with evidence. |

**From the companion packs,** used as published:

| Skill | Pack | Role in the line |
|---|---|---|
| `grill-with-docs` | [Matt Pocock](https://github.com/mattpocock/skills) | Stage 1. Settles the decisions and writes ADRs and a glossary |
| `to-tickets` | [Matt Pocock](https://github.com/mattpocock/skills) | Stage 3. Publishes tickets with blocking edges |
| `plan` | [Addy Osmani](https://github.com/addyosmani/agent-skills) | Stage 2. Writes the plan |
| `incremental-implementation`, `test-driven-development` | [Addy Osmani](https://github.com/addyosmani/agent-skills) | How the Developer seat builds |
| `code-review-and-quality` | [Addy Osmani](https://github.com/addyosmani/agent-skills) | How the Reviewer seat reviews, plus the dev loop's three reach questions |

The seats read the companion SKILL.md files by absolute path, so an agent from another vendor in a seat follows them too.

## Docs

[The line](docs/the-line.md) · [Guardrails](docs/guardrails.md) · [Rules](docs/rules.md) · [Install and agents](docs/install.md) · [Cost](docs/cost.md) · [Comparison](docs/comparison.md) · [Demo](docs/demo.md)

## Sources and inspiration

- [mattpocock/skills](https://github.com/mattpocock/skills): `grill-with-docs` and `to-tickets`, which run stages 1 and 3.
- [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills): `plan` for stage 2, and the build and review skills the seats follow.
- Addy Osmani, [Software Factories, Light and Dark](https://addyosmani.com/blog/software-factories/): the light versus dark factory distinction this project is built on.
- [addyosmani/factory](https://github.com/addyosmani/factory): a reference light factory built on a GitHub issue queue.
- [Agent Skills specification](https://agentskills.io/specification): the open `SKILL.md` format these skills follow.
- Claude Code [plugins](https://code.claude.com/docs/en/plugins-reference) and [hooks](https://code.claude.com/docs/en/hooks): how AI Light Factory installs and how its guard hook works.
- [Codex CLI](https://developers.openai.com/codex/skills): the second-vendor reviewer in the reference setup.
- [awesome-software-factories](https://github.com/varun1505/awesome-software-factories): the wider landscape. See [docs/comparison.md](docs/comparison.md) for how this project differs.

## About

Built by **Leo Magsino Jr**, a tech lead working on how teams ship with fleets of coding agents without losing the plot.
[GitHub](https://github.com/lmagsino)

Built on Matt Pocock's and Addy Osmani's skills; the term *light software factory* is Addy's. See [CREDITS.md](CREDITS.md). Licensed [MIT](LICENSE).
