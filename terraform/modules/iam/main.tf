# -------------------------------------------------------
# EC2 INSTANCE ROLE
# Allows EC2 instances to assume this role via IMDS
# -------------------------------------------------------
resource "aws_iam_role" "ec2_instance" {
  name = "${var.project}-${var.environment}-ec2-role"

  # Trust policy — defines WHO can assume this role
  # Only EC2 service can assume it, not users or other services
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ec2-role"
  })
}

# -------------------------------------------------------
# AWS MANAGED POLICIES — attached directly to the role
# These are maintained by AWS and updated automatically
# -------------------------------------------------------

# SSM — enables Session Manager, no SSH needed
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent — allows instance to ship metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# -------------------------------------------------------
# CUSTOM KMS POLICY — least privilege KMS access
# Only allows usage operations, not key administration
# -------------------------------------------------------
resource "aws_iam_role_policy" "kms_access" {
  name = "${var.project}-${var.environment}-ec2-kms-policy"
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKMSUsage"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        # Scoped to only the keys passed in — not all KMS keys
        Resource = length(var.kms_key_arns) > 0 ? var.kms_key_arns : ["*"]
      }
    ]
  })
}

# -------------------------------------------------------
# INSTANCE PROFILE
# The container that attaches the IAM role to an EC2 instance
# EC2 doesn't attach roles directly — it uses instance profiles
# -------------------------------------------------------
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_instance.name

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ec2-profile"
  })
}