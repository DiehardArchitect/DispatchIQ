variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "cloud-platform"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = "975050048256"
}

variable "use_vpc_endpoints" {
  type        = bool
  description = "Toggle for VPC Interface Endpoints + scoped SG egress. False (default) = cheap NAT-based path for dev. True = production-grade private connectivity."
  default     = false
}
