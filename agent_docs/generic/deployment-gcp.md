<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# GCP Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## Recommended Service Stack

| Concern             | Service                              | Notes                                             |
|---------------------|--------------------------------------|---------------------------------------------------|
| Compute (simple)    | Cloud Run                            | Fully managed; prefer for stateless HTTP services |
| Compute (complex)   | Google Kubernetes Engine (GKE)       | Autopilot mode preferred                          |
| Container Registry  | Artifact Registry                    | Never use deprecated Container Registry           |
| Object Storage      | Cloud Storage (GCS)                  | Versioning + CMEK encryption enabled              |
| Database (SQL)      | Cloud SQL (PostgreSQL / MySQL)       | HA config for staging and production              |
| Database (NoSQL)    | Firestore / Bigtable                 | Firestore for documents; Bigtable for time-series |
| Cache               | Memorystore (Redis)                  | For sessions and hot data                         |
| Secrets             | Secret Manager                       | Mandatory for all credentials and keys            |
| DNS / CDN           | Cloud DNS + Cloud CDN                | HTTPS enforced; HTTP → HTTPS redirect via LB      |
| Load Balancer       | Cloud Load Balancing (HTTPS LB)      | Global; SSL policy: MODERN (TLS 1.2+)             |
| Email               | SendGrid or Mailgun via GCP          | GCP does not have a native email service          |
| Queue               | Cloud Pub/Sub or Cloud Tasks         | Dead-letter topic configured                      |
| Monitoring          | Cloud Monitoring + Cloud Trace       | Centralised logs, metrics, traces                 |
| Audit Logging       | Cloud Audit Logs                     | Admin, data access, and system event logs         |

## IaC — Terraform (Preferred)

```
infrastructure/
├── modules/
│   ├── networking/       # VPC, subnets, firewall rules
│   ├── compute/          # Cloud Run services / GKE cluster
│   ├── database/         # Cloud SQL, Memorystore
│   ├── storage/          # GCS buckets
│   └── monitoring/       # Alerting policies, dashboards
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── backend.tf            # Remote state in GCS bucket
```

- Remote state stored in GCS with versioning and object locking `[ISO 27001: 8.32]`
- Separate GCP Projects per environment — use GCP Organization + folders `[ISO 27001: 8.31]`
- Organization Policy constraints to enforce guardrails (e.g. no public IPs, no external service accounts)

## Networking
`ISO 27001: 8.20, 8.22`

```
VPC (Shared VPC or per-project)
├── Public-facing      → Cloud Load Balancer only (managed by Google)
├── Private Subnets    → Cloud Run (VPC connector), GKE nodes, Cloud SQL
└── Serverless VPC Access → Cloud Run → internal services
```

- Cloud Run services: set ingress to `internal-and-cloud-load-balancing` — no direct external access `[8.20]`
- Firewall rules: deny-all default; explicit allow rules for required traffic only `[8.20]`
- VPC Service Controls: perimeter around sensitive projects to prevent data exfiltration `[8.12]`
- Private Service Connect for Cloud SQL — no public IP on database instances `[8.20]`
- Cloud Armor WAF on HTTPS Load Balancer for production `[8.20]`

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.9, 8.24`

- **IAM**: principle of least privilege — use predefined roles; avoid primitive roles (Owner, Editor) `[8.2]`
- **Workload Identity**: Cloud Run and GKE workloads use Workload Identity — no service account key files `[8.5]`
- **Service Account Keys**: disabled org-wide via Organization Policy where possible `[8.5]`
- **MFA**: required for all human accounts via Google Workspace or Cloud Identity `[8.2]`
- **GCS**: uniform bucket-level access enabled; public access prevention on `[8.12]`
- **GCS encryption**: CMEK (Cloud KMS) for sensitive buckets `[8.24]`
- **Cloud SQL**: encrypted at rest by default; SSL required for all connections `[8.24]`
- **Artifact Registry**: vulnerability scanning enabled on push `[8.8]`
- **Security Command Center**: enabled at Premium tier — findings routed to security team `[8.16]`
- **Cloud Asset Inventory**: enabled for configuration drift detection `[8.9]`
- **Audit Logs**: Data Access audit logs enabled for all services handling sensitive data `[8.15]`

## CI/CD — GitHub Actions → Artifact Registry → Cloud Run / GKE

```yaml
# Typical pipeline flow
1. Test (unit + integration)
2. SAST (CodeQL or SonarQube)
3. Dependency scan (Snyk or OWASP DC)
4. Secrets scan (GitLeaks)
5. Build Docker image
6. Push to Artifact Registry (tagged: git-sha + semver)
7. Trivy scan on pushed image
8. Deploy to Cloud Run (gcloud run deploy) or GKE (kubectl apply)
9. Smoke tests / health check
```

- Use Workload Identity Federation for GitHub Actions — no long-lived service account keys in GitHub secrets `[8.5]`
- Separate service accounts per environment with minimal IAM roles
- Image tags: `{semver}-{git-sha}` — never deploy `:latest`

## Secrets Management
`ISO 27001: 8.24, 5.17`

- All secrets in GCP Secret Manager under naming convention: `env-service-secret-name`
- Cloud Run references secrets as environment variables or mounted volumes via Secret Manager integration
- Secret versions: disable old versions after rotation; never delete (retain for audit)
- All secret access logged via Cloud Audit Logs `[8.15]`

## Monitoring & Observability
`ISO 27001: 8.15, 8.16`

- Structured JSON logs → Cloud Logging → log buckets per environment
- Log retention: 30 days default → configure _Default bucket to 400 days for compliance `[8.15]`
- Log sink to Cloud Storage for long-term cold retention (12 months total) `[8.15]`
- Cloud Monitoring alerting policies: p99 latency, error rate, CPU/memory, HTTP 5xx
- Cloud Trace for distributed tracing (or OpenTelemetry → Cloud Trace)
- Dashboards in Cloud Monitoring or Grafana (Cloud Monitoring data source)
- PagerDuty / OpsGenie via Cloud Monitoring → Pub/Sub → webhook

## Backup & Recovery
`ISO 27001: 5.29, 5.30`

- Cloud SQL automated backups: 7-day minimum (30 days for production)
- On-demand snapshot before every schema migration
- GCS versioning enabled on all buckets containing persistent data
- Point-in-time recovery (PITR) enabled on Cloud SQL for production
- Cross-region backup copy for production databases
- DR runbook documented and tested annually `[5.30]`

## Cost Controls

- Budget alerts in GCP Billing per project / environment
- GCS lifecycle policies: move to Nearline after 30 days, Coldline after 90, Archive after 365
- Cloud Run: set min-instances to 0 for dev; tune max-instances with concurrency
- Committed Use Discounts (CUDs) for GKE node pools after 3 months stable load

## Compliance Evidence for ISO 27001 Audits
`ISO 27001: 5.28, 8.15`

| Evidence Required                    | GCP Source                                      |
|--------------------------------------|-------------------------------------------------|
| All admin API calls logged           | Cloud Audit Logs (Admin Activity)               |
| Access to sensitive data audited     | Cloud Audit Logs (Data Access)                  |
| Configuration drift detection        | Cloud Asset Inventory + Security Command Center |
| Vulnerability scan results           | Artifact Registry scan + Security Command Center|
| Secret access audit                  | Cloud Audit Logs (Secret Manager events)        |
| Network flow logs                    | VPC Flow Logs                                   |
| Backup completion records            | Cloud SQL backup history                        |
