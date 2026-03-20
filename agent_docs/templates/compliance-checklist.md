<!-- checklist-version: 2026-03-17b -->

# Project Compliance Checklist — [Project Name]

> Generated from the master compliance checklist template.
> Fill in the **Status** column for every row. Use the legend below.
> Items marked **[BLOCKER]** must be Compliant before any production release.

## Source File Versions
*The checklist was last synchronised with these versions of the source files.
If any source file has a `last-reviewed` date newer than the `Synced` date below,
the checklist must be updated before use.*

| Source File                        | Last Reviewed (source) | Synced to Checklist | Drift? |
|------------------------------------|------------------------|---------------------|--------|
| api-conventions.md                 | 2026-03-17             | 2026-03-17b         | —      |
| nfr-baseline.md                    | 2026-03-16             | 2026-03-16          | —      |
| security-checklist.md              | 2026-03-17             | 2026-03-17          | —      |
| deployment-standards.md            | 2026-03-17             | 2026-03-17b         | —      |
| deployment-aws.md                  | 2026-03-16             | 2026-03-16          | N/A    |
| deployment-gcp.md                  | 2026-03-16             | 2026-03-16          | N/A    |
| deployment-alicloud.md             | 2026-03-16             | 2026-03-16          | N/A    |
| deployment-onpremise.md            | 2026-03-16             | 2026-03-16          | N/A    |
| deployment-vercel-cloudflare.md    | 2026-03-16             | 2026-03-16          | N/A    |
| git-workflow.md                    | 2026-03-16             | 2026-03-16          | —      |
| uiux-standards.md                  | 2026-03-17             | 2026-03-17          | —      |
| agent-roles.md                     | 2026-03-17             | 2026-03-17b         | —      |

> **Note on platform files:** Only the platform applicable to this project needs to be checked.
> Set the others to N/A in the Drift column and mark all their checklist items as N/A.

## Project Info

| Field          | Value                        |
|----------------|------------------------------|
| Project        | [Project Name]               |
| Release        | [Version / Sprint / Tag]     |
| Cloud Platform | [AWS / GCP / Alicloud / On-Premise] |
| Reviewer       | [Name]                       |
| Review Date    | [YYYY-MM-DD]                 |
| Environment    | [ ] Staging   [ ] Production |

## Status Legend

| Symbol | Meaning                                                      |
|--------|--------------------------------------------------------------|
| ✅     | Compliant — fully meets the requirement                      |
| ⚠️     | Partially Compliant — meets requirement with minor gaps      |
| ❌     | Non-Compliant — does not meet requirement; action required   |
| N/A    | Not Applicable — requirement does not apply to this project  |

> Add a **Notes** entry for every ⚠️ and ❌ row explaining the gap and owner.

---

## Summary (fill in last)

| Section                                    | Total Items | ✅ | ⚠️ | ❌ | N/A |
|--------------------------------------------|-------------|----|----|-----|-----|
| 1. API Conventions                         |             |    |    |     |     |
| 2. NFR Baseline — Performance              |             |    |    |     |     |
| 3. NFR Baseline — Availability             |             |    |    |     |     |
| 4. NFR Baseline — Security                 |             |    |    |     |     |
| 5. NFR Baseline — Data & Privacy           |             |    |    |     |     |
| 6. NFR Baseline — Observability            |             |    |    |     |     |
| 7. Security — Auth & Authorisation         |             |    |    |     |     |
| 8. Security — Input Validation             |             |    |    |     |     |
| 9. Security — Secrets & Config             |             |    |    |     |     |
| 10. Security — Transport                   |             |    |    |     |     |
| 11. Security — CORS & Headers              |             |    |    |     |     |
| 12. Security — Dependencies                |             |    |    |     |     |
| 13. Security — Data Classification         |             |    |    |     |     |
| 14. Security — Secure SDLC                 |             |    |    |     |     |
| 15. Security — Logging & Audit             |             |    |    |     |     |
| 16. Security — OWASP Top 10                |             |    |    |     |     |
| 17. Deployment Standards                   |             |    |    |     |     |
| 18. Platform — AWS *(if applicable)*       |             |    |    |     |     |
| 19. Platform — GCP *(if applicable)*       |             |    |    |     |     |
| 20. Platform — Alicloud *(if applicable)*  |             |    |    |     |     |
| 21. Platform — On-Premise *(if applicable)*|             |    |    |     |     |
| 22. Platform — Vercel+CF *(if applicable)* |             |    |    |     |     |
| 23. Git Workflow                           |             |    |    |     |     |
| 24. UI/UX Standards                        |             |    |    |     |     |
| 25. Agent Pipeline                         |             |    |    |     |     |
| 26. Experience-Based Extras                |             |    |    |     |     |
| **TOTAL**                                  |             |    |    |     |     |

**Blocker items non-compliant:** ___ (must be 0 before production release)

**Sign-off:** _________________________ Date: ___________

---

## Section 1 — API Conventions
*Source: `agent_docs/generic/api-conventions.md`*

