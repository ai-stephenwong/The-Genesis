# Requirements Registry — [Project Name]

> This file is the **index** for all project requirements.
> Actual requirement files live in `agent_docs/project/specs/requirements-include-files/`.
> Do not write requirements directly here — register them in the table below.

---

## Requirements File Registry

| File | Description | Last Updated (file) | Last Reviewed | Drift? |
|------|-------------|---------------------|---------------|--------|
| _(none yet — add files to `requirements/` and register here)_ | | | | |

---

## How to Add a Requirements File

1. Create a `.md` file in `agent_docs/project/specs/requirements-include-files/`
2. Start the file with `<!-- last-updated: YYYY-MM-DD -->`
3. Add a row to the registry table above
4. Set `Last Reviewed` to today's date in the registry

**Suggested file breakdown** (use as many or as few as needed):

| Suggested File | Content |
|---|---|
| `01-functional.md` | Feature-by-feature functional requirements |
| `02-nonfunctional.md` | Project-specific NFR overrides |
| `03-ui-ux.md` | UI/UX requirements and screen flows |
| `04-integrations.md` | Third-party API and integration requirements |
| `05-data.md` | Data models, retention, migration requirements |
| `06-security.md` | Project-specific security requirements |
| `07-out-of-scope.md` | Explicit exclusions to prevent scope creep |
| `08-open-questions.md` | Outstanding questions and assumptions |

---

## Drift Check Instructions (for Claude)

**At the start of every conversation**, do the following automatically:

1. Read this registry file
2. For each row in the registry table, read the corresponding file in `agent_docs/project/specs/requirements-include-files/`
3. Extract its `<!-- last-updated: YYYY-MM-DD -->` tag
4. Compare against the `Last Reviewed` date in the registry
5. If any file's `last-updated` is **newer** than `Last Reviewed`, immediately alert the user before doing anything else:

```
⚠️ Requirements have been updated since they were last reviewed:

  • 01-functional.md    updated: 2026-04-01   last reviewed: 2026-03-16
  • 03-ui-ux.md         updated: 2026-03-28   last reviewed: 2026-03-16

Would you like to review the changes before we continue? [Y/n]
```

6. If the user says **yes** — read each updated file, summarise what has changed, and ask whether the changes affect current work in progress
7. If the user says **no** — acknowledge, continue with the session, but flag it again at the start of the next session
8. Update `Last Reviewed` in this registry **only** when the user explicitly confirms they have reviewed a file
