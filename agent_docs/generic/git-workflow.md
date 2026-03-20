<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# Git Workflow Standards (Company Standard)

> These rules apply to all projects. Do not override without explicit approval.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## Branching Model (GitFlow)

```
main          ← production-ready, protected, always deployable
develop       ← integration branch, protected
feature/*     ← new features (branch from develop)
fix/*         ← bug fixes (branch from develop)
release/*     ← release candidates (branch from develop)
hotfix/*      ← urgent production fixes (branch from main)
```

### Branch Lifecycle

| Branch       | Created from | Merges into            | Deleted after merge |
|--------------|--------------|------------------------|---------------------|
| `feature/*`  | `develop`    | `develop`              | Yes                 |
| `fix/*`      | `develop`    | `develop`              | Yes                 |
| `release/*`  | `develop`    | `main` + `develop`     | Yes                 |
| `hotfix/*`   | `main`       | `main` + `develop`     | Yes                 |

- `main` and `develop` are **permanent protected branches** — never deleted
- Short-lived branches must be deleted within **3 days** of merging

## Branch Naming

```
feature/TICKET-123-short-description
fix/TICKET-456-short-description
hotfix/critical-login-failure
release/v1.2.0
```

- Use kebab-case, lowercase only
- Always include ticket/issue number where one exists
- Keep description concise (3–5 words max)
- No personal names or dates in branch names

## Commit Messages (Conventional Commits)

```
<type>(<scope>): <short description>

[optional body — explain the why, not the what]

[optional footer — breaking changes, issue refs]
```

### Types

| Type       | When to use                                              |
|------------|----------------------------------------------------------|
| `feat`     | New feature or capability                                |
| `fix`      | Bug fix                                                  |
| `chore`    | Maintenance, dependency updates, config changes          |
| `docs`     | Documentation only                                       |
| `test`     | Adding or updating tests                                 |
| `refactor` | Code restructure with no behaviour change                |
| `perf`     | Performance improvement                                  |
| `ci`       | CI/CD pipeline changes                                   |
| `revert`   | Reverting a previous commit                              |

### Examples

```
feat(auth): add JWT refresh token rotation
fix(api): handle null response from payment gateway
chore(deps): upgrade Spring Boot to 3.2.1
docs(readme): update local setup instructions
test(user-service): add integration tests for registration
ci(deploy): add container scan stage to prod pipeline
```

### Rules

- Subject line: max 72 characters, imperative mood ("add" not "added")
- Do not end subject line with a period
- Body: wrap at 72 characters; explain *why*, not *what*
- Reference ticket numbers in footer: `Refs: TICKET-123`
- Breaking changes must be noted: `BREAKING CHANGE: <description>`

## Pull Requests
`ISO 27001: 8.25, 8.32`

### Title & Description

- PR title must follow the same Conventional Commits format as commit messages
- Description must include:
  - **What changed** — brief summary
  - **Why** — motivation or ticket reference
  - **How to test** — steps to verify the change
  - **Screenshots** — for any UI changes

### Review Requirements

- Minimum **1 reviewer approval** required before merge
- Author cannot approve their own PR
- All CI checks must pass before merge is permitted `[8.29]`
- Reviewers must check: logic correctness, security implications, test coverage, standards compliance
- For changes to auth, payments, or PII handling: minimum **2 reviewer approvals** required `[8.2]`

### Merge Strategy

| Target Branch | Merge Strategy  | Notes                                      |
|---------------|-----------------|--------------------------------------------|
| `develop`     | Squash merge    | Keeps history clean; one commit per feature|
| `main`        | Merge commit    | Preserves release history                  |

- **Never force-push** to `main` or `develop`
- **Never rebase** shared branches (`main`, `develop`, `release/*`)
- Delete source branch immediately after merge

### Draft PRs

- Use draft PRs for work-in-progress — signals "not ready for review"
- Convert to ready only when: tests pass, self-review done, description complete

## Protected Branches
`ISO 27001: 8.3, 8.32`

Both `main` and `develop` must be protected with:

- [ ] Require PR before merging (no direct pushes)
- [ ] Require minimum 1 approval (2 for `main`)
- [ ] Dismiss stale reviews on new commits
- [ ] Require all CI status checks to pass
- [ ] Require branches to be up to date before merge
- [ ] Restrict who can push (tech leads / CI service account only for `main`)
- [ ] No force pushes
- [ ] No branch deletion

## Release Process

1. Branch `release/vX.Y.Z` from `develop`
2. Only bug fixes and release prep commits allowed on this branch (no new features)
3. Update version number and changelog
4. Raise PR: `release/vX.Y.Z` → `main`
5. After merge to `main`: tag the commit as `vX.Y.Z`
6. Back-merge `main` → `develop` to capture any release fixes

## Hotfix Process

1. Branch `hotfix/<description>` from `main`
2. Apply minimal fix — no unrelated changes
3. Raise PR: `hotfix/*` → `main` (2 approvals required)
4. After merge: tag `main` with a patch version `vX.Y.Z+1`
5. Back-merge `main` → `develop` immediately

## Tagging & Versioning

- Use [Semantic Versioning](https://semver.org/): `vMAJOR.MINOR.PATCH`
- Tags must be annotated: `git tag -a v1.2.3 -m "Release v1.2.3"`
- Tags must only be created on `main`
- Never delete or move tags

## Audit & Access Control
`ISO 27001: 8.3, 8.15`

- All commits are traceable to an individual via verified Git identity `[8.15]`
- Repository access reviewed and re-approved every 90 days `[8.3]`
- Revoke access immediately on role change or departure `[8.3]`
- CI/CD service accounts use separate credentials — not personal tokens `[8.5]`
- Repository access logs retained for minimum 12 months `[8.15]`
