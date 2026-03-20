# Deployment — [Project Name]

> Project-specific deployment configuration and runbooks.
> Generic company standards: @agent_docs/generic/deployment-standards.md
> Fill in all [placeholders] before first deploy.

## Cloud Provider & Region

- **Provider:** [AWS / GCP / Azure]
- **Primary Region:** [e.g. ap-east-1 / asia-east1 / eastasia]
- **Disaster Recovery Region:** [e.g. ap-southeast-1 / asia-southeast1 / southeastasia]

## Environments

| Environment | URL                              | Cloud Account / Project ID   | Branch         |
|-------------|----------------------------------|------------------------------|----------------|
| dev         | https://dev.[project].example.com    | [account/project ID]     | `develop`      |
| staging     | https://staging.[project].example.com| [account/project ID]     | `release/*`    |
| production  | https://[project].example.com        | [account/project ID]     | `main`         |

## Services & Container Registry

| Service       | Image Name                              | Port | Notes             |
|---------------|-----------------------------------------|------|-------------------|
| API Server    | [registry]/[project]-api                | 8080 |                   |
| Frontend      | [registry]/[project]-web                | 80   |                   |
| [Add more...] |                                         |      |                   |

- **Container Registry:** [ECR URI / Artifact Registry host / ACR host]
- **Image tagging convention:** `[service]:[semver]-[git-sha]` e.g. `api:1.2.3-a1b2c3d`

## Infrastructure as Code

- **IaC Tool:** [Terraform / AWS CDK / Pulumi / Bicep]
- **IaC Repository:** [repo URL or path within this repo]
- **State Backend:** [e.g. S3 bucket name / GCS bucket / Azure Storage account]
- **State Locking:** [e.g. DynamoDB table / native GCS lock / Azure Blob lease]

## CI/CD Pipeline

- **CI/CD Tool:** GitHub Actions
- **Workflow files:** `.github/workflows/`

| Workflow File       | Trigger                   | Purpose                            |
|---------------------|---------------------------|------------------------------------|
| `ci.yml`            | All PRs                   | Test, SAST, dependency scan        |
| `deploy-dev.yml`    | Push to `develop`         | Build, scan, deploy to dev         |
| `deploy-staging.yml`| Push to `release/*`       | Build, scan, deploy to staging     |
| `deploy-prod.yml`   | Merge to `main`           | Build, scan, deploy to production  |

- **CI/CD Service Account (dev):** [name / ARN / email]
- **CI/CD Service Account (staging):** [name / ARN / email]
- **CI/CD Service Account (production):** [name / ARN / email]

## Secrets & Configuration

| Secret Name (in Secret Manager)    | Description                    | Environment        |
|------------------------------------|--------------------------------|--------------------|
| `/[project]/dev/db-password`       | Database password              | dev                |
| `/[project]/staging/db-password`   | Database password              | staging            |
| `/[project]/prod/db-password`      | Database password              | production         |
| `/[project]/prod/jwt-secret`       | JWT signing key                | production         |
| [Add more...]                      |                                |                    |

- **Secret Manager:** [AWS Secrets Manager / GCP Secret Manager / Azure Key Vault]
- **Secret access role / identity:** [IAM role or service account name]

## Health Checks

| Service    | Health Endpoint         | Expected Response                              |
|------------|-------------------------|------------------------------------------------|
| API Server | `GET /health`           | `200 { "status": "ok", "version": "x.y.z" }`  |
| Frontend   | `GET /`                 | `200`                                          |

## Rollback Procedure

> Run this if a production deploy must be reverted.

```bash
# 1. Identify the last stable image tag (check CI/CD run history or ECR/registry)
STABLE_TAG=[previous-image-tag]

# 2. Re-deploy using the previous image tag
# [provider-specific command — fill in]

# 3. Confirm health check passes
curl https://[project].example.com/health

# 4. Notify team and log the rollback event
```

- **Maximum rollback time target:** 15 minutes
- **Image retention period:** 30 days minimum (confirm in registry lifecycle policy)
- **Rollback decision authority:** [Lead Developer / Tech Lead / On-call]

## Deployment Runbook — Production

> Step-by-step for a planned production release.

1. Confirm all CI checks pass on the `release/*` branch
2. Confirm staging smoke tests pass
3. Notify the team: "Deploying vX.Y.Z to production at [time]"
4. Merge `release/*` → `main` via approved PR
5. Monitor the `deploy-prod.yml` pipeline run
6. Confirm `/health` returns `200` within 2 minutes
7. Monitor error rate and p99 latency for 15 minutes post-deploy
8. If error rate spikes > 5%: execute rollback procedure above
9. Log deployment: version, deployer, timestamp, any observations

## Monitoring & Alerting

| Tool          | Purpose                        | Link / Config Location       |
|---------------|--------------------------------|------------------------------|
| [Datadog / CloudWatch / GCP Monitoring] | Metrics, dashboards | [URL] |
| [PagerDuty / OpsGenie] | On-call alerting    | [URL]                        |
| [Sentry / Datadog APM] | Error tracking      | [URL]                        |

### Alert Thresholds

| Alert                  | Condition                          | Severity |
|------------------------|------------------------------------|----------|
| Service down           | `/health` fails 3 consecutive checks | P1     |
| High error rate        | Error rate > 5% for 5 minutes      | P1       |
| p99 latency breach     | p99 > 2s for 5 minutes             | P2       |
| Failed login spike     | > 50 failed logins in 1 minute     | P2       |

## Contacts

| Role                  | Name / Team                | Contact                  |
|-----------------------|----------------------------|--------------------------|
| Tech Lead             | [name]                     | [email / Slack]          |
| DevOps / Infrastructure| [name / team]             | [email / Slack]          |
| On-call rotation      | [PagerDuty schedule link]  |                          |
| Client contact        | [name]                     | [email]                  |
