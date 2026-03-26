# Environment Variable Contract

> **Owner:** `solution-architect`
> **Change control:** See `agent-roles.md` — Universal Rule — Environment Variable change control.
> No agent may add, rename, or remove env vars without approval. Change requests go to `artifacts/development/env-var-change-requests-YYYYMMDD.md`.

---

## Naming Conventions

- Use the framework's required prefix: `NEXT_PUBLIC_` (Next.js), `VITE_` (Vite), none (server-side)
- Use `SCREAMING_SNAKE_CASE`
- Use `_URL` suffix for URLs (not `_ENDPOINT`, `_HOST`, or `_ORIGIN`)
- Use `_KEY` suffix for API keys

---

## Contract

| Env var key | Service | Required? | Source / Set by | Description |
|---|---|---|---|---|
| <!-- Example: `DATABASE_URL` | API server | Yes | Neon → Doppler → CI | PostgreSQL connection string --> |
| <!-- Example: `NEXT_PUBLIC_API_BASE_URL` | Frontend (Next.js) | Yes | Vercel env var | API server base URL --> |
| <!-- Example: `JWT_SECRET` | API server | Yes | Doppler → CI | JWT signing secret --> |

<!-- Delete the example comments above and fill in the actual env vars for this project. -->

---

## Change Log

| Date | Action | Env var key | Requested by | Change request ref | Status |
|---|---|---|---|---|---|
| <!-- YYYY-MM-DD | ADD | `NEW_VAR` | developer | env-var-change-requests-YYYYMMDD.md | Approved --> |