| #    | Item                                                                                     | Blocker | Status | Notes |
|------|------------------------------------------------------------------------------------------|---------|--------|-------|
| 1.1  | All API base paths use `/api/v1/` (or current version prefix)                            |         |        |       |
| 1.2  | Resource URLs use nouns, not verbs (e.g. `/users` not `/getUsers`)                       |         |        |       |
| 1.3  | Multi-word URL segments use kebab-case                                                   |         |        |       |
| 1.4  | Nested resources limited to max 2 levels                                                 |         |        |       |
| 1.5  | Non-CRUD actions use verb sub-resource (e.g. `POST /orders/{id}/cancel`)                 |         |        |       |
| 1.6  | GET used for retrieval only; POST for create; PUT for full replace; PATCH for partial    |         |        |       |
| 1.7  | All timestamps use ISO 8601 UTC format                                                   |         |        |       |
| 1.8  | All public IDs are strings (UUID v4); no sequential integers exposed                     |         |        |       |
| 1.9  | Currency values use integer cents (no floating point)                                    |         |        |       |
| 1.10 | Boolean fields named with `is` / `has` prefix                                           |         |        |       |
| 1.11 | Nullable fields explicitly set to `null`, never omitted                                  |         |        |       |
| 1.12 | Pagination uses `?page` and `?limit`; response includes `meta.total` and `meta.totalPages` |       |        |       |
| 1.13 | Default page limit is 20; maximum is 100                                                 |         |        |       |
| 1.14 | All errors use the standard envelope `{ error: { code, message, details } }`            | ✋      |        |       |
| 1.15 | Error `code` is SCREAMING_SNAKE_CASE and machine-readable                                |         |        |       |
| 1.16 | HTTP status codes match the correct scenarios (200/201/204/400/401/403/404/409/422/429/500) |      |        |       |
| 1.17 | API version in URL path; old versions not removed without a new version                  |         |        |       |
| 1.18 | `GET /health` endpoint exists and returns `{ status, version, uptime }`                  | ✋      |        |       |
| 1.19 | API responses do not return data above the caller's classification level                 | ✋      |        |       |
| 1.20 | Restricted data (passwords, tokens, card numbers) never returned in full                 | ✋      |        |       |
| 1.21 | Sensitive fields masked where partial display needed (e.g. `****1234`)                   |         |        |       |
| 1.22 | Audit log emitted for: auth events, sensitive data access, CRUD, privilege change, export, credential change | ✋ |  |  |
| 1.23 | Audit log includes: `audit`, `action`, `actorId`, `resourceType`, `resourceId`, `timestamp`, `ip`, `requestId` | ✋ | | |
| 1.24 | No request bodies containing passwords/tokens/PII written to logs                       | ✋      |        |       |
| 1.25 | `Authorization`, `Cookie`, `X-API-Key` headers redacted from all logs                   | ✋      |        |       |
| 1.26 | PII responses carry `Cache-Control: no-store`                                            |         |        |       |

---

## Section 2 — NFR Baseline: Performance
*Source: `agent_docs/generic/nfr-baseline.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 2.1  | API p99 response time < 500ms under normal load                   | ✋      |        |       |
| 2.2  | API p99 response time < 2s under peak load                        | ✋      |        |       |
| 2.3  | Frontend Time to Interactive < 3s on 4G mobile                    |         |        |       |
| 2.4  | Frontend Largest Contentful Paint < 2.5s                          |         |        |       |
| 2.5  | Database query p99 < 100ms                                        | ✋      |        |       |

---

## Section 3 — NFR Baseline: Availability & Reliability
*Source: `agent_docs/generic/nfr-baseline.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 3.1  | Production uptime target 99.9% documented and architecturally supported | ✋ |        |       |
| 3.2  | RTO < 1 hour documented and achievable                            | ✋      |        |       |
| 3.3  | RPO < 15 minutes documented and achievable                        | ✋      |        |       |
| 3.4  | Zero-downtime deployment in place (rolling or blue/green)         | ✋      |        |       |
| 3.5  | Database backups run at minimum every 15 minutes                  | ✋      |        |       |
| 3.6  | Backup retention minimum 30 days                                  | ✋      |        |       |
| 3.7  | DR test scheduled annually; results documented                    |         |        |       |

---

## Section 4 — NFR Baseline: Security
*Source: `agent_docs/generic/nfr-baseline.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 4.1  | OWASP Top 10 all items addressed                                  | ✋      |        |       |
| 4.2  | Auth uses OAuth 2.0 / OIDC / JWT with 15–60 min access token     | ✋      |        |       |
| 4.3  | MFA required for all admin and privileged accounts                | ✋      |        |       |
| 4.4  | Passwords hashed with bcrypt (cost ≥ 12) or Argon2               | ✋      |        |       |
| 4.5  | TLS 1.2+ enforced everywhere (HTTPS only)                         | ✋      |        |       |
| 4.6  | Encryption at rest for all DBs and storage containing sensitive data | ✋   |        |       |
| 4.7  | No critical/high CVEs in production dependencies                  | ✋      |        |       |
| 4.8  | Vulnerability patching: Critical ≤ 24h, High ≤ 7d, Medium ≤ 30d  | ✋      |        |       |
| 4.9  | SAST runs on every PR                                             | ✋      |        |       |
| 4.10 | Penetration test conducted or scheduled (annually or after major arch change) | |     |       |

---

## Section 5 — NFR Baseline: Data Classification & Privacy
*Source: `agent_docs/generic/nfr-baseline.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 5.1  | All data assets classified (Public / Internal / Confidential / Restricted) | ✋ |   |       |
| 5.2  | PII register maintained with processing purpose, retention, and legal basis | ✋ |   |       |
| 5.3  | No PII in logs (emails, tokens, passwords, IDs masked or omitted) | ✋      |        |       |
| 5.4  | Production data not used in dev or staging                        | ✋      |        |       |
| 5.5  | System supports data subject rights: access, correction, deletion |         |        |       |
| 5.6  | Data retention periods defined and automated deletion in place    |         |        |       |
| 5.7  | PDPO / GDPR / PIPL compliance documented where applicable         |         |        |       |

---

