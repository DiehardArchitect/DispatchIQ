# -------------------------------------------------------
# DATABASE CREDENTIALS SECRET
# Stores RDS credentials — value is a placeholder.
# Real password is set outside Terraform to avoid
# storing secrets in state file.
# -------------------------------------------------------
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project}/${var.environment}/db-credentials"
  description = "RDS database credentials for ${var.project} ${var.environment}"
  kms_key_id  = var.kms_key_arn

  # Secrets are not immediately destroyed — 7 days recovery window
  # Set to 0 in dev for fast teardown cycles
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-db-credentials"
    Purpose = "database-credentials"
  })
}

# Placeholder value — real credentials set manually or via rotation
# NEVER put real credentials in Terraform code
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = "CHANGE_ME_BEFORE_USE"
    engine   = "postgres"
    port     = 5432
  })

  # Ignore changes to secret_string so manual rotations
  # don't get overwritten by terraform apply
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -------------------------------------------------------
# APP SECRET — API keys and third party credentials
# -------------------------------------------------------
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = "${var.project}/${var.environment}/app-secrets"
  description = "Application secrets for ${var.project} ${var.environment}"
  kms_key_id  = var.kms_key_arn

  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-app-secrets"
    Purpose = "application-secrets"
  })
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    placeholder = "REPLACE_WITH_REAL_SECRETS"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}