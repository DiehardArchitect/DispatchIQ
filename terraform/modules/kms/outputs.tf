output "ebs_key_arn" {
  description = "ARN of EBS KMS key"
  value       = aws_kms_key.ebs.arn
}

output "rds_key_arn" {
  description = "ARN of RDS KMS key"
  value       = aws_kms_key.rds.arn
}

output "s3_key_arn" {
  description = "ARN of S3 KMS key"
  value       = aws_kms_key.s3.arn
}

output "secrets_key_arn" {
  description = "ARN of Secrets Manager KMS key"
  value       = aws_kms_key.secrets.arn
}

output "ebs_key_id" {
  description = "ID of EBS KMS key"
  value       = aws_kms_key.ebs.key_id
}

output "rds_key_id" {
  description = "ID of RDS KMS key"
  value       = aws_kms_key.rds.key_id
}

output "s3_key_id" {
  description = "ID of S3 KMS key"
  value       = aws_kms_key.s3.key_id
}

output "secrets_key_id" {
  description = "ID of Secrets Manager KMS key"
  value       = aws_kms_key.secrets.key_id
}

output "ebs_key_alias" {
  description = "Alias of EBS KMS key"
  value       = aws_kms_alias.ebs.name
}

output "rds_key_alias" {
  description = "Alias of RDS KMS key"
  value       = aws_kms_alias.rds.name
}

output "s3_key_alias" {
  description = "Alias of S3 KMS key"
  value       = aws_kms_alias.s3.name
}

output "secrets_key_alias" {
  description = "Alias of Secrets Manager KMS key"
  value       = aws_kms_alias.secrets.name
}