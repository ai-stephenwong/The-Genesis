<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# AWS Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## Recommended Service Stack

| Concern             | Service                          | Notes                                         |
|---------------------|----------------------------------|-----------------------------------------------|
| Compute             | ECS Fargate / EKS                | Fargate for simplicity; EKS for complex workloads |
| Container Registry  | Amazon ECR                       | Private, scan-on-push enabled                 |
| Object Storage      | Amazon S3                        | Versioning + server-side encryption enabled   |
| Database (SQL)      | Amazon RDS (PostgreSQL / MySQL)  | Multi-AZ for staging and production           |
| Database (NoSQL)    | Amazon DynamoDB                  | On-demand billing; point-in-time recovery on  |
| Cache               | Amazon ElastiCache (Redis)       | For sessions and hot data                     |
| Secrets             | AWS Secrets Manager              | Never use SSM Parameter Store for secrets     |
| DNS / CDN           | Route 53 + CloudFront            | HTTPS enforced at CloudFront level            |
| Load Balancer       | Application Load Balancer (ALB)  | HTTPS listener only; HTTP → HTTPS redirect    |
| Email               | Amazon SES                       | Verify domains; DKIM + SPF configured         |
| Queue               | Amazon SQS                       | Dead-letter queue configured on all queues    |
| Events              | Amazon EventBridge               | For async event-driven architectures          |
| Monitoring          | CloudWatch + AWS X-Ray           | Centralised logs, metrics, traces             |
| SIEM / Audit        | AWS CloudTrail + CloudWatch Logs | All API calls logged and retained             |

## IaC — Terraform (Preferred)

```
infrastructure/
├── modules/
│   ├── networking/       # VPC, subnets, security groups
│   ├── compute/          # ECS / EKS cluster
│   ├── database/         # RDS, ElastiCache
│   ├── storage/          # S3 buckets
│   └── monitoring/       # CloudWatch, alarms, dashboards
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── backend.tf            # Remote state in S3 + DynamoDB lock
```

- Remote state stored in S3 with versioning; lock via DynamoDB table `[ISO 27001: 8.32]`
- Separate AWS accounts per environment (dev / staging / production) — strongly preferred `[ISO 27001: 8.31]`
- Use AWS Organizations + SCPs to enforce account-level guardrails

## Networking
`ISO 27001: 8.20, 8.22`

```
VPC (10.0.0.0/16)
├── Public Subnets      → ALB, NAT Gateway only
├── Private Subnets     → ECS tasks, EKS nodes, RDS, ElastiCache
└── Isolated Subnets    → RDS (no outbound internet access)
```

- No EC2 instances or application services in public subnets `[8.20]`
- All inter-service communication via private subnets
- Security groups: least-privilege ingress/egress — no `0.0.0.0/0` inbound except ALB on 443 `[8.20]`
- VPC Flow Logs enabled and shipped to CloudWatch `[8.15]`
- AWS Network Firewall or WAF on ALB for production `[8.20]`

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.9, 8.24`

- **IAM**: follow least-privilege — no wildcard `*` actions in production IAM policies `[8.2]`
- **IAM Roles**: ECS tasks and Lambda use task roles — never use long-lived access keys inside containers `[8.5]`
- **MFA**: required for all human IAM users, especially root and admin accounts `[8.2]`
- **Root account**: no access keys; locked away; only used for break-glass scenarios `[8.2]`
- **S3**: block all public access at account level unless explicitly required `[8.12]`
- **S3 encryption**: SSE-S3 minimum; SSE-KMS for sensitive data `[8.24]`
- **RDS**: encryption at rest enabled; TLS required for connections `[8.24]`
- **ElastiCache**: encryption at rest and in-transit enabled `[8.24]`
- **ECR**: scan on push enabled; block images with critical CVEs from deploying `[8.8]`
- **GuardDuty**: enabled in all accounts — alerts routed to security team `[8.16]`
- **AWS Config**: rules enabled to detect configuration drift `[8.9]`
- **Security Hub**: enabled and aggregated across accounts
- **CloudTrail**: multi-region trail; log file integrity validation enabled `[8.15]`

## CI/CD — GitHub Actions → ECR → ECS/EKS

```yaml
# Typical pipeline flow
1. Test (unit + integration)
2. SAST (CodeQL or SonarQube)
3. Dependency scan (Snyk or OWASP DC)
4. Secrets scan (GitLeaks)
5. Build Docker image
6. Push to ECR (tagged: git-sha + semver)
7. Trivy scan on pushed image
8. Deploy to ECS (task definition update) or EKS (kubectl apply)
9. Smoke tests / health check
```

- Use OIDC-based GitHub Actions authentication to AWS — no long-lived AWS access keys in GitHub secrets `[8.5]`
- Separate IAM roles per environment with minimal permissions
- Image tags: `{semver}-{git-sha}` — never deploy `:latest`

## Secrets Management
`ISO 27001: 8.24, 5.17`

- All secrets in AWS Secrets Manager under path `/env/service/secret-name`
- ECS task definitions reference secrets by ARN — values never appear in task definition JSON
- Secret rotation: enable automatic rotation for DB credentials via Secrets Manager
- Audit all secret access via CloudTrail `[8.15]`

## Monitoring & Observability
`ISO 27001: 8.15, 8.16`

- Structured JSON logs → CloudWatch Logs → log groups per service per environment
- Log retention: 90 days hot (CloudWatch) → S3 Glacier for remainder up to 12 months `[8.15]`
- CloudWatch Alarms on: p99 latency, error rate, CPU/memory, ALB 5xx rate
- AWS X-Ray for distributed tracing (or OpenTelemetry → X-Ray)
- Dashboards per service in CloudWatch or Grafana (CloudWatch data source)
- PagerDuty / OpsGenie integration via CloudWatch Alarm → SNS → webhook

## Backup & Recovery
`ISO 27001: 5.29, 5.30`

- RDS automated backups: 7-day minimum retention (30 days for production)
- RDS snapshot before every schema migration
- S3 versioning enabled on all buckets containing persistent data
- Point-in-time recovery enabled on DynamoDB tables
- Cross-region backup copy for production databases (RTO/RPO compliance)
- DR runbook documented and tested annually `[5.30]`

## Cost Controls

- Budget alerts in AWS Budgets per account / environment
- S3 lifecycle policies: move to Infrequent Access after 30 days, Glacier after 90
- ECS/EKS: right-size task/pod CPU and memory — review monthly
- RDS: use Reserved Instances for production baseline after 3 months of stable load

## Compliance Evidence for ISO 27001 Audits
`ISO 27001: 5.28, 8.15`

| Evidence Required                    | AWS Source                                 |
|--------------------------------------|--------------------------------------------|
| All API calls logged                 | CloudTrail                                 |
| Access to sensitive data audited     | CloudTrail + S3 access logs                |
| Configuration drift detection        | AWS Config                                 |
| Vulnerability scan results           | ECR scan reports + GuardDuty findings      |
| Secret access audit                  | CloudTrail (Secrets Manager events)        |
| Network flow logs                    | VPC Flow Logs                              |
| Backup completion records            | RDS automated backup events                |
