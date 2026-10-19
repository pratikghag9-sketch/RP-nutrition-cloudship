# CloudShip: RP Nutrition on AWS

> Taking a real Flask + PostgreSQL e-commerce app from a simple PaaS deployment to a production-style AWS platform, built end to end with Infrastructure as Code, CI/CD, secrets management and monitoring.

![Status](https://img.shields.io/badge/status-in%20progress-orange)
![Cloud](https://img.shields.io/badge/cloud-AWS-232F3E)
![IaC](https://img.shields.io/badge/IaC-Terraform-7B42BC)

## Why this project

The application (RP Nutrition: Flask, SQLAlchemy, PostgreSQL, JWT auth) already runs on Render. This project rebuilds its hosting the way a real team would on AWS, so every important cloud service gets used for an actual reason, not as a tutorial exercise.

**Goals**
- Provision everything as code (Terraform), reproducible with one command
- Deploy automatically on every `git push` (GitHub Actions, no long-lived keys)
- Keep secrets out of code (Secrets Manager)
- Follow least privilege (IAM) and keep costs under control
- Monitor and alert (CloudWatch, SNS)

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 0 | Account security, billing guardrails, IAM user, CLI access | Done |
| 1 | Terraform base: remote state (S3), reusable VPC module | In progress |
| 2 | Secrets Manager, ECR, Docker image for the Flask app | Planned |
| 3 | ECS Fargate service behind an Application Load Balancer | Planned |
| 4 | RDS PostgreSQL in private subnets, app connected to it | Planned |
| 5 | CI/CD with GitHub Actions (OIDC to AWS) | Planned |
| 6 | S3 + CloudFront, Route 53 and ACM (custom domain, HTTPS) | Planned |
| 7 | CloudWatch dashboards and alarms, SNS alerts, IAM least-privilege hardening | Planned |
| 8 | Demo video, final documentation, cost summary, teardown | Planned |

## Target architecture (planned)

```mermaid
flowchart TB
    Dev[Developer] -->|git push| GH[GitHub Actions]
    GH -->|build and push image| ECR[ECR]
    GH -->|deploy| ECS
    User[Users] --> CF[CloudFront]
    CF --> ALB[Application Load Balancer]
    ALB --> ECS[ECS Fargate - Flask app]
    ECS --> RDS[(RDS PostgreSQL - private subnets)]
    ECS --> SM[Secrets Manager]
    ECS --> CW[CloudWatch Logs and Alarms]
    CW --> SNS[SNS email alerts]
```

## AWS services and why each is used

| Service | Purpose in this project |
|---|---|
| VPC | Isolated network with public and private subnets |
| IAM | Least-privilege access for people, pipelines and services |
| S3 | Terraform remote state and static assets |
| ECR | Private storage for Docker images |
| ECS Fargate | Run the Flask container without managing servers |
| ALB | Distribute traffic and run health checks |
| RDS (PostgreSQL) | Managed database in private subnets |
| Secrets Manager | Store DB password, JWT secret and API keys |
| CloudFront | CDN and HTTPS in front of the app |
| Route 53 and ACM | Custom domain and free TLS certificate |
| CloudWatch | Logs, dashboards, alarms |
| SNS | Email notifications for alarms |

## Phase 0: Foundation (done)

Before creating any infrastructure, the account was secured and cost-protected.

```mermaid
flowchart LR
    R["Root user<br/>MFA on, no access keys<br/>billing and emergencies only"] -->|bootstraps| G["IAM group: admins"]
    G --> U["IAM user<br/>MFA on, console + CLI"]
    U --> P["AWS CLI named profile"]
    P --> T["Terraform"]
    B["Budgets and cost alerts"] -.->|watch spend| R
```

**What was done**
- Root account protected with MFA, no root access keys, alternate contacts set
- Monthly cost budget, zero-spend alert, Free Tier usage alerts and cost anomaly detection
- IAM password policy, an `admins` group, and a named IAM user with MFA (permissions granted via the group, not directly to the user)
- Access key created for the CLI and stored in a named profile, never in the repository
- Verified: console login as the IAM user with MFA, and `aws sts get-caller-identity` returns the IAM user

**What was learned**
- Why root is not used for daily work, and how MFA protects the account
- Users, groups, roles and policies, and why permissions go to groups
- Why budgets alert but do not stop spending, so resources are destroyed after each session

**Known trade-off:** the admin group currently uses a broad managed policy for learning speed. It will be replaced with scoped, least-privilege policies in Phase 7.

## Repository structure

```
rp-nutrition-cloudship/
├── bootstrap/     # remote state bucket (created first, uses local state)
├── modules/       # reusable Terraform modules (vpc, ...)
└── envs/
    └── dev/       # actual deployment that consumes the modules
```

## Cost control

- Hourly-billed resources (NAT Gateway, ALB, RDS, Fargate) exist only during work sessions
- `terraform destroy` after every session, then a billing check
- Budget alerts and anomaly detection enabled from day one
- Always-on foundation (IAM, state bucket, VPC without NAT) costs almost nothing

## Security notes

- No credentials, state files or `.tfvars` are committed (see `.gitignore`)
- Account identifiers are intentionally omitted from this documentation

## Progress log

| Date | Update |
|---|---|
| Phase 0 | Account secured, billing guardrails and IAM access set up |
| Phase 1 | Terraform base in progress |
