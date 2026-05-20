# DispatchIQ

> Production-grade cloud infrastructure built with Terraform.
> Actively developed — additional phases in progress.

## Overview

End-to-end AWS infrastructure built entirely as code. No manual console
configuration. This repository documents the build process, design decisions,
and lessons learned at each phase of development.

**Built by:** Cornelius Rhone (DiehardArchitect)
**Certifications:** AWS SAA | AWS Cloud Practitioner | CompTIA Security+

---

## Current State — Phase 1: VPC Network Foundation

**What was built:**

- VPC (10.0.0.0/16) across 2 Availability Zones in us-east-1
- Public subnets (10.0.0.0/24, 10.0.1.0/24) — load balancer layer
- Private subnets (10.0.10.0/24, 10.0.11.0/24) — compute and data layer
- Internet Gateway for public subnet internet access
- NAT Gateways (one per AZ) for private subnet outbound-only access
- Route tables wiring each subnet tier to the correct gateway
- VPC Flow Logs to CloudWatch for full network audit trail
- Remote Terraform state: S3 (encrypted, versioned) + DynamoDB (state locking)

**Key design decisions:**

- Private subnets for all compute and data — no direct internet exposure
- One NAT Gateway per AZ — eliminates single point of failure for outbound traffic
- Flow logs enabled from day one — forensic capability before any workload runs
- Modular Terraform structure — VPC module is reusable across environments

---

## Tech Stack

| Layer | Tool |
|---|---|
| IaC | Terraform >= 1.6 |
| Cloud | AWS (us-east-1) |
| State Backend | S3 + DynamoDB |
| Networking | VPC, IGW, NAT Gateway, Route Tables |
| Logging | VPC Flow Logs, CloudWatch |

---

## Prerequisites
```bash
terraform version   # >= 1.6.0
aws --version       # >= 2.x
```

## Getting Started
```bash
# Bootstrap backend (run once)
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh

# Deploy dev environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

---

## Repository Structure
```
aws-cloud-platform/
|- terraform/
|   |- modules/
|   |   |- vpc/              # Reusable VPC module
|   |- environments/
|       |- dev/              # Dev environment config
|- docs/
|   |- architecture.md       # Design decisions and ADRs
|   |- lessons-learned.md    # Troubleshooting log
|- scripts/
    |- bootstrap.sh          # One-time backend setup
```

---

## Business Context

Infrastructure purpose-built to support a field services operation running
across multiple markets with 60+ personnel. Each phase replaces a manual
process or SaaS dependency with owned, version-controlled infrastructure.

All resources provisioned as code. No manual console configuration.