## Section 6 — NFR Baseline: Observability & Incident Response
*Source: `agent_docs/generic/nfr-baseline.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 6.1  | Logs are structured JSON with configurable log level via env var  | ✋      |        |       |
| 6.2  | `X-Request-ID` correlation ID on all requests                     | ✋      |        |       |
| 6.3  | Audit events logged: auth, sensitive data access, privilege changes, exports | ✋ |    |       |
| 6.4  | Log store is append-only and separate from application servers    | ✋      |        |       |
| 6.5  | Log retention minimum 12 months (90 days hot)                     | ✋      |        |       |
| 6.6  | NTP clock synchronisation across all services                     |         |        |       |
| 6.7  | Error tracking active (Sentry / Datadog or equivalent)            | ✋      |        |       |
| 6.8  | `/metrics` endpoint exposed (Prometheus-compatible)               |         |        |       |
| 6.9  | Alerts configured: p99 latency, error spike, auth anomalies       | ✋      |        |       |
| 6.10 | Incident response plan documented and accessible to team          | ✋      |        |       |
| 6.11 | Incident classification defined (P1–P4)                           |         |        |       |

---

## Section 7 — Security Checklist: Authentication & Authorisation
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 7.1  | Passwords hashed with bcrypt (cost ≥ 12) or Argon2               | ✋      |        |       |
| 7.2  | JWT access tokens expire in 15–60 minutes                         | ✋      |        |       |
| 7.3  | Refresh tokens rotate on use; stored securely (httpOnly cookie or DB) | ✋   |        |       |
| 7.4  | RBAC enforced server-side — no client-supplied role claims trusted | ✋      |        |       |
| 7.5  | Rate limiting on auth endpoints (login, register, password reset) |         |        |       |
| 7.6  | Account lockout or CAPTCHA after N failed attempts                |         |        |       |
| 7.7  | Password reset tokens are single-use and expire within 1 hour     |         |        |       |
| 7.8  | MFA enabled for all admin and privileged accounts                 | ✋      |        |       |
| 7.9  | Privileged access reviewed and re-approved every 90 days          |         |        |       |

---

## Section 8 — Security Checklist: Input Validation
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 8.1  | All user input validated at API boundary (zod / pydantic / Bean Validation) | ✋ |     |       |
| 8.2  | All SQL uses parameterised queries or ORM — no string concatenation | ✋    |        |       |
| 8.3  | File uploads validated: type (magic bytes), size, and content     | ✋      |        |       |
| 8.4  | Output encoded/escaped to prevent XSS                             |         |        |       |
| 8.5  | Content-Type enforced on all endpoints                            |         |        |       |

---

## Section 9 — Security Checklist: Secrets & Config
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 9.1  | No secrets, keys, or credentials in source code or git history   | ✋      |        |       |
| 9.2  | `.env` files in `.gitignore`                                      | ✋      |        |       |
| 9.3  | All production secrets stored in secret manager (not env files)  |         |        |       |
| 9.4  | `.env.example` present with placeholder values only              |         |        |       |
| 9.5  | API keys rotated if accidentally exposed                          |         |        |       |
| 9.6  | Cryptographic key rotation schedule defined and documented        |         |        |       |
| 9.7  | Encryption at rest enabled for all databases and object storage containing sensitive data | ✋ | | |

---

## Section 10 — Security Checklist: Transport Security
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 10.1 | HTTPS enforced everywhere in staging and production               | ✋      |        |       |
| 10.2 | HSTS header set (`Strict-Transport-Security: max-age=31536000`)   |         |        |       |
| 10.3 | TLS 1.2 minimum (TLS 1.3 preferred)                               |         |        |       |
| 10.4 | Certificates auto-renew (Let's Encrypt / ACM / cert-manager)     |         |        |       |

---

## Section 11 — Security Checklist: CORS & Headers
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 11.1 | CORS whitelist configured — no wildcard `*` in production         | ✋      |        |       |
| 11.2 | Security headers set: `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `CSP` | | | |
| 11.3 | Cookies have `Secure`, `HttpOnly`, and `SameSite=Strict` or `Lax` |        |        |       |

---

## Section 12 — Security Checklist: Dependencies
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 12.1 | No critical/high CVEs in production dependencies                  | ✋      |        |       |
| 12.2 | Dependency scan runs in CI on every build                         |         |        |       |
| 12.3 | Container image scanned before deploy (Trivy)                     |         |        |       |
| 12.4 | Lock files committed (`package-lock.json` / `poetry.lock` / `pom.xml`) |    |        |       |
| 12.5 | Patch timeline enforced: Critical ≤ 24h, High ≤ 7d, Medium ≤ 30d | ✋      |        |       |

---

## Section 13 — Security Checklist: Data Classification & Handling
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 13.1 | All data assets classified (Public / Internal / Confidential / Restricted) | ✋ |   |       |
| 13.2 | PII and sensitive data identified and documented in the data register | ✋  |        |       |
| 13.3 | No PII or sensitive data written to logs                          | ✋      |        |       |
| 13.4 | Personal data encrypted at rest and in transit                    | ✋      |        |       |
| 13.5 | Data retention periods defined; automated deletion in place       |         |        |       |
| 13.6 | Data processing documented for PDPO / GDPR / PIPL compliance     |         |        |       |

---

## Section 14 — Security Checklist: Secure Development & Change Management
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 14.1 | Security requirements defined before development began           |         |        |       |
| 14.2 | Threat modelling completed for features handling sensitive data   |         |        |       |
| 14.3 | OWASP Secure Coding Practices followed                            |         |        |       |
| 14.4 | All changes deployed via CI/CD pipeline — no manual production changes | ✋ |       |       |
| 14.5 | Dev, staging, and production environments strictly separated      | ✋      |        |       |
| 14.6 | Production data never used in dev or staging                      | ✋      |        |       |
| 14.7 | SAST + DAST run in pipeline before staging deploy                 | ✋      |        |       |
| 14.8 | Penetration test conducted or scheduled                           |         |        |       |

---

## Section 15 — Security Checklist: Logging, Monitoring & Audit
*Source: `agent_docs/generic/security-checklist.md`*

| #    | Item                                                              | Blocker | Status | Notes |
|------|-------------------------------------------------------------------|---------|--------|-------|
| 15.1 | Audit logs enabled for: auth events, sensitive data access, privilege changes, exports | ✋ | | |
| 15.2 | Log integrity protected — append-only store separate from application | ✋   |        |       |
| 15.3 | Log retention minimum 12 months (90 days hot)                    | ✋      |        |       |
| 15.4 | Clocks synchronised via NTP                                       |         |        |       |
| 15.5 | Alerts configured for: failed login spikes, privilege escalation, unusual data access | ✋ | | |
| 15.6 | Security events reviewed at least weekly                          |         |        |       |
| 15.7 | Audit log evidence available for ISO 27001 audit requests         | ✋      |        |       |

---

## Section 16 — Security Checklist: OWASP Top 10
*Source: `agent_docs/generic/security-checklist.md`*

