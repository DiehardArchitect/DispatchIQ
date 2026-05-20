###############################################################################
# VPC Endpoints Module
#
# Provides VPC Interface Endpoints for AWS services so private-subnet workloads
# (like ECS Fargate tasks) can reach AWS APIs without traversing NAT or the
# public internet. Required for production-grade private connectivity.
#
# When var.enabled = false, this module is a no-op (zero resources created).
# This lets dev environments toggle the cost (~$29/mo when enabled) off while
# prod/staging keep the secure path on.
###############################################################################

locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  # Services that ECS Fargate tasks need to reach during pre-start (secrets/ECR
  # auth/image pull) and runtime (log streaming). Each is ~$7.20/mo + data.
  interface_endpoints = var.enabled ? toset([
    "secretsmanager",
    "ecr.api",
    "ecr.dkr",
    "logs",
  ]) : toset([])
}

###############################################################################
# Security Group for the endpoint ENIs
#
# Interface endpoints place ENIs in your private subnets. Those ENIs need an
# SG that allows 443 inbound from your application tasks — but nothing else.
# This is the lockdown layer: even if a task is compromised, it can only reach
# the four AWS services we explicitly allow via endpoint resolution.
###############################################################################
resource "aws_security_group" "endpoints" {
  count = var.enabled ? 1 : 0

  name        = "${var.project_name}-${var.environment}-vpc-endpoints"
  description = "VPC Interface Endpoints — accepts HTTPS from app tasks only"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  })
}

resource "aws_security_group_rule" "endpoints_ingress_https" {
  count = var.enabled ? 1 : 0

  type                     = "ingress"
  description              = "HTTPS from app tasks"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
  security_group_id        = aws_security_group.endpoints[0].id
}

###############################################################################
# Interface Endpoints (paid)
#
# private_dns_enabled = true makes AWS service hostnames (e.g.
# secretsmanager.us-east-1.amazonaws.com) resolve to the endpoint's private
# ENI IPs automatically. Without this, your SDK calls would still try to
# reach the public AWS endpoint and fail.
###############################################################################
resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-${replace(each.value, ".", "-")}-endpoint"
  })
}

###############################################################################
# S3 Gateway Endpoint (free)
#
# ECR stores image layers in S3 internally. Without an S3 gateway endpoint,
# the .dkr endpoint can reach ECR's API but the actual image-layer download
# would still need NAT or public internet. Gateway endpoints attach to route
# tables (not subnets) and don't cost anything.
###############################################################################
resource "aws_vpc_endpoint" "s3" {
  count = var.enabled ? 1 : 0

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  })
}
