locals {
  key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrail"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  # Dedicated policy for the Secrets Manager KMS key: base statements +
  # explicit grant for the ECS execution role to call kms:Decrypt via Secrets
  # Manager. Required because KMS key policies are authoritative — IAM alone
  # cannot grant decrypt access without the key's resource policy agreeing.
  secrets_key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECSExecutionRoleViaSecretsManager"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:role/${var.project}-${var.environment}-ecs-execution-role"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

# EBS KEY
resource "aws_kms_key" "ebs" {
  description             = "${var.project}-${var.environment} EBS encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = local.key_policy

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-ebs-key"
    Purpose = "ebs-encryption"
  })
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# RDS KEY
resource "aws_kms_key" "rds" {
  description             = "${var.project}-${var.environment} RDS encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = local.key_policy

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-rds-key"
    Purpose = "rds-encryption"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# S3 KEY
resource "aws_kms_key" "s3" {
  description             = "${var.project}-${var.environment} S3 encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = local.key_policy

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-s3-key"
    Purpose = "s3-encryption"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# SECRETS MANAGER KEY
resource "aws_kms_key" "secrets" {
  description             = "${var.project}-${var.environment} Secrets Manager encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  policy                  = local.secrets_key_policy

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-secrets-key"
    Purpose = "secrets-encryption"
  })
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}