| #     | Item                                                                       | Blocker | Status | Notes |
|-------|----------------------------------------------------------------------------|---------|--------|-------|
| 16.1  | A01 Broken Access Control — resource-level authorisation on every endpoint | ✋      |        |       |
| 16.2  | A02 Cryptographic Failures — no sensitive data in logs; encrypted at rest  | ✋      |        |       |
| 16.3  | A03 Injection — parameterised queries and input validation in place        | ✋      |        |       |
| 16.4  | A04 Insecure Design — threat model reviewed                                |         |        |       |
| 16.5  | A05 Security Misconfiguration — debug mode off; default credentials changed | ✋     |        |       |
| 16.6  | A06 Vulnerable Components — dependency scan passed                         | ✋      |        |       |
| 16.7  | A07 Auth Failures — auth checklist items met                               | ✋      |        |       |
| 16.8  | A08 Integrity Failures — CI/CD pipeline integrity verified                 |         |        |       |
| 16.9  | A09 Logging & Monitoring — alerts configured; no PII in logs               | ✋      |        |       |
| 16.10 | A10 SSRF — allowlist for outbound requests; no user-supplied URLs fetched directly | ✋ |   |       |

---

## Section 17 — Deployment Standards
*Source: `agent_docs/generic/deployment-standards.md`*

| #     | Item                                                                         | Blocker | Status | Notes |
|-------|------------------------------------------------------------------------------|---------|--------|-------|
| 17.1  | Three environments in place: dev, staging, production                        |         |        |       |
| 17.2  | Dev and staging use synthetic/anonymised data only                           | ✋      |        |       |
| 17.3  | Environments strictly separated — no shared credentials or network access    | ✋      |        |       |
| 17.4  | Infrastructure defined as code (IaC) — no manual console changes            | ✋      |        |       |
| 17.5  | All secrets injected at runtime via secret manager                           | ✋      |        |       |
| 17.6  | All services containerised (Docker)                                          |         |        |       |
| 17.7  | Container orchestration in use for staging and production                    |         |        |       |
| 17.8  | `GET /health` endpoint returns 200 on all deployed services                  | ✋      |        |       |
| 17.9  | Zero-downtime deployment implemented (rolling or blue/green)                 | ✋      |        |       |
| 17.10 | All deploys go through CI/CD pipeline — no manual deploys                    | ✋      |        |       |
| 17.11 | Container images run as non-root user                                        |         |        |       |
| 17.12 | Minimal base images used; base image versions pinned (no `:latest`)          |         |        |       |
| 17.13 | Images stored in private registry only                                       |         |        |       |
| 17.14 | CI/CD pipeline includes: unit tests, integration tests, SAST, dep scan, secrets scan, container scan | ✋ | | |
| 17.15 | Image tags use `{semver}-{git-sha}`                                          |         |        |       |
| 17.16 | CI/CD service accounts follow least-privilege; separate per environment      |         |        |       |
| 17.17 | Secrets stored with separate namespaces per environment                      |         |        |       |
| 17.18 | Rollback plan documented before every production deploy                      | ✋      |        |       |
| 17.19 | Rollback executable within 15 minutes                                        | ✋      |        |       |
| 17.20 | Previous image tag retained for minimum 30 days                              |         |        |       |
| 17.21 | Production changes require PR with at least 1 reviewer approval              | ✋      |        |       |
| 17.22 | `/health` confirmed returning 200 within 2 minutes of deploy                 | ✋      |        |       |
| 17.23 | Error rate monitored for 15 minutes post-deploy                              | ✋      |        |       |
| 17.24 | Deployment events logged (who, what version, when, which environment)        | ✋      |        |       |
| 17.25 | Pipeline logs redacted — no secrets, passwords, or tokens in logs            | ✋      |        |       |
| 17.26 | Pipeline run logs retained for minimum 12 months                             |         |        |       |

---

## Section 18 — Platform: AWS
*Source: `agent_docs/generic/deployment-aws.md` | Mark entire section N/A if not on AWS.*

| #     | Item                                                                                      | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------|---------|--------|-------|
| 18.1  | ECS Fargate or EKS used for compute (no bare EC2 for app workloads)                       |         |        |       |
| 18.2  | All app workloads in private subnets — no public IPs on ECS tasks                         | ✋      |        |       |
| 18.3  | ALB HTTPS-only; HTTP → HTTPS redirect configured                                          | ✋      |        |       |
| 18.4  | Security groups follow least-privilege; no `0.0.0.0/0` inbound except ALB on 443          | ✋      |        |       |
| 18.5  | VPC Flow Logs enabled                                                                     |         |        |       |
| 18.6  | AWS WAF or Network Firewall on ALB in production                                          |         |        |       |
| 18.7  | IAM roles used for ECS tasks — no long-lived access keys inside containers                | ✋      |        |       |
| 18.8  | No wildcard `*` actions in production IAM policies                                        | ✋      |        |       |
| 18.9  | MFA required for all human IAM users                                                      | ✋      |        |       |
| 18.10 | S3 public access blocked at account level                                                 | ✋      |        |       |
| 18.11 | S3 SSE-KMS encryption for sensitive data                                                  | ✋      |        |       |
| 18.12 | RDS encryption at rest enabled; TLS required for connections                               | ✋      |        |       |
| 18.13 | ECR scan on push enabled; critical CVEs blocked from deploying                            | ✋      |        |       |
| 18.14 | GuardDuty enabled; alerts routed to security team                                         |         |        |       |
| 18.15 | CloudTrail multi-region trail with log file integrity validation                          | ✋      |        |       |
| 18.16 | AWS Config rules enabled for drift detection                                              |         |        |       |
| 18.17 | OIDC-based GitHub Actions auth — no long-lived AWS access keys in CI secrets              | ✋      |        |       |
| 18.18 | All secrets in AWS Secrets Manager under `/env/service/secret-name` path                 | ✋      |        |       |
| 18.19 | RDS automated backups: 30-day retention in production                                     | ✋      |        |       |
| 18.20 | Cross-region backup copy in place for production databases                                | ✋      |        |       |

---

## Section 19 — Platform: GCP
*Source: `agent_docs/generic/deployment-gcp.md` | Mark entire section N/A if not on GCP.*

