variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for key policy"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "deletion_window_in_days" {
  description = "Days before KMS key is deleted after destruction. Min 7, max 30."
  type        = number
  default     = 7  # Dev: 7 days. Production should be 30.
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}