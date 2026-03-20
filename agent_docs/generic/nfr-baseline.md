<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# Non-Functional Requirements Baseline (Company Standard)

> These are the minimum accepted targets for all production systems.
> Project-specific NFRs in `agent_docs/project/specs/requirements.md` may raise (never lower) these baselines.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.
> Compliance with these baselines is required to maintain our ISO 27001 certification.

## Performance

| Metric                               | Target                      |
|--------------------------------------|-----------------------------|
| API p99 response time (normal load)  | < 500ms                     |
| API p99 response time (peak load)    | < 2s                        |
| Frontend Time to Interactive         | < 3s on 4G mobile           |
| Frontend Largest Contentful Paint    | < 2.5s                      |
| Database query time (p99)            | < 100ms                     |

## Availability & Reliability
`ISO 27001: 5.29, 5.30`

| Metric                          | Target                                          |
|---------------------------------|-------------------------------------------------|
| Production uptime               | 99.9% (≤ 8.7 hours downtime/year)               |
| Staging uptime                  | 99% (business hours)                            |
| RTO (Recovery Time Objective)   | < 1 hour                                        |
| RPO (Recovery Point Objective)  | < 15 minutes                                    |
| Zero-downtime deploy            | Required for production (rolling or blue/green) |
| Backup frequency                | ≥ every 15 minutes for databases                |
| Backup retention                | 30 days minimum                                 |
| DR test frequency               | At least annually                               |

## Security
`ISO 27001: 8.5, 8.8, 8.24, 8.25, 8.26, 8.29`

| Requirement              | Standard                                                 | ISO 27001    |
|--------------------------|----------------------------------------------------------|--------------|
| OWASP Top 10             | All items addressed before go-live                       | 8.26, 8.28   |
| Authentication           | OAuth 2.0 / OIDC / JWT (15–60 min access token)         | 8.5          |
| MFA                      | Required for all admin and privileged accounts           | 8.2          |
| Password hashing         | bcrypt (cost ≥ 12) or Argon2                             | 8.5          |
| Transport security       | TLS 1.2+ only (HTTPS everywhere)                         | 8.20, 8.24   |
| Encryption at rest       | All DBs and storage containing personal/sensitive data   | 8.24         |
| Dependency scan          | No critical/high CVEs in production                      | 8.8          |
| Vulnerability patching   | Critical ≤ 24h, High ≤ 7 days, Medium ≤ 30 days         | 8.8          |
| SAST                     | Run on every PR                                          | 8.29         |
| Penetration testing      | Annually or after major architecture changes             | 8.29         |

## Data Classification & Privacy
`ISO 27001: 5.12, 5.13, 8.10, 8.11`

| Requirement                    | Standard                                                      |
|-------------------------------|---------------------------------------------------------------|
| Data classification           | All assets classified: Public / Internal / Confidential / Restricted |
| PII register                  | All personal data documented with processing purpose, retention period, and legal basis |
| Data retention                | Defined per classification; automated deletion enforced       |
| PII in logs                   | Prohibited — mask or omit emails, tokens, passwords, IDs      |
| Production data in non-prod   | Prohibited — use anonymised or synthetic data only            |
| Data subject rights           | System must support access, correction, and deletion requests (PDPO / GDPR) |

## Accessibility

| Standard        | Level                               |
|-----------------|-------------------------------------|
| WCAG            | 2.1 AA                              |
| Keyboard nav    | All interactive elements            |
| Screen reader   | ARIA labels on all non-text content |
| Colour contrast | Minimum 4.5:1 (AA)                  |

## Scalability

| Metric             | Baseline requirement                                    |
|--------------------|---------------------------------------------------------|
| Horizontal scaling | Stateless services — scale via replicas                 |
| Session state      | Stored externally (Redis / DB), not in-process          |
| File uploads       | Stream to object storage — never to local disk          |

## Observability & Audit Logging
`ISO 27001: 8.15, 8.16, 8.17`

| Requirement           | Standard                                                              | ISO 27001 |
|-----------------------|-----------------------------------------------------------------------|-----------|
| Structured logging    | JSON format, log level configurable via env var                       | 8.15      |
| Request tracing       | Correlation ID on all requests (`X-Request-ID` header)                | 8.15      |
| Audit events logged   | Auth events, sensitive data access, privilege changes, data exports   | 8.15      |
| Log integrity         | Append-only store, separate from application                          | 8.15      |
| Log retention         | Minimum 12 months (90 days hot / remainder cold)                      | 8.15      |
| Clock sync            | NTP synchronisation across all services                               | 8.17      |
| Error tracking        | Errors reported to monitoring service (Sentry / Datadog)              | 8.16      |
| Metrics               | Expose `/metrics` endpoint (Prometheus-compatible)                    | 8.16      |
| Alerting              | PagerDuty / OpsGenie on p99 > threshold, error spike, auth anomalies  | 8.16      |

## Incident Response
`ISO 27001: 5.24, 5.25, 5.26, 5.27`

| Metric                              | Target                                      |
|-------------------------------------|---------------------------------------------|
| Detection to ISMS notification      | ≤ 1 hour                                    |
| P1 (Critical) response              | Immediate; resolution target ≤ 4 hours      |
| P2 (High) response                  | ≤ 4 hours; resolution target ≤ 24 hours     |
| Post-incident review (PIR)          | Within 5 business days of resolution        |
| Lessons-learned loop                | Fed back into risk register and checklist   |
