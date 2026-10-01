# Toggling flags locally, by platform

Verify these against your own setup and record the exact commands in `.factory/config.json` → `flags.notes`. The rule is the same everywhere: **toggle only the gate under test, and put it back afterwards.**

| Platform | Typical local toggle | Watch for |
|---|---|---|
| LaunchDarkly | a local dev server or test data source, or a dedicated dev environment's flag | toggling in a shared environment changes it for everyone else on it |
| Flipper (Ruby) | `Flipper.enable(:flag)`, and turning off only the boolean gate you enabled | a blanket "disable" can clear actor, group and percentage gates too. Check your version's semantics before you use it |
| Unleash | a local Unleash instance, or the API with an admin token for a dev project | strategies and constraints, not just on/off |
| GrowthBook | a local features payload, or forced values in the SDK | forced values must be cleared after the run |
| OpenFeature | an in-memory provider in the test setup | make sure the app under test uses the same provider |
| env var / config | restart the dev server with the variable set or unset | a cached config needs a restart, not a reload |

## The account-setting gate

If a flag is paired with a per-account (or per-tenant) setting, find:
- where the setting lives, and its **default** for existing and new accounts
- every call site that reads the flag, and whether each one also reads the setting

A call site that reads the flag alone is the classic bug the middle row catches: the whole rollout cohort is switched on without opting in.
