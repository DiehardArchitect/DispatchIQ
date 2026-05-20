variable "enabled" {
  type        = bool
  description = "When true, deploys VPC Interface Endpoints + S3 gateway endpoint. When false, the module creates zero resources."
  default     = false
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming and tagging"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "region" {
  type        = string
  description = "AWS region for the endpoints (e.g., us-east-1)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where endpoints will be created"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs where interface endpoint ENIs are placed (one ENI per subnet)"
}

variable "private_route_table_ids" {
  type        = list(string)
  description = "Private route table IDs for the S3 gateway endpoint route entries"
}

variable "app_security_group_id" {
  type        = string
  description = "Application security group ID — endpoints accept 443 ingress from this SG"
}
