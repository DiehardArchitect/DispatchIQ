###############################################################################
# RDS Module — PostgreSQL for DispatchIQ
#
# Phase 4 of the DispatchIQ build. Creates an encrypted PostgreSQL instance
# in private subnets, with master credentials managed natively by RDS
# (stored in a dedicated Secrets Manager secret, auto-rotated by AWS).
#
# Dev defaults: single-AZ, db.t4g.micro, no final snapshot, no deletion
# protection — supports the destroy/recreate cost pattern.
#
# Prod overrides: set multi_az = true, skip_final_snapshot = false,
# deletion_protection = true, larger instance class.
###############################################################################

locals {
  common_tags = merge(var.tags, {
    Module = "rds"
  })
}

###############################################################################
# DB Subnet Group
#
# RDS requires a subnet group spanning 2+ AZs even for single-AZ deployments.
# AWS uses it to determine eligible AZs for future failover/Multi-AZ promotion.
###############################################################################
resource "aws_db_subnet_group" "main" {
  name        = "${var.project}-${var.environment}-db-subnet-group"
  description = "Private subnet group for ${var.project} ${var.environment} RDS"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-db-subnet-group"
  })
}

###############################################################################
# DB Parameter Group
#
# rds.force_ssl = 1 makes Postgres REFUSE non-TLS connections at the engine
# level. Defense in depth on top of SG and IAM restrictions.
###############################################################################
resource "aws_db_parameter_group" "main" {
  name        = "${var.project}-${var.environment}-pg16"
  family      = "postgres16"
  description = "Custom parameter group for ${var.project} ${var.environment} Postgres 16"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Log queries slower than 1 second — catches N+1 and missing indexes
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Enhanced Monitoring IAM Role
#
# RDS Enhanced Monitoring streams OS-level metrics (CPU, memory, disk I/O)
# to CloudWatch every 60s. More detailed than default RDS metrics.
###############################################################################
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

###############################################################################
# RDS Instance
#
# manage_master_user_password = true is the modern AWS pattern (post-2023).
# RDS generates the master password, stores it in its own Secrets Manager
# secret, and handles rotation natively. The existing module.secrets_manager
# .db_credentials is reserved for the application-level DB user (Phase 5+).
###############################################################################
resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-db"

  # --- Engine ---
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  # --- Storage ---
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  # --- Credentials (RDS-managed) ---
  username                      = var.master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  # --- Networking ---
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  port                   = 5432

  # --- Backups & maintenance ---
  backup_retention_period    = var.backup_retention_period
  backup_window              = "03:00-04:00"
  maintenance_window         = "sun:04:30-sun:05:30"
  copy_tags_to_snapshot      = true
  auto_minor_version_upgrade = true

  # --- Deletion behavior (env-aware) ---
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project}-${var.environment}-db-final-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  deletion_protection       = var.deletion_protection

  # --- High availability ---
  multi_az = var.multi_az

  # --- Observability ---
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = var.kms_key_arn
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_enhanced_monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql"]

  parameter_group_name = aws_db_parameter_group.main.name

  apply_immediately = var.apply_immediately

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-db"
  })

  lifecycle {
    ignore_changes = [
      master_user_secret_kms_key_id,
    ]
  }
}
