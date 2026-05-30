variable "project" {
  type        = string
  description = "Project name for naming and tagging"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the DB subnet group (need 2+ in different AZs)"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for the RDS instance"
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for storage and master-user-secret encryption"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.4"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class. t4g = Graviton ARM (cheaper than t3)"
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 20
}

variable "max_allocated_storage" {
  type        = number
  description = "Upper limit for storage autoscaling"
  default     = 100
}

variable "master_username" {
  type        = string
  description = "Master DB username. AWS manages the password."
  default     = "dbadmin"
}

variable "backup_retention_period" {
  type        = number
  description = "Days to retain automated backups"
  default     = 7
}

variable "multi_az" {
  type        = bool
  description = "Multi-AZ deployment for HA. Doubles cost."
  default     = false
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on destroy. TRUE for dev."
  default     = true
}

variable "deletion_protection" {
  type        = bool
  description = "Block terraform destroy. TRUE for prod."
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Apply changes immediately vs. waiting for maintenance window."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default     = {}
}