| #     | Item                                                                                      | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------|---------|--------|-------|
| 19.1  | Cloud Run ingress set to `internal-and-cloud-load-balancing` only                        | ✋      |        |       |
| 19.2  | Firewall rules: deny-all default with explicit allow only                                 | ✋      |        |       |
| 19.3  | VPC Service Controls perimeter around sensitive projects                                  |         |        |       |
| 19.4  | No public IP on Cloud SQL instances (Private Service Connect used)                        | ✋      |        |       |
| 19.5  | Cloud Armor WAF on HTTPS Load Balancer                                                    |         |        |       |
| 19.6  | Workload Identity used — no service account key files                                    | ✋      |        |       |
| 19.7  | Service account key creation disabled org-wide via Organization Policy                   |         |        |       |
| 19.8  | GCS uniform bucket-level access; public access prevention enabled                        | ✋      |        |       |
| 19.9  | CMEK (Cloud KMS) for sensitive GCS buckets                                                | ✋      |        |       |
| 19.10 | Artifact Registry vulnerability scanning on push                                         | ✋      |        |       |
| 19.11 | Security Command Center enabled at Premium; findings routed to security team              |         |        |       |
| 19.12 | Data Access audit logs enabled for all services handling sensitive data                   | ✋      |        |       |
| 19.13 | Workload Identity Federation for GitHub Actions — no long-lived SA keys in CI            | ✋      |        |       |
| 19.14 | All secrets in GCP Secret Manager under `env-service-secret-name` convention             | ✋      |        |       |
| 19.15 | Cloud SQL PITR enabled for production; 30-day backup retention                            | ✋      |        |       |

---

## Section 20 — Platform: Alibaba Cloud
*Source: `agent_docs/generic/deployment-alicloud.md` | Mark entire section N/A if not on Alicloud.*

| #     | Item                                                                                      | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------|---------|--------|-------|
| 20.1  | All workloads in private VSwitches — no public IPs on ACK/SAE pods                       | ✋      |        |       |
| 20.2  | Security Groups: whitelist only; no `0.0.0.0/0` inbound except ALB on 443                | ✋      |        |       |
| 20.3  | VPC Flow Logs shipped to SLS                                                              |         |        |       |
| 20.4  | WAF on ALB in production                                                                  |         |        |       |
| 20.5  | ICP Licence obtained before going live (Mainland China)                                   | ✋      |        |       |
| 20.6  | PIPL compliance documented; personal data of Chinese citizens stored in China             | ✋      |        |       |
| 20.7  | MLPS level assessed and required controls implemented                                     | ✋      |        |       |
| 20.8  | RAM roles used — no long-lived AccessKey pairs inside containers                          | ✋      |        |       |
| 20.9  | No wildcard `*` actions in production RAM policies                                        | ✋      |        |       |
| 20.10 | OSS public access disabled; RAM/bucket policies only                                      | ✋      |        |       |
| 20.11 | OSS SSE-KMS for sensitive data                                                            | ✋      |        |       |
| 20.12 | RDS encryption at rest; SSL required for connections                                      | ✋      |        |       |
| 20.13 | ACR vulnerability scanning on push; critical CVEs blocked                                 | ✋      |        |       |
| 20.14 | ActionTrail multi-region with integrity check to OSS                                      | ✋      |        |       |
| 20.15 | RAM OIDC used for GitHub Actions — no long-lived AccessKey pairs in CI                   | ✋      |        |       |
| 20.16 | All secrets in Alibaba Cloud Secrets Manager under `env/service/secret-name`             | ✋      |        |       |

---

## Section 21 — Platform: On-Premise
*Source: `agent_docs/generic/deployment-onpremise.md` | Mark entire section N/A if not on-premise.*

| #     | Item                                                                                      | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------|---------|--------|-------|
| 21.1  | Kubernetes RBAC enabled; no cluster-admin bindings except break-glass                    | ✋      |        |       |
| 21.2  | Pod Security Standards: `restricted` profile enforced in production namespaces           | ✋      |        |       |
| 21.3  | Network Policies: default deny; explicit allow per service                                | ✋      |        |       |
| 21.4  | etcd secrets encrypted at rest                                                            | ✋      |        |       |
| 21.5  | Node-to-node communication encrypted (WireGuard or CNI equivalent)                       | ✋      |        |       |
| 21.6  | Kubernetes API server not exposed outside management network                              | ✋      |        |       |
| 21.7  | SSH: key-based auth only; root login disabled; no shared SSH keys                        | ✋      |        |       |
| 21.8  | Bastion host required for any SSH access — no direct SSH to production nodes             | ✋      |        |       |
| 21.9  | CIS Benchmark Level 1 applied to all server OS builds                                    |         |        |       |
| 21.10 | HashiCorp Vault deployed in HA mode for secrets management                               | ✋      |        |       |
| 21.11 | Vault root token generated once and immediately revoked after setup                      | ✋      |        |       |
| 21.12 | Harbor used for container registry; vulnerability scanning on push                       | ✋      |        |       |
| 21.13 | Physical access to servers restricted and logged                                         | ✋      |        |       |
| 21.14 | PostgreSQL: pgBackRest WAL archiving + daily full backup; 30-day retention in production | ✋      |        |       |
| 21.15 | Prometheus + Grafana + Loki observability stack active                                   |         |        |       |
| 21.16 | Wazuh HIDS or equivalent intrusion detection on all production nodes                     |         |        |       |

---

## Section 22 — Platform: Vercel + Cloudflare
*Source: `agent_docs/generic/deployment-vercel-cloudflare.md` | Mark entire section N/A if not on this platform.*

