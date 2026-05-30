# DispatchIQ

Production-grade AWS infrastructure for a field service automation platform, built phase-by-phase as code with Terraform. No manual console configuration. Each phase documented with design decisions and trade-offs.

**Built by:** Cornelius Rhone ([DiehardArchitect](https://github.com/DiehardArchitect))
**Certifications:** AWS Solutions Architect Associate | AWS Cloud Practitioner | CompTIA Security+

---

## Current State

| Phase | Layer | Status |
|---|---|---|
| 1 | VPC and networking foundation | Complete |
| 2 | Security foundation (KMS, IAM, Security Groups, Secrets Manager, CloudTrail) | Complete |
| 3 | Compute (ECR, ECS Fargate, ALB) | Complete |
| 3.5 | Hardening (VPC endpoints toggle, KMS auth fixes) | Complete |
| 4 | Data layer (RDS PostgreSQL 16, encrypted, private) | Complete |
| 5 | CI/CD via GitHub Actions | Planned |
| 6 | Observability and alerting | Planned |
| 7 | Threat detection (GuardDuty, Security Hub) | Planned |

---

## Architecture    
Internet
                          |
              +-----------v-----------+
              |   Application LB      |  Public subnets
              |   (port 80/443)       |  AZ-a + AZ-b
              +-----------+-----------+
                          |
              +-----------v-----------+
              |  ECS Fargate Service  |  Private subnets
              |  (2 tasks across AZs) |  AZ-a + AZ-b
              +-----------+-----------+
                          |
              +-----------v-----------+
              |   RDS PostgreSQL 16   |  Private subnets
              |   (encrypted, KMS)    |  AZ-a + AZ-b
              +-----------------------+

VPC 10.0.0.0/16 | us-east-1
              Public:  10.0.0.0/24, 10.0.1.0/24
              Private: 10.0.10.0/24, 10.0.11.0/24
---

## What is built (Phase 1 through 4)

### Phase 1: VPC and Networking

- VPC `10.0.0.0/16` across two availability zones in `us-east-1`
- Public subnets for the load balancer layer
- Private subnets for compute and data
- Internet Gateway for public subnet egress
- Two NAT Gateways (one per AZ) for private subnet outbound traffic, with AZ-aligned routing to avoid cross-AZ data charges
- VPC Flow Logs streaming to CloudWatch
- DynamoDB Gateway Endpoint (free, no NAT traversal for DynamoDB API calls)
- Remote Terraform state: S3 (encrypted, versioned) + DynamoDB table for state locking

### Phase 2: Security Foundation

- Four KMS keys (EBS, RDS, S3, Secrets) with automatic annual rotation
- Dedicated key policies per use case rather than a shared template
- IAM EC2 instance role with SSM Session Manager and CloudWatch agent permissions
- Three-tier Security Groups (ALB, App, RDS) with circular dependency resolved via separated `aws_security_group_rule` resources
- Secrets Manager for database credentials and application secrets, with `lifecycle.ignore_changes` to prevent rotation overwrites
- Multi-region CloudTrail with KMS encryption and log file validation enabled

### Phase 3: Compute Layer

- ECR repository with immutable tags, vulnerability scanning on push, and lifecycle policies
- ECS Fargate cluster with Container Insights enabled
- Dual IAM role architecture (execution role for the agent, task role for application permissions)
- Application Load Balancer in public subnets routing to ECS tasks in private subnets
- ECS Service maintaining two tasks across both availability zones
- Task definition with Secrets Manager injection at runtime

### Phase 3.5: Hardening

- New `vpc-endpoints` module providing environment-aware private connectivity
- Variable-driven toggle (`var.use_vpc_endpoints`): dev defaults to NAT-based AWS API access for cost, prod uses VPC Interface Endpoints (Secrets Manager, ECR API, ECR DKR, CloudWatch Logs) plus S3 Gateway Endpoint, with app security group egress scoped to VPC CIDR
- KMS key policy refactored to grant the ECS execution role `kms:Decrypt` on the secrets key, scoped by `kms:ViaService` to Secrets Manager only

### Phase 4: Data Layer

- RDS PostgreSQL 16 on `db.t4g.micro` (Graviton ARM)
- Encrypted at rest with the RDS KMS key from Phase 2
- Private subnet group spanning both AZs, `publicly_accessible = false`
- `manage_master_user_password = true` — master credentials generated and rotated by RDS, stored in a dedicated `rds!`-prefixed Secrets Manager secret encrypted with the same KMS key
- Custom parameter group with `rds.force_ssl = 1` (engine-level rejection of unencrypted connections) and `log_min_duration_statement = 1000` (slow query logging)
- Performance Insights enabled (7-day retention, free tier)
- Enhanced monitoring at 60-second intervals
- PostgreSQL logs exported to CloudWatch
- Variable-driven `var.deploy_rds` toggle to cleanly add/remove the data layer between sessions

---

## Repository Structure
---

## Tech Stack

| Layer | Tool |
|---|---|
| Infrastructure as Code | Terraform >= 1.6 |
| Cloud | AWS (us-east-1) |
| State backend | S3 (encrypted, versioned) + DynamoDB (locking) |
| Networking | VPC, IGW, NAT Gateway, Route Tables, VPC Endpoints |
| Compute | ECS Fargate |
| Load balancing | Application Load Balancer |
| Data | RDS PostgreSQL 16 |
| Container registry | ECR |
| Secrets | Secrets Manager (manual + RDS-managed) |
| Encryption | KMS (4 keys, auto-rotated) |
| Audit | CloudTrail (multi-region), VPC Flow Logs |
| Observability | CloudWatch Logs, Performance Insights, Container Insights |

---

## Design Principles

- **Modular by concern.** Each module owns one layer. Modules consume outputs from each other, never reach into each other's internals.
- **Environment-aware via variables.** Dev and prod share the same module code. Differences (`use_vpc_endpoints`, `deploy_rds`, `multi_az`, `deletion_protection`, `skip_final_snapshot`) are toggled via variables, not separate codebases.
- **Cost-aware destroy/recreate pattern.** Expensive idle resources (NAT Gateways, RDS) can be destroyed between development sessions via targeted destroys or toggle flags. Reduces idle spend without losing infrastructure code.
- **Defense in depth.** Network isolation (private subnets), security group restrictions, KMS encryption at rest, TLS-only connections at the engine level, IAM least privilege, audit logging from day one.
- **No console drift.** Every resource is defined in Terraform. Manual AWS console changes are policy violations, not workarounds.

---

## Prerequisites
---

## Getting Started
---

## Business Context

DispatchIQ is being built to support a field service operation running across multiple markets. Each phase replaces a manual process or third-party dependency with owned, version-controlled infrastructure. The platform also serves as a portfolio piece demonstrating production-grade AWS architecture, Terraform module design, and security engineering practices.

The DispatchIQ name is trademark-secured.
