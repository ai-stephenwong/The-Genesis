<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# Alibaba Cloud (Alicloud) Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.
> Note: Alicloud is the preferred platform for deployments targeting Mainland China or Southeast Asia.

## Recommended Service Stack

| Concern             | Service                              | Notes                                                   |
|---------------------|--------------------------------------|---------------------------------------------------------|
| Compute             | ACK (Alibaba Container Service for K8s) / SAE | SAE for simple apps; ACK for full K8s control  |
| Container Registry  | ACR (Container Registry Enterprise)  | Enterprise edition; scan on push enabled                |
| Object Storage      | OSS (Object Storage Service)         | Versioning + SSE-KMS encryption enabled                 |
| Database (SQL)      | RDS (PolarDB or ApsaraDB)            | Multi-zone HA for staging and production                |
| Database (NoSQL)    | Tablestore / ApsaraDB for MongoDB    | Tablestore for wide-column; MongoDB for documents       |
| Cache               | ApsaraDB for Redis                   | For sessions and hot data                               |
| Secrets             | KMS + Secrets Manager                | Mandatory for all credentials and keys                  |
| DNS / CDN           | Alibaba Cloud DNS + CDN              | ICP licence required for Mainland China domains         |
| Load Balancer       | ALB (Application Load Balancer)      | HTTPS only; HTTP → HTTPS redirect configured            |
| Email               | DirectMail (DM)                      | Domain verification + DKIM required                     |
| Queue               | MNS (Message Notification Service) / RocketMQ | Dead-letter queue configured                  |
| Monitoring          | ARMS + SLS (Simple Log Service)      | Centralised logs, metrics, APM traces                   |
| Audit Logging       | ActionTrail                          | All API calls logged and retained                       |
| Security Centre     | Security Centre (Cloud Security)     | Threat detection and vulnerability scanning             |

## IaC — Terraform with Alicloud Provider (Preferred)

```
infrastructure/
├── modules/
│   ├── networking/       # VPC, VSwitches, security groups
│   ├── compute/          # ACK cluster / SAE application
│   ├── database/         # RDS, Redis
│   ├── storage/          # OSS buckets
│   └── monitoring/       # SLS log stores, dashboards, alerts
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── backend.tf            # Remote state in OSS bucket
```

- Remote state in OSS with versioning; use OSSLock or DynamoDB-compatible locking `[ISO 27001: 8.32]`
- Separate Alicloud accounts per environment using Resource Directory (organisation management) `[ISO 27001: 8.31]`
- Resource Directory SCPs to enforce account-level guardrails

## Networking
`ISO 27001: 8.20, 8.22`

```
VPC
├── Public VSwitches     → ALB, NAT Gateway only
├── Private VSwitches    → ACK/SAE pods, RDS, Redis
└── No public endpoints  → Database and cache instances
```

- All application workloads in private VSwitches — no ECS or container instances with public IPs `[8.20]`
- Security Groups: whitelist only; no `0.0.0.0/0` inbound except ALB on 443 `[8.20]`
- Enable VPC Flow Logs and ship to SLS `[8.15]`
- Web Application Firewall (WAF) on ALB for production `[8.20]`
- For Mainland China: ensure all inbound traffic routes through approved ICP-licensed CDN `[8.20]`

## China-Specific Compliance Requirements