| #     | Item                                                                                       | Blocker | Status | Notes |
|-------|--------------------------------------------------------------------------------------------|---------|--------|-------|
| 22.1  | All DNS records proxied through Cloudflare — origin IPs not exposed                       | ✋      |        |       |
| 22.2  | Cloudflare SSL mode set to Full (strict)                                                   | ✋      |        |       |
| 22.3  | HTTP → HTTPS redirect enforced at Cloudflare level                                         | ✋      |        |       |
| 22.4  | Minimum TLS version 1.2 enforced via Cloudflare                                            | ✋      |        |       |
| 22.5  | HSTS enabled (`max-age=31536000; includeSubDomains`)                                       | ✋      |        |       |
| 22.6  | Cloudflare WAF: OWASP Core Ruleset + managed rules enabled in production                   | ✋      |        |       |
| 22.7  | Bot Management or Bot Fight Mode enabled in production                                     |         |        |       |
| 22.8  | Rate limiting rules on all API endpoints                                                   | ✋      |        |       |
| 22.9  | Workers CORS `allowed_origins` explicitly set — no wildcard `*` in production              | ✋      |        |       |
| 22.10 | Cloudflare API tokens scoped (not Global API Key); minimum permissions                     | ✋      |        |       |
| 22.11 | Workers secrets set via `wrangler secret put` — not in `wrangler.toml`                    | ✋      |        |       |
| 22.12 | Vercel Env Vars marked Sensitive for all secret values                                     | ✋      |        |       |
| 22.13 | R2 buckets not publicly accessible (unless serving public assets intentionally)            | ✋      |        |       |
| 22.14 | Staging and preview deployments protected with Cloudflare Access or Vercel Auth            | ✋      |        |       |
| 22.15 | Cloudflare Logpush configured; logs shipped to external sink for 12-month retention        | ✋      |        |       |
| 22.16 | Vercel Log Drains configured and shipping to external log sink                             |         |        |       |
| 22.17 | Sentry installed in both Workers (`@sentry/cloudflare`) and frontend                       | ✋      |        |       |
| 22.18 | Alerts on: Worker error rate > 1%, p99 latency > 500ms, WAF block spike                   | ✋      |        |       |
| 22.19 | `vercel rollback` and `wrangler rollback` tested; rollback time < 5 minutes                | ✋      |        |       |
| 22.20 | Dependency scanning (Snyk) runs in CI for both Workers and frontend code                   | ✋      |        |       |

---

## Section 23 — Git Workflow
*Source: `agent_docs/generic/git-workflow.md`*



| #     | Item                                                                         | Blocker | Status | Notes |
|-------|------------------------------------------------------------------------------|---------|--------|-------|
| 18.1  | GitFlow branching model in use: `main`, `develop`, `feature/*`, `fix/*`, `release/*`, `hotfix/*` | | |  |
| 18.2  | `main` and `develop` are protected — no direct pushes                        | ✋      |        |       |
| 18.3  | Branch naming follows convention (type/TICKET-NNN-description)               |         |        |       |
| 18.4  | Short-lived branches deleted within 3 days of merge                          |         |        |       |
| 18.5  | Commit messages follow Conventional Commits format                           |         |        |       |
| 18.6  | Commit subject lines ≤ 72 characters                                         |         |        |       |
| 18.7  | PRs require minimum 1 reviewer approval before merge                         | ✋      |        |       |
| 18.8  | Author cannot self-approve PRs                                               | ✋      |        |       |
| 18.9  | All CI checks pass before merge                                              | ✋      |        |       |
| 18.10 | Auth / payments / PII PRs require 2 approvals                                | ✋      |        |       |
| 18.11 | Squash merge into `develop`; merge commit into `main`                        |         |        |       |
| 18.12 | Production releases tagged with semantic version (`vMAJOR.MINOR.PATCH`)      |         |        |       |
| 18.13 | Tags are annotated and only on `main`                                        |         |        |       |
| 18.14 | Repository access reviewed every 90 days                                     |         |        |       |
| 18.15 | Separate CI/CD service account used (not personal tokens)                    |         |        |       |
| 18.16 | Git access logs retained for minimum 12 months                               |         |        |       |

---

## Section 24 — UI/UX Standards
*Source: `agent_docs/generic/uiux-standards.md` | Mark entire section N/A if no frontend.*

| #     | Item                                                                                       | Blocker | Status | Notes |
|-------|--------------------------------------------------------------------------------------------|---------|--------|-------|
| 24.1  | Colour contrast for body text ≥ 4.5:1 (WCAG 2.1 AA)                                       | ✋      |        |       |
| 24.2  | Colour contrast for large text / UI components ≥ 3:1                                       |         |        |       |
| 24.3  | All interactive elements reachable and operable via keyboard                               | ✋      |        |       |
| 24.4  | Visible focus indicator on all focusable elements (no bare `outline: none`)                | ✋      |        |       |
| 24.5  | All non-text content has a text alternative (`alt`, `aria-label`, `aria-describedby`)     | ✋      |        |       |
| 24.6  | Every form input has an associated visible `<label>` (not placeholder-only)               | ✋      |        |       |
| 24.7  | Errors identified in text, not colour alone                                                | ✋      |        |       |
| 24.8  | `prefers-reduced-motion` respected — animations disabled or reduced                       |         |        |       |
| 24.9  | Touch targets minimum 44×44px                                                              |         |        |       |
| 24.10 | `lang` attribute set correctly on `<html>`                                                 |         |        |       |
| 24.11 | Mobile-first responsive design; tested at all defined breakpoints                          | ✋      |        |       |
| 24.12 | Loading, error, and empty states designed and implemented for all data-dependent views     | ✋      |        |       |
| 24.13 | Restricted / Confidential data masked in UI per data classification rules                  | ✋      |        |       |
| 24.14 | Sensitive fields (passwords, tokens) never rendered in plaintext in the DOM                | ✋      |        |       |
| 24.15 | Auto-fill disabled on sensitive fields (`autocomplete="off"` or `"new-password"`)         |         |        |       |
| 24.16 | Session timeout warning shown to user before auto-logout                                   |         |        |       |
| 24.17 | Design tokens used throughout — no hardcoded colour / spacing / typography values         |         |        |       |
| 24.18 | All user-facing strings externalised for i18n (if multi-language required)                |         |        |       |
| 24.19 | Password fields have show/hide toggle                                                      |         |        |       |
| 24.20 | Design review checklist completed before development handoff                               |         |        |       |
| 24.21 | Input field text colour and background colour explicitly set as a pair — never relying on CSS inheritance for either independently | ✋ | | |
| 24.22 | Input text contrast ratio ≥ 4.5:1 against input background in all states (default, focus, disabled, error) | ✋ | | |
| 24.23 | Input placeholder text contrast ratio ≥ 3:1 against input background                      | ✋      |        |       |
| 24.24 | Input field colour contrast verified in all theme variants (light, dark, high-contrast if applicable) | ✋ | | |

