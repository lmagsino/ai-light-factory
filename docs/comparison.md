# How AI Light Factory compares

This was surveyed in October 2026. These projects move fast, so check each one's README before relying on this table. Each is good at what it is for. This page exists to say what AI Light Factory is for.

| Project | Shape | Stops at | Second vendor | Verifier runs the app | Lane / cost caps |
|---|---|---|---|---|---|
| **AI Light Factory** | PRD → decisions → plan → tickets → unattended dev loop → verifier | **draft PR**, enforced by a hook | **required** seat, any vendor | **yes, every flag state, NOT RUN reported** | **2 lanes, budget, per-seat $** |
| [addyosmani/factory](https://github.com/addyosmani/factory) | GitHub issue queue + charter, scheduled agents | draft PR | Claude and Codex share the queue | independent verify step | back-pressure cap |
| [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) (`/lfg`) | brainstorm → plan → work → review → compound | PR, watching CI | optional model routing | browser tests | bounded repair loops |
| [superpowers](https://github.com/obra/superpowers) | brainstorm → plan → subagent build → review | offers merge / PR / keep | no | no | no |
| [gstack](https://github.com/garrytan/gstack) | toolkit of review, QA and ship commands | PR (`/ship`); can land and deploy | `/codex` second opinion | `/qa` drives a browser | no |
| [spec-kit](https://github.com/github/spec-kit) | constitution → specify → plan → tasks → implement | implementation | no | no | no |
| [Taskplane](https://github.com/HenryLach/taskplane) | dependency graph, worktree lanes | **merges** | cross-model reviewer | no | lanes |
| [DoorDash agentic-orchestrator](https://github.com/doordash-oss/agentic-orchestrator) | research → design → roadmap → implement → review → publish | publish with evidence | Claude, Codex and OpenCode co-equal | verification evidence | iteration caps |

## What AI Light Factory does not do

- **No issue triage or scheduled queue.** Use addyosmani/factory for that. AI Light Factory starts from a PRD you bring.
- **No merging and no deploying.** That is on purpose. Pair it with your own CI and release train.
- **No swarm.** Two lanes is the ceiling, and it is not a starting point to tune upward.
- **No hosted service.** Everything runs in your terminal, against your GitHub, on your accounts.

## Label-triggered agents

If what you want is "label an issue, get a PR", GitHub already has good building blocks: [claude-code-action](https://github.com/anthropics/claude-code-action) (`label_trigger`), [codex-action](https://github.com/openai/codex-action), and Copilot's cloud agent. [examples/github-action](../examples/github-action/) shows an **experimental** workflow that runs a single ticket through AI Light Factory's dev loop when an issue is labelled `factory:ready`.