- **ICP Licence**: mandatory for any website or app accessible from Mainland China — obtain before go-live
- **Data Residency**: personal data of Chinese citizens must be stored in Mainland China regions per PIPL (Personal Information Protection Law)
- **MLPS (Multi-Level Protection Scheme)**: assess MLPS level (typically Level 2 or 3 for business systems); implement required controls
- **PIPL compliance**: equivalent to GDPR for personal data — consent, purpose limitation, data subject rights required
- **Cross-border data transfer**: requires security assessment if transferring personal data of Chinese citizens outside China
- Regions: `cn-hangzhou`, `cn-shanghai`, `cn-beijing` for Mainland China; `ap-southeast-1` (Singapore) for international

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.9, 8.24`

- **RAM (Resource Access Management)**: least-privilege policies; no wildcard `*` actions in production `[8.2]`
- **RAM Roles**: ACK pods and SAE apps use RAM roles — never use long-lived AccessKey pairs inside containers `[8.5]`
- **AccessKey pairs**: avoid for human users; use SSO via RAM Identity Provider; rotate every 90 days if used `[8.5]`
- **MFA**: required for all human RAM users, especially root and admin accounts `[8.2]`
- **Root account**: enable MFA; no AccessKey pairs; used only for break-glass scenarios `[8.2]`
- **OSS**: disable public read/write; use RAM policies and bucket policies only `[8.12]`
- **OSS encryption**: SSE-OSS minimum; SSE-KMS for sensitive data `[8.24]`
- **RDS**: encryption at rest enabled; SSL required for all connections `[8.24]`
- **Redis**: TLS in-transit enabled; VPC access only `[8.24]`
- **ACR**: vulnerability scanning on push; block deploy of images with critical CVEs `[8.8]`
- **Security Centre**: enabled at Advanced or Enterprise tier — findings routed to security team `[8.16]`
- **ActionTrail**: multi-region trail; log file delivery to OSS with integrity check enabled `[8.15]`

## CI/CD — GitHub Actions → ACR → ACK / SAE

```yaml
# Typical pipeline flow
1. Test (unit + integration)
2. SAST (CodeQL or SonarQube)
3. Dependency scan (Snyk or OWASP DC)
4. Secrets scan (GitLeaks)
5. Build Docker image
6. Push to ACR (tagged: git-sha + semver)
7. Trivy scan on pushed image
8. Deploy to ACK (kubectl apply) or SAE (Alibaba Cloud CLI / SDK)
9. Smoke tests / health check
```

- Use RAM OIDC role assumption for GitHub Actions — no long-lived AccessKey pairs in GitHub secrets `[8.5]`
- Separate RAM roles per environment with minimal permissions
- Image tags: `{semver}-{git-sha}` — never deploy `:latest`

## Secrets Management
`ISO 27001: 8.24, 5.17`

- All secrets in Alibaba Cloud Secrets Manager under naming convention: `env/service/secret-name`
- ACK workloads: use `ack-secret-manager` controller to sync secrets as Kubernetes secrets
- KMS: use Customer Master Keys (CMK) for envelope encryption of sensitive secrets `[8.24]`
- All secret access logged via ActionTrail `[8.15]`

## Monitoring & Observability
`ISO 27001: 8.15, 8.16`

- Structured JSON logs → SLS (Simple Log Service) → log stores per service per environment
- Log retention: 90 days hot (SLS) → OSS for remainder up to 12 months `[8.15]`
- ARMS (Application Real-Time Monitoring) for APM, traces, and dashboards
- Alerting: SLS alert rules or ARMS alerts → DingTalk / PagerDuty / OpsGenie
- ActionTrail events shipped to SLS for SIEM integration

## Backup & Recovery
`ISO 27001: 5.29, 5.30`

- RDS automated backups: 7-day minimum (30 days for production)
- Snapshot before every schema migration
- OSS versioning on all buckets with persistent data
- Cross-zone replication for production databases (HA within region)
- Cross-region OSS replication for disaster recovery
- DR runbook documented and tested annually `[5.30]`

## Cost Controls

- Cost allocation tags on all resources: environment, service, team
- OSS lifecycle rules: Infrequent Access after 30 days, Archive after 90
- ECS/ACK: right-size pod CPU/memory — review monthly
- Savings Plans or reserved instances for production baseline compute

## Compliance Evidence for ISO 27001 Audits
`ISO 27001: 5.28, 8.15`

| Evidence Required                    | Alicloud Source                                |
|--------------------------------------|------------------------------------------------|
| All API calls logged                 | ActionTrail                                    |
| Access to sensitive data audited     | ActionTrail + OSS access logs                  |
| Configuration drift detection        | Security Centre compliance checks              |
| Vulnerability scan results           | ACR scan reports + Security Centre findings    |
| Secret access audit                  | ActionTrail (KMS / Secrets Manager events)     |
| Network flow logs                    | VPC Flow Logs → SLS                            |
| Backup completion records            | RDS backup history                             |
| MLPS evidence                        | Security Centre MLPS compliance report         |
