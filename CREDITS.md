# Credits

AI Light Factory was designed and written by **Leo Magsino Jr**, including the line's structure, the five rules in [docs/rules.md](docs/rules.md), the dev loop and the guardrails. It is built on two skill packs, used as published:

- **Matt Pocock**'s [skills](https://github.com/mattpocock/skills) (MIT) run the first and third stages as they are: `grill-with-docs` settles the decisions and writes the ADRs, and `to-tickets` publishes the tickets with their blocking edges.
- **Addy Osmani**'s [agent-skills](https://github.com/addyosmani/agent-skills) (MIT) run the plan stage (`plan`), and the Developer and Reviewer seats follow its `incremental-implementation`, `test-driven-development` and `code-review-and-quality` skills. His post ["Software Factories, Light and Dark"](https://addyosmani.com/blog/software-factories/) (2026) named the light factory, and his [factory](https://github.com/addyosmani/factory) is the reference issue-queue factory.

AI Light Factory adds what those packs don't have: the dev loop (`dev-loop`), the Verifier (`verify`), the readiness gate, the guard and shims, the seats, and the board.

No code from these projects is copied into this repository: they are installed alongside it. If you contribute something that is adapted from another project, keep its copyright line and license, and add it here.
