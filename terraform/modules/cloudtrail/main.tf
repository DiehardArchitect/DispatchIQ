# -------------------------------------------------------
# S3 BUCKET FOR CLOUDTRAIL LOGS
# CloudTrail requires a specific bucket policy to allow
# it to write logs — without this, CloudTrail will fail
# -------------------------------------------------------
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project}-${var.environment}-cloudtrail-${var.aws_account_id}"
  force_destroy = true # Dev only — allows bucket deletion even with logs inside

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-cloudtrail"
    Purpose = "cloudtrail-logs"
  })
}

# Block all public access — audit logs must never be public
resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encrypt all objects with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true # Reduces KMS API costs by caching the key
  }
}

# CloudTrail requires explicit bucket policy permission to write logs
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.aws_account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# -------------------------------------------------------
# CLOUDTRAIL
# Multi-region trail captures ALL API calls across
# every region — not just us-east-1
# -------------------------------------------------------
resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-${var.environment}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail.id
  kms_key_id                    = var.kms_key_arn
  include_global_service_events = true  # Captures IAM, STS, Route53
  is_multi_region_trail         = true  # Captures events in ALL regions
  enable_log_file_validation    = true  # Detects log tampering via hash chain

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-trail"
    Purpose = "api-audit-logging"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}