<!-- last-reviewed: 2026-03-16 | reviewed-by: Stephen Wong | next-review: 2026-09-16 -->

# On-Premise Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## Recommended Stack

| Concern             | Technology                            | Notes                                              |
|---------------------|---------------------------------------|----------------------------------------------------|
| Compute             | Kubernetes (K8s) via kubeadm or Rancher | RKE2 (Rancher) preferred for enterprise on-prem  |
| Container Registry  | Harbor                                | Self-hosted; vulnerability scanning built-in       |
| Object Storage      | MinIO                                 | S3-compatible API; deploy in distributed mode      |
| Database (SQL)      | PostgreSQL (self-managed or Patroni)  | Patroni for HA; pgBackRest for backups             |
| Database (NoSQL)    | MongoDB (self-managed) / Redis        | Replica set for HA                                 |
| Cache               | Redis Sentinel or Redis Cluster       | For sessions and hot data                          |
| Secrets             | HashiCorp Vault                       | Mandatory — no plaintext secrets anywhere          |
| DNS / Load Balancer | MetalLB + NGINX Ingress / HAProxy     | TLS termination at ingress                         |
| Certificates        | cert-manager + internal CA or Let's Encrypt | Internal CA for air-gapped environments      |
| Queue               | RabbitMQ or Apache Kafka              | Mirrored queues / replicated partitions for HA     |
| Monitoring          | Prometheus + Grafana + Loki           | Full observability stack — self-hosted             |
| Audit Logging       | Loki + Elasticsearch (ELK optional)  | Append-only log store; separate from app servers   |
| CI/CD               | GitLab CI (self-hosted) or Jenkins    | Agents/runners on dedicated build nodes            |

## IaC — Terraform + Ansible

```
infrastructure/
├── terraform/
│   ├── modules/
│   │   ├── networking/        # VLAN, firewall rules
│   │   ├── kubernetes/        # Node provisioning
│   │   └── storage/           # MinIO, persistent volumes
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── production/
└── ansible/
    ├── playbooks/
    │   ├── harden-os.yml      # CIS benchmark hardening
    │   ├── install-k8s.yml    # Kubernetes node setup
    │   └── install-vault.yml  # HashiCorp Vault setup
    └── inventory/
        ├── dev
        ├── staging
        └── production
```

- All infrastructure changes via Terraform/Ansible — no manual SSH changes to servers `[ISO 27001: 8.32]`
- Terraform state stored in GitLab-managed Terraform state or dedicated Consul backend `[8.32]`
- Separate server groups (VLANs or network segments) per environment `[ISO 27001: 8.31]`

## Networking & Physical Security
`ISO 27001: 7.1, 7.2, 8.20, 8.22`

```
Network Segments
├── DMZ               → Ingress controllers, load balancers only
├── Application       → Kubernetes nodes (app workloads)
├── Data              → Database servers, MinIO, Redis
├── Management        → Bastion hosts, CI/CD runners, monitoring
└── No direct routing between DMZ and Data segments
```

- Physical access to servers restricted to authorised personnel only `[ISO 27001: 7.1, 7.2]`
- Server room access logged and audited (badge access or key register) `[7.2]`
- Network firewall rules: default deny; explicit allow only `[8.20]`
- All inter-service communication within private network segments — no public IPs on app or DB nodes `[8.20]`
- Bastion host (jump server) required for any SSH access — direct SSH to production nodes disallowed `[8.20]`
- Network switch port security enabled; unused ports disabled `[8.20]`

## Server Hardening
`ISO 27001: 8.8, 8.9`

- Apply CIS Benchmark Level 1 (minimum) to all server OS builds `[8.9]`
- OS patching schedule: Critical ≤ 24h, High ≤ 7 days, Medium ≤ 30 days `[8.8]`
- Disable unused services and ports on all nodes
- SSH: key-based authentication only; password auth disabled; root login disabled `[8.5]`
- SSH keys centralised via LDAP/AD or Vault SSH Secrets Engine — no shared SSH keys `[8.5]`
- Configure auditd for OS-level audit logging `[8.15]`
- Intrusion detection: AIDE or Wazuh HIDS on all production nodes `[8.16]`

## Kubernetes Hardening
`ISO 27001: 8.2, 8.9, 8.25`

- RBAC enabled — no cluster-admin bindings except for break-glass accounts `[8.2]`
- Pod Security Standards: enforce `restricted` profile in production namespaces `[8.9]`
- Network Policies: default deny all; explicit allow per service `[8.20]`
- Secrets encrypted at rest in etcd (encryption provider configured) `[8.24]`
- etcd: TLS client certificates required; separate from worker nodes `[8.24]`
- Node-to-node communication encrypted (Calico WireGuard or similar CNI) `[8.24]`
- Admission controllers: OPA/Gatekeeper or Kyverno for policy enforcement `[8.9]`
- Kubernetes API server: not exposed outside management network `[8.20]`
- Audit logging on Kubernetes API server enabled and shipped to Loki `[8.15]`

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.24`

- **HashiCorp Vault**: AppRole or Kubernetes auth for workload secrets; no static tokens `[8.5]`
- **Vault policies**: least-privilege — workloads read only their own secrets `[8.2]`
- **Vault audit**: all secret access logged to file and shipped to Loki `[8.15]`
- **TLS everywhere**: internal CA-signed certs for all service-to-service communication `[8.24]`
- **cert-manager**: automate certificate issuance and renewal `[8.24]`
- **Harbor**: scan images on push; block deployment of images with critical CVEs `[8.8]`
- **MFA**: required for all privileged access (Vault, Kubernetes dashboard, GitLab admin) `[8.2]`
- **LDAP/AD integration**: centralise identity for all services — no local service accounts `[8.5]`

## CI/CD — GitLab CI or Jenkins → Harbor → Kubernetes

```yaml
# Typical pipeline flow
1. Test (unit + integration)
2. SAST (SonarQube — self-hosted)
3. Dependency scan (OWASP Dependency Check)
4. Secrets scan (GitLeaks)
5. Build Docker image
6. Push to Harbor (tagged: git-sha + semver)
7. Trivy scan on pushed image (or Harbor built-in scan)
8. Deploy to Kubernetes (kubectl apply / Helm upgrade)
9. Smoke tests / health check
```

- CI/CD runners isolated on dedicated build nodes — not shared with application nodes `[8.31]`
- Separate service accounts per environment in Kubernetes for CI/CD deployments `[8.2]`
- Image tags: `{semver}-{git-sha}` — never deploy `:latest`

## Secrets Management — HashiCorp Vault
`ISO 27001: 8.24, 5.17`

- Vault deployed in HA mode (3-node Raft cluster minimum for production)
- All application secrets injected at runtime via Vault Agent Injector or Vault Secrets Operator
- Vault unsealing: use Vault Auto Unseal with an HSM or cloud KMS if available; otherwise Shamir with split key holders `[8.24]`
- Secret leases: short TTL + dynamic secrets for database credentials `[8.24]`
- All Vault access logged via Vault audit device → Loki `[8.15]`
- Vault root token: generated once, immediately revoked after initial setup `[8.5]`

## Monitoring & Observability
`ISO 27001: 8.15, 8.16`

- Prometheus scrapes all services and Kubernetes node metrics
- Grafana dashboards per service and per environment
- Loki for log aggregation — structured JSON logs from all containers
- Log retention: 90 days hot (Loki) → object storage (MinIO) for remainder up to 12 months `[8.15]`
- Alertmanager → PagerDuty / OpsGenie for on-call alerts
- Wazuh HIDS alerts integrated into Grafana or SIEM `[8.16]`

## Backup & Recovery
`ISO 27001: 5.29, 5.30`

- PostgreSQL: pgBackRest continuous WAL archiving to MinIO; full backup daily; 30-day retention for production `[5.29]`
- Snapshot before every schema migration
- etcd: snapshot every 30 minutes; stored off-node on MinIO `[5.29]`
- MinIO: erasure coding enabled (minimum 4+2 for production); data replicated across physical nodes
- Persistent Volumes: Velero for Kubernetes PV backup to MinIO
- Offsite backup: replicate MinIO buckets to a secondary site or encrypted cloud bucket `[5.30]`
- DR runbook documented and tested annually; RTO/RPO validated `[5.30]`

## Capacity & Availability

- Production Kubernetes cluster: minimum 3 control-plane nodes + 3 worker nodes across separate physical hosts
- Database: Patroni HA with automatic failover; `max_wal_senders` and `hot_standby` configured
- UPS and generator for data centre power continuity `[ISO 27001: 7.5, 7.6]`
- Environmental controls (cooling, humidity): monitored with alerting `[7.5]`

## Compliance Evidence for ISO 27001 Audits
`ISO 27001: 5.28, 8.15`

| Evidence Required                    | On-Prem Source                                  |
|--------------------------------------|-------------------------------------------------|
| All admin access logged              | auditd + Kubernetes API audit logs → Loki       |
| Access to sensitive data audited     | Vault audit logs + application audit logs       |
| Configuration drift detection        | Ansible playbook runs + AIDE integrity reports  |
| Vulnerability scan results           | Harbor scan reports + Trivy CI reports          |
| Secret access audit                  | Vault audit logs                                |
| Network flow logs                    | Firewall logs + netflow data                    |
| Backup completion records            | pgBackRest logs + Velero backup reports         |
| Physical access records              | Badge access logs / key register                |
| Server hardening evidence            | CIS benchmark scan reports (Lynis / OpenSCAP)   |
