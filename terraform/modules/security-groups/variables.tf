variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create security groups in"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for internal traffic rules"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "use_vpc_endpoints" {
  type        = bool
  description = "When true, app egress is scoped to VPC CIDR (assumes Interface Endpoints exist for AWS service access). When false, egress opens to 0.0.0.0/0 for NAT-based AWS API access. Defaults to false for dev cost savings."
  default     = false
}
