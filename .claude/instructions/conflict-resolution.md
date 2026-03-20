# Standards Conflict Resolution Policy

Applies to **all agents** — whenever a project decision conflicts with a company standard in `agent_docs/generic/`, or when requirements specify something that differs from the company default.

---

## When a Conflict is Detected

1. **STOP** — do not implement the override or silently default to the standard
2. **Alert the user** with a structured conflict summary:

```
⚠️ Standards conflict detected:

  Rule source : agent_docs/generic/[filename].md — [rule name]
  Standard    : [what the company standard says]
  Requirement : [what the project requires or the proposed override]

  Options:
    A) Keep company standard — [brief description]
    B) Override — [brief description of the override]

  Which would you like? [A / B, or describe a different approach]
```

3. **Record the decision immediately** — whether the standard is kept OR overridden — in the relevant project-specific file:

| Type of conflict | Record in |
|---|---|
| Technology, library, framework, or hosting choice | `agent_docs/project/stack.md` |
| API conventions, pagination style, token expiry, rate limits | `agent_docs/project/conventions.md` |
| Security exceptions (password reset window, session length, etc.) | `agent_docs/project/conventions.md` |

---

## Conflict Resolution Table Format

Add or update the `## Conflict Resolutions` table at the top of the target file (just below the file header):

```markdown
## Conflict Resolutions (YYYY-MM-DD)

| Conflict | Original | Replaced by | Reason |
|---|---|---|---|
| CONFLICT-01 | ~~company standard being overridden~~ | **override decision** | reason |
| CONFLICT-02 | ~~alternative option~~ | **Company standard maintained** | reason |
```

**Rules:**
- `~~strikethrough~~` marks the **rejected** option (always the one not chosen)
- **Bold** marks the **chosen** option
- If keeping the company standard: write `**Company standard maintained**` in "Replaced by"; strikethrough the requirement/alternative
- If overriding: write the override in bold; strikethrough the company standard
- Conflict IDs are sequential within the project: CONFLICT-01, CONFLICT-02, …
- Entries are a permanent audit trail — never delete a resolved conflict entry
- Append new entries as they arise; do not rewrite existing ones

---

## Agents Responsible

| Agent | When to invoke conflict resolution |
|---|---|
| `requirements-analyst` | When raw requirements conflict with any generic standard — flag in analysis output |
| `solution-architect` | When architecture or stack choices conflict with standards (primary owner) |
| `developer` | When implementation constraints conflict with coding conventions or NFRs |
| `devops-engineer` | When platform or infra choices conflict with deployment standards |
