variable "project_name" {
  description = "Name prefix for all resources."
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}
variable "availability_zones" {
  description = "List of AZs to deploy into. Minimum 2 for HA."
  type        = list(string)
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones required."
  }
}
variable "common_tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