---

## Section 25 — Agent Pipeline
*Source: `agent_docs/generic/agent-roles.md` | Mark entire section N/A if agent pipeline not used.*

| #     | Item                                                                                       | Blocker | Status | Notes |
|-------|--------------------------------------------------------------------------------------------|---------|--------|-------|
| 25.1  | `agent_docs/project/pipeline.md` completed with active agents and correct paths           |         |        |       |
| 25.2  | `requirements-analyst` artifact exists in `artifacts/requirements/`                       |         |        |       |
| 25.3  | `solution-architect` artifact exists in `artifacts/architecture/`                         |         |        |       |
| 25.4  | Developer implementation notes exist in `artifacts/development/`                          |         |        |       |
| 25.5  | `code-reviewer` artifact exists in `artifacts/code-review/`                               | ✋      |        |       |
| 25.6  | Code reviewer was a different agent instance from the developer                           | ✋      |        |       |
| 25.7  | `tester` artifact exists in `artifacts/test/`                                             | ✋      |        |       |
| 25.8  | Tester was a different agent instance from the developer                                  | ✋      |        |       |
| 25.9  | `security-auditor` artifact exists in `artifacts/security/`                               | ✋      |        |       |
| 25.10 | Security auditor was a different agent instance from the developer and code reviewer      | ✋      |        |       |
| 25.11 | All code-reviewer Critical findings resolved before this compliance check                 | ✋      |        |       |
| 25.12 | All security-auditor Critical [BLOCKER] findings resolved before this compliance check    | ✋      |        |       |
| 25.13 | Pipeline Status table in `pipeline.md` updated with latest run dates and artifact paths   |         |        |       |

---

## Section 27 — Platform Runtime Compatibility [ALL ITEMS ARE BLOCKERS]
*Source: `agent_docs/generic/deployment-{platform}.md` — Runtime Constraints section, `agent_docs/project/architecture.md` — Platform Runtime Compatibility Matrix.*
*Every item is a BLOCKER. Discovering runtime incompatibilities at deployment time requires source code rewrites. These must be caught at the architecture stage.*

