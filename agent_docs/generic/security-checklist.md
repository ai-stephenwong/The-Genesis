<!-- last-reviewed: 2026-03-22 | reviewed-by: The Genesis (tribute omnichat-v4 R2) | next-review: 2026-09-22 -->

# Security Checklist (Company Standard)

> Run through this checklist before every staging and production release.
> Items marked [BLOCKER] must pass before deploy.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.
> This checklist supports our ISO 27001 certification — deviations must be logged as exceptions in the ISMS risk register.

## Authentication & Authorisation
`ISO 27001: 8.2, 8.3, 8.5`

- [ ] [BLOCKER] Passwords hashed with bcrypt (cost ≥ 12) or Argon2 — never MD5/SHA1/plain `[8.5]`
- [ ] [BLOCKER] JWT access tokens expire in 15–60 minutes `[8.5]`
- [ ] [BLOCKER] Refresh tokens rotate on use and are stored securely (httpOnly cookie or DB) `[8.5]`
- [ ] [BLOCKER] RBAC enforced server-side — no client-supplied role claims trusted `[8.2, 8.3]`
- [ ] Rate limiting on all auth endpoints (login, register, password reset) `[8.5]`
- [ ] Account lockout or CAPTCHA after N failed attempts `[8.5]`
- [ ] Password reset tokens are single-use and expire in ≤ 1 hour `[8.5]`
- [ ] Multi-factor authentication (MFA) enabled for all admin and privileged accounts `[8.2]`
- [ ] Privileged access reviewed and re-approved every 90 days `[8.2]`

## Input Validation
`ISO 27001: 8.26, 8.28`

- [ ] [BLOCKER] All user input validated at the API boundary (zod / pydantic / Bean Validation) `[8.26]`
- [ ] [BLOCKER] All SQL uses parameterised queries or ORM — no string concatenation `[8.28]`
- [ ] [BLOCKER] File uploads validated: type (magic bytes), size, and content `[8.26]`
- [ ] Output encoded/escaped to prevent XSS `[8.28]`
- [ ] Content-Type enforced on all endpoints `[8.26]`

## Secrets & Config
`ISO 27001: 8.24, 5.17`

- [ ] [BLOCKER] No secrets, keys, or credentials in source code or git history `[8.24, 5.17]`
- [ ] [BLOCKER] `.env` files in `.gitignore` `[5.17]`
- [ ] All production secrets in secret manager (not env files) `[8.24]`
- [ ] `.env.example` present with placeholder values only `[5.17]`
- [ ] API keys rotated if accidentally exposed `[8.24]`
- [ ] Cryptographic key rotation schedule defined and documented `[8.24]`
- [ ] Encryption at rest enabled for all databases and object storage containing personal or sensitive data `[8.24]`

## Transport Security
`ISO 27001: 8.20, 8.24`

