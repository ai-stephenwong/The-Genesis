# Git Workflow — [Project Name]

> Project-specific Git configuration and overrides.
> Company-wide GitFlow standards: @agent_docs/generic/git-workflow.md
> Fill in all [placeholders] before the project kicks off.

## Repository

- **GitHub Org / URL:** [https://github.com/[org]/[repo]]
- **Default Branch:** `main`
- **Integration Branch:** `develop`

## Branch → Environment Mapping

| Branch        | Deploys to  | Notes                              |
|---------------|-------------|------------------------------------|
| `develop`     | dev         | Automatic on push                  |
| `release/*`   | staging     | Automatic on push                  |
| `main`        | production  | Automatic on merge via approved PR |

## Ticket / Issue Tracker

- **Tool:** [Jira / Linear / GitHub Issues]
- **Project / Board URL:** [URL]
- **Ticket prefix:** [e.g. PROJ, APP, TICKET]
- **Branch naming example:** `feature/PROJ-123-user-login`

## Review Requirements

> Defaults from company standard — only override here if different for this project.

| Scenario                                         | Min Approvals |
|--------------------------------------------------|---------------|
| Standard PR → `develop`                          | 1             |
| Release PR → `main`                              | 2             |
| Hotfix PR → `main`                               | 2             |
| Changes to auth / payments / PII handling        | 2             |
| IaC / infrastructure changes                     | [1 / 2]       |

- **Required reviewers for production merges:** [list names or GitHub teams]
- **CODEOWNERS file location:** `.github/CODEOWNERS`

## Protected Branch Settings (GitHub)

Confirm the following are enabled in GitHub → Settings → Branches:

### `main`
- [ ] Require pull request before merging
- [ ] Required approvals: 2
- [ ] Dismiss stale reviews on new commits
- [ ] Require status checks: [list CI check names]
- [ ] Require branches to be up to date
- [ ] Restrict push access to: [team/users]
- [ ] No force pushes
- [ ] No deletions

### `develop`
- [ ] Require pull request before merging
- [ ] Required approvals: 1
- [ ] Require status checks: [list CI check names]
- [ ] No force pushes
- [ ] No deletions

## Versioning Scheme

- **Format:** Semantic Versioning — `vMAJOR.MINOR.PATCH`
- **Current version:** [e.g. v0.1.0]
- **Changelog location:** `CHANGELOG.md`
- **Version bump responsibility:** [Tech Lead / Release Manager]

## CI Status Checks Required Before Merge

> List the exact GitHub Actions check names that must pass.

- [ ] `unit-tests`
- [ ] `integration-tests`
- [ ] `sast-scan`
- [ ] `dependency-scan`
- [ ] `secrets-scan`
- [ ] [Add more...]

## Project-Specific Overrides

> Only document rules that differ from @agent_docs/generic/git-workflow.md.

<!-- Example:
- We use `task/*` instead of `feature/*` for branch naming because the team uses a task-based board
- Merge strategy into develop is merge commit (not squash) because [reason]
-->

[None — or document overrides here]

## Access & Permissions

| Role                  | GitHub Access Level  | Notes                            |
|-----------------------|----------------------|----------------------------------|
| Tech Lead             | Admin                |                                  |
| Senior Developer      | Write                |                                  |
| Developer             | Write                |                                  |
| QA Engineer           | Write                |                                  |
| Client / Stakeholder  | Read                 | View-only, no commit access      |
| CI/CD Service Account | Write (via token)    | Scoped to deploy workflows only  |

- **Access review schedule:** Every 90 days `[ISO 27001: 8.3]`
- **Access review owner:** [Tech Lead name]
