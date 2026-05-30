output "db_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "endpoint" {
  description = "DB connection endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "address" {
  description = "DB hostname (no port)"
  value       = aws_db_instance.main.address
}

output "port" {
  description = "DB port"
  value       = aws_db_instance.main.port
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager secret containing master credentials. For admin/migration use only — apps should use a less-privileged DB user (Phase 5+)."
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "parameter_group_name" {
  description = "Parameter group name"
  value       = aws_db_parameter_group.main.name
}
