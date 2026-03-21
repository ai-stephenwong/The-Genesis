# developer — Self-Review — 2026-03-21 15:30

## Trigger
  Bug report: artifacts/development/bug-report-20260321-1530.md
  Round: 2 (deployment round)

---

## Observations

### OBS-01 — vercel.json framework set to nextjs for a Vite app (DEPLOY-MAJ-03)

**What was found:**
`omnichat-v1-web/vercel.json` contained `"framework": "nextjs"`. Vercel detected this,
attempted a Next.js build, and immediately failed with "No Next.js version detected."
Additionally the rewrite rule used `_next/` path exclusions and the static cache
header targeted `/_next/static/` — both Next.js-specific conventions that are
meaningless for a Vite SPA (which outputs to `assets/`).

**What this agent did:**
I wrote `vercel.json` for the public web frontend with the wrong framework setting.
The CMS `vercel.json` was correct (`"framework": "vite"`). The inconsistency indicates
I wrote the web `vercel.json` by copying from a Next.js template or a previous project
rather than from the CMS's correct Vite configuration.

**Why it slipped through:**
The `vercel.json` file is not TypeScript — it has no compiler that catches a wrong
`framework` value. The error surfaces only when Vercel actually runs a build.
I did not perform a local `vercel build` or `vercel --yes` dry-run before submitting
the frontend code. There was no checklist item requiring me to verify that the
`vercel.json` framework field matches the framework listed in `package.json`.

---

### OBS-02 — Multiple TypeScript build failures and missing packages across both frontends (DEPLOY-MAJ-04)

**What was found:**
Both frontends failed `tsc` on Vercel due to:

1. Missing `vite-env.d.ts` — `import.meta.env` produced "Property 'env' does not
   exist on type 'ImportMeta'" in every file that read environment variables.
2. `vite.config.ts` used `defineConfig` from `vite` rather than from `vitest/config`,
   making the `test` block an unknown property and causing a TypeScript error.
3. Missing `src/test/setup.ts` in the web frontend (config referenced it but it
   didn't exist).
4. `noUnusedLocals`/`noUnusedParameters` violations across multiple source files —
   unused imports, unused destructured variables — that were present in submitted code.
5. Missing npm packages: `react-hook-form`, `@hookform/resolvers`, `zod` in
   `omnichat-v1-web/package.json` despite being imported in `ContactForm.tsx`.
6. `@radix-ui/react-badge` listed in CMS `package.json` — this package does not
   exist in the npm registry (the Badge in shadcn/ui is a plain CVA component, not
   a Radix primitive).
7. `@hey-api/openapi-ts@^0.39.3` does not exist — correct version is `^0.94.0`.
8. `vitest@^1.6.0` in the API is incompatible with `@cloudflare/vitest-pool-workers`
   which requires `vitest@"2.0.x - 2.1.x"`.
9. YAML parse error in `api-spec.yaml` — an unquoted description string containing
   `: ` (colon-space) was parsed as a YAML mapping entry.

**What this agent did:**
I submitted both frontend repositories without running a clean `npm install && npm
run build` to verify that the projects build from scratch. The TypeScript errors,
missing packages, and non-existent package references would all have been caught by
a single `tsc` run. The `noUnusedLocals` violations indicate I did not run
`npm run build` at all before submitting — that command runs `tsc` with strict
settings as its first step.

**Why it slipped through:**
There was no mandatory "verify clean build" gate in the developer role. The
developer responsibilities include writing code and tests but do not explicitly
require a clean `npm install && npm run build` pass in the submission checklist.
I relied on the code being syntactically correct in my editor rather than running
a full compilation against strict tsconfig settings. The package.json errors
(non-existent packages, wrong versions) indicate I did not verify packages against
the npm registry before adding them.

---

## Root Causes

| # | Root Cause | Affected Observations |
|---|---|---|
| RC-01 | No mandatory clean-build verification step before submitting frontend code — a single `npm run build` would have caught all TypeScript errors, missing packages, and config issues before deployment | OBS-02 |
| RC-02 | `vercel.json` framework field not verified against `package.json` — deployment config was not cross-checked against the actual framework used | OBS-01 |
| RC-03 | npm packages added to `package.json` without verifying they exist in the registry at the stated version — would have been caught by `npm install` | OBS-02 (items 6, 7, 8) |
| RC-04 | YAML spec file not validated with a YAML linter or OpenAPI linter before submission — a parse error in `api-spec.yaml` would fail any tool that consumes it | OBS-02 (item 9) |

---

## Suggested Improvements

### SUG-01 — Add a mandatory clean-build gate to the developer Spec Compliance Checklist

Before marking any frontend feature complete and before submitting for review, the
developer must run and confirm a passing `npm ci && npm run build` from a clean
state. This is the single most effective gate for catching TypeScript errors, missing
packages, configuration issues, and strict-mode violations before the code leaves
the developer's hands.

### SUG-02 — Add vercel.json/deployment config framework verification to the developer checklist

For Vercel deployments, the developer must verify that the `"framework"` field in
`vercel.json` matches the framework used in `package.json`, the rewrite rules are
appropriate for that framework's output structure, and static asset cache headers
reference the correct output paths.

### SUG-03 — Add api-spec.yaml YAML validity check to the developer checklist

Before submitting any change to `api-spec.yaml`, the developer must run a YAML
linter or OpenAPI validator (`spectral lint`, `swagger-parser`, or `npx openapi-ts
--check`) to confirm the spec is parseable. A broken spec file breaks all downstream
tooling (client generation, documentation, linting).

---

## Summary

Both findings are execution failures attributable to this agent. Neither required
complex analysis to prevent — a single `npm run build` run would have caught
virtually all issues in OBS-02, and a cross-check of the vercel.json framework field
against package.json would have caught OBS-01. The improvements above are each a
simple, mandatory verification step that is currently absent from the developer
submission checklist.

---

## Sign-off: developer — 2026-03-21 15:30
