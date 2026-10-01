# Reach matrix

Review question 2 asks: *does this change touch code that other paths run through?* That is the only review question you cannot answer by reading the diff, because the answer depends on what else runs through the files the diff touched. So write it down once, per area, and keep it current.

- **shared**: several features, tenants, regions or states run through it. A change here is correct in the case you tested and can still be wrong in the others.
- **specific**: one path only.
- **registry**: configuration or data that switches behaviour everywhere with no code change at all. Treat every edit as shared.

| Path (glob) | Class | What runs through it | Notes |
|---|---|---|---|
| `src/billing/providers/base/**` | shared | every provider | |
| `src/billing/providers/acme/**` | specific | the Acme provider only | |
| `config/providers.yml` | registry | every tenant, at boot | |

Keep it short. The rows that matter are the shared and registry ones, since a reviewer already treats anything unlisted as specific.