- [ ] [BLOCKER] HTTPS enforced everywhere in staging and production `[8.20]`
- [ ] HSTS header set (`Strict-Transport-Security: max-age=31536000`) `[8.20]`
- [ ] TLS 1.2 minimum (TLS 1.3 preferred) `[8.24]`
- [ ] Certificates auto-renew (Let's Encrypt / ACM) `[8.24]`

## CORS & Headers
`ISO 27001: 8.20, 8.26`

- [ ] [BLOCKER] CORS whitelist — no wildcard `*` in production `[8.20]`
- [ ] [BLOCKER] CORS verified with a **real browser OPTIONS preflight request** from the deployed frontend origin in staging — config inspection alone is not sufficient
- [ ] [BLOCKER] `Access-Control-Allow-Origin` response header confirmed present and correct in staging before production deploy
- [ ] CORS origin env var (e.g. `FRONTEND_URL`) confirmed set in the target environment's secret manager / platform config — not just in `.env.example`
- [ ] [BLOCKER] CSP directive domain values verified against the documented API base URL, media CDN origin, and font provider domains for the target deployment environment — a production API domain appearing in CSP `connect-src` in a staging config (or vice versa) is an A05 (Security Misconfiguration) failure `[8.9, 8.26]`
- [ ] Security headers set: `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `CSP` `[8.26]`
- [ ] Cookies: `Secure`, `HttpOnly`, `SameSite=Strict` or `Lax` `[8.26]`

## Dependencies & Vulnerability Management
`ISO 27001: 8.8`

- [ ] [BLOCKER] No critical/high CVEs in production dependencies (Snyk / Dependabot / OWASP DC) `[8.8]`
- [ ] Dependency scan runs in CI on every build `[8.8]`
- [ ] Container image scanned before deploy (Trivy) `[8.8]`
- [ ] Lock files committed (`package-lock.json` / `poetry.lock` / `pom.xml`) `[8.8]`
- [ ] Patch timeline enforced: Critical ≤ 24h, High ≤ 7 days, Medium ≤ 30 days `[8.8]`

## Data Classification & Handling
`ISO 27001: 5.12, 5.13, 8.10, 8.11`

- [ ] [BLOCKER] All data assets classified (Public / Internal / Confidential / Restricted) `[5.12]`
- [ ] [BLOCKER] PII and sensitive data identified and documented in the data register `[5.12]`
- [ ] No PII or sensitive data written to logs (mask or omit emails, tokens, passwords) `[8.11]`
- [ ] Personal data encrypted at rest and in transit `[8.24]`
- [ ] Data retention periods defined per data class; automated deletion in place `[8.10]`
- [ ] Data processing documented to support PDPO / GDPR compliance where applicable `[5.12]`

## Secure Development & Change Management
`ISO 27001: 8.25, 8.27, 8.29, 8.32`

- [ ] Security requirements defined before development begins `[8.25]`
- [ ] Threat modelling completed for new features handling sensitive data `[8.25]`
- [ ] Secure coding guidelines followed (OWASP Secure Coding Practices) `[8.28]`
- [ ] All changes deployed via CI/CD pipeline — no manual production changes `[8.32]`
- [ ] Dev, staging, and production environments strictly separated `[8.31]`
- [ ] Production data never used in dev or staging environments `[8.33]`
- [ ] Security testing (SAST + DAST) run in the pipeline before staging deploy `[8.29]`
- [ ] Penetration test conducted at least annually or after major architecture changes `[8.29]`

## Logging, Monitoring & Audit
`ISO 27001: 8.15, 8.16, 5.28`

- [ ] [BLOCKER] Audit logs enabled for: authentication events, access to sensitive data, privilege changes, data exports `[8.15]`
- [ ] Log integrity protected — logs written to a separate, append-only store `[8.15]`
- [ ] Log retention: minimum 12 months (90 days hot / remainder cold) `[8.15]`
- [ ] Clocks synchronised via NTP across all services (required for log correlation) `[8.17]`
- [ ] Alerts configured for: failed login spikes, privilege escalation, unusual data access volumes `[8.16]`
- [ ] Security events reviewed at least weekly by the responsible team `[8.16]`
- [ ] Audit log evidence preserved and available for ISO 27001 audit requests `[5.28]`

## Incident Management
`ISO 27001: 5.24, 5.25, 5.26, 5.27`

- [ ] Incident response plan documented and accessible to the team `[5.24]`
- [ ] Security incidents reported to the ISMS team within 1 hour of detection `[5.25]`
- [ ] Incident classification defined: P1 (Critical) / P2 (High) / P3 (Medium) / P4 (Low) `[5.25]`
- [ ] Post-incident review (PIR) completed within 5 business days of resolution `[5.27]`
- [ ] Lessons learned fed back into the risk register and this checklist `[5.27]`

## Supplier & Third-Party Security
`ISO 27001: 5.19, 5.20, 5.21`

- [ ] All third-party integrations reviewed and approved before use `[5.19]`
- [ ] Data processing agreements (DPAs) in place for any supplier handling personal data `[5.19]`
- [ ] Third-party access limited to least privilege; reviewed quarterly `[5.20]`
- [ ] Open source libraries reviewed for licence compliance and known vulnerabilities `[5.21]`

## Business Continuity
`ISO 27001: 5.29, 5.30`

- [ ] Backup strategy documented: frequency, retention, and restoration tested `[5.29]`
- [ ] Disaster recovery runbook in place and tested at least annually `[5.30]`
- [ ] RTO and RPO targets confirmed achievable based on last DR test `[5.30]`

## OWASP Top 10 Checklist
`ISO 27001: 8.26, 8.28`

- [ ] A01 Broken Access Control — resource-level authorisation on every endpoint `[8.3]`
- [ ] A02 Cryptographic Failures — no sensitive data in logs, encrypted at rest `[8.24]`
- [ ] A03 Injection — parameterised queries, input validation ✓ `[8.28]`
- [ ] A04 Insecure Design — threat model reviewed `[8.25]`
- [ ] A05 Security Misconfiguration — debug mode off, default credentials changed `[8.9]`
- [ ] A06 Vulnerable Components — dependency scan ✓ `[8.8]`
- [ ] A07 Auth Failures — auth checklist above ✓ `[8.5]`
- [ ] A08 Integrity Failures — verify integrity of CI/CD pipeline `[8.32]`
- [ ] A09 Logging & Monitoring — alerts configured, no PII in logs `[8.15, 8.16]`
- [ ] A10 SSRF — allowlist for outbound requests, no user-supplied URLs fetched directly `[8.23]`

## Pre-Production Sign-off
`ISO 27001: 8.29`

- [ ] SAST scan passed (SonarQube / CodeQL)
- [ ] Dependency vulnerability scan passed
- [ ] Container image scan passed
- [ ] Secrets scan passed (GitLeaks / GitHub secret scanning)
- [ ] Data classification review completed
- [ ] Audit logging verified in staging
- [ ] Security checklist reviewed and signed off by lead developer
- [ ] Any exceptions documented in the ISMS risk register with owner and review date