| #     | Item                                                                                                              | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------------------------------|---------|--------|-------|
| 27.1  | Platform Runtime Compatibility Matrix completed and signed off in `architecture.md` before development started    | ✅ YES  |        |       |
| 27.2  | Every planned npm library verified as compatible with the target runtime (Cloudflare Workers / Edge / Lambda)     | ✅ YES  |        |       |
| 27.3  | No packages with native addons (N-API) in the production dependency tree                                          | ✅ YES  |        |       |
| 27.4  | Password hashing uses a runtime-compatible library (e.g. `bcryptjs` not `bcrypt` for Workers)                    | ✅ YES  |        |       |
| 27.5  | Crypto operations use the correct API for the runtime (e.g. Web Crypto API for Workers, not Node's `crypto`)     | ✅ YES  |        |       |
| 27.6  | Database connections use a runtime-compatible driver (serverless / REST-based for Workers/Edge)                   | ✅ YES  |        |       |
| 27.7  | No direct file system access (`fs`) — file handling uses object storage or platform-native equivalents            | ✅ YES  |        |       |
| 27.8  | Environment variables accessed via the correct mechanism for the runtime (e.g. Worker `env`, not `process.env`)   | ✅ YES  |        |       |
| 27.9  | Worker / Edge function bundle size verified within platform limits (e.g. 1MB compressed for Cloudflare Workers)  | ✅ YES  |        |       |
| 27.10 | All runtime constraints documented in `architecture.md` under "Platform Runtime Constraints"                      | ✅ YES  |        |       |
| 27.11 | Any incompatibility discovered during development was escalated to architect and resolved before proceeding        | ✅ YES  |        |       |

---

## Section 28 — API Specification Compliance [ALL ITEMS ARE BLOCKERS]
*Source: `agent_docs/generic/api-conventions.md` — API-First Design section.*
*Every item in this section is a BLOCKER. No production release is permitted if any item is Non-Compliant.*
*The `api-spec.yaml` (OpenAPI 3.1) is the single source of truth. Code must follow the spec — never the reverse.*
*If the spec needs to change, a formal change request must be raised and approved by the project owner BEFORE any code or spec is modified.*

| #     | Item                                                                                                              | Blocker | Status | Notes |
|-------|-------------------------------------------------------------------------------------------------------------------|---------|--------|-------|
| 27.1  | `api-spec.yaml` (OpenAPI 3.1) exists in `agent_docs/project/specs/`                                              | ✋      |        |       |
| 27.2  | `api-spec.yaml` was written and **approved before any implementation began**                                      | ✋      |        |       |
| 27.3  | `api-spec.yaml` approval is recorded (frontend lead + backend lead sign-off in architecture artifact)             | ✋      |        |       |
| 27.4  | All API endpoint paths in code match `api-spec.yaml` exactly — no undocumented endpoints in production           | ✋      |        |       |
| 27.5  | All request body schemas in code match `api-spec.yaml` — field names, types, and required fields                 | ✋      |        |       |
| 27.6  | All response schemas in code match `api-spec.yaml` — field names, types, and nullable fields                     | ✋      |        |       |
| 27.7  | All enum values in code use exactly the values defined in `api-spec.yaml` — `lowercase_snake_case`                | ✋      |        |       |
| 27.8  | Frontend API client is **generated** from `api-spec.yaml` via `@hey-api/openapi-ts` — typed fetch functions keyed by `operationId` exist for every endpoint; no hand-written types or service functions | ✋      |        |       |
| 27.9  | Backend DTOs / validators are **generated from or validated against** `api-spec.yaml`                             | ✋      |        |       |
| 27.10 | Error response shape matches the company standard envelope in `api-spec.yaml` on all endpoints                    | ✋      |        |       |
| 27.11 | HTTP status codes used in code match those declared in `api-spec.yaml` for each endpoint                          | ✋      |        |       |
| 27.12 | Pagination envelope (`data` + `meta`) matches `api-spec.yaml` on all list endpoints                               | ✋      |        |       |
| 27.13 | No API changes were made directly to code without first updating `api-spec.yaml` and obtaining approval           | ✋      |        |       |
| 27.14 | All API spec change requests are recorded in `artifacts/development/api-spec-change-requests-*.md`                | ✋      |        |       |
| 27.15 | Every recorded change request has explicit project owner approval before the change was implemented               | ✋      |        |       |
| 27.16 | `api-spec.yaml` version matches the implementation version being released                                         | ✋      |        |       |
| 27.17 | Every frontend service layer function maps to an `operationId` declared in `api-spec.yaml` — no calls to undeclared paths | ✋ |        |       |
| 27.18 | No manual `fetch()` / `axios` calls to API endpoints exist in the frontend service layer — all calls go through the generated client | ✋ |        |       |
| 27.19 | Query parameter names used in frontend service calls match exactly those declared in `api-spec.yaml` (e.g. `q` vs `query`, `search` vs `q`) | ✋ |        |       |
| 27.20 | `api-spec.yaml` was linted with Spectral or Vacuum in CI — no lint errors in the released version                | ✋      |        |       |

---

## Section 26 — Experience-Based Extra Checks
*Items added from past project learnings and post-mortems — not derived from the standard md files.*
*New items should be added here whenever a post-mortem identifies a gap not covered by existing sections.*

| #     | Item                                                                                          | Blocker | Status | Notes |
|-------|-----------------------------------------------------------------------------------------------|---------|--------|-------|
| 26.1  | All required env vars verified **live** in target environment before deployment cutover       | ✋      |        |       |
| 26.2  | Cross-service env vars (CORS origins, API base URLs) explicitly verified in target environment | ✋     |        |       |
| 26.3  | API base URL includes correct path prefix (e.g. `/api/v1`) — verified by making a real call  | ✋      |        |       |
| 26.4  | CORS verified with real browser OPTIONS preflight from deployed frontend origin in staging    | ✋      |        |       |
| 26.5  | `Access-Control-Allow-Origin` response header confirmed present and correct                   | ✋      |        |       |
| 26.6  | Frontend service layer cross-checked against `api-spec.yaml` — each service function verified to call the correct path as declared (not a similar but different endpoint, e.g. `/jobs?q=` vs `/search`) | ✋ |        |       |
| 26.6  | Cross-service smoke test passed: full frontend → API → database round trip                   | ✋      |        |       |
| 26.7  | Auth flow smoke test passed end-to-end on deployed environment                               | ✋      |        |       |
| 19.1  | No `TODO` / `FIXME` / `HACK` comments remaining in production code                           |         |        |       |
| 19.2  | No debug `console.log` / `print` / `logger.debug` statements left in production code         |         |        |       |
| 19.3  | No hardcoded URLs, IPs, port numbers, or IDs — all moved to config/env                        | ✋      |        |       |
| 19.4  | All environment variables documented in `.env.example` with descriptions                     |         |        |       |
| 19.5  | OpenAPI / Swagger spec present and up-to-date with actual implementation                      |         |        |       |
| 19.6  | All database queries reviewed for N+1 problems                                               |         |        |       |
| 19.7  | Indexes in place for all foreign keys and common query filter/sort columns                   | ✋      |        |       |
| 19.8  | Long-running operations use async jobs (not blocking HTTP request threads)                   |         |        |       |
| 19.9  | File uploads streamed to object storage — never written to local disk                         | ✋      |        |       |
| 19.10 | API response times load-tested (not just unit-tested); results documented                    |         |        |       |
| 19.11 | Error messages shown to end users are human-friendly — no stack traces exposed               | ✋      |        |       |
| 19.12 | All third-party library licences reviewed and approved                                        |         |        |       |
| 19.13 | Feature flags / toggles cleaned up — no dead code from old flags in production               |         |        |       |
| 19.14 | Database schema migration rollback tested (down migration works)                             | ✋      |        |       |
| 19.15 | Ops runbook exists for common incidents (service down, DB failover, high error rate)         | ✋      |        |       |
| 19.16 | Mobile and tablet responsiveness tested for all major user-facing screens                    |         |        |       |
| 19.17 | Accessibility spot-check done (keyboard nav, screen reader, colour contrast)                  |         |        |       |
| 19.18 | Email / notification content reviewed — no PII in email subjects; unsubscribe mechanism in place |    |        |       |
| 19.19 | Rate limiting in place on all public-facing endpoints (not just auth)                         |         |        |       |
| 19.20 | Background job failures are logged, alerted, and have a dead-letter or retry mechanism       |         |        |       |
| 19.21 | All scheduled jobs (crons) have idempotent logic — safe to run twice                         |         |        |       |
| 19.22 | Session invalidation works correctly on logout and password change                           | ✋      |        |       |
| 19.23 | Pagination tested with large datasets — no full table scans on page requests                 |         |        |       |
| 19.24 | All external API integrations have timeout and retry logic with exponential back-off          |         |        |       |
| 19.25 | Smoke test suite covers at minimum: login, core CRUD flow, health check                      | ✋      |        |       |
| 26.12 | Input field text is legible against input background — text/background colour pair explicitly set in CSS, not relying on inheritance | ✋ | | |
| 26.13 | Input contrast verified manually in browser across light and dark modes before release       | ✋      |        |       |

---

## Action Items

> List all ⚠️ and ❌ items that require follow-up before release.

| # | Section | Item Ref | Issue Description | Owner | Target Date | Resolved |
|---|---------|----------|-------------------|-------|-------------|----------|
|   |         |          |                   |       |             | [ ]      |
|   |         |          |                   |       |             | [ ]      |

---

*This checklist was generated from `agent_docs/templates/compliance-checklist.md`.*
*Report stored at: `artifacts/compliance/compliance-[TIMESTAMP].md`*
