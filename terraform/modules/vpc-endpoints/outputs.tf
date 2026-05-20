output "enabled" {
  description = "Whether VPC endpoints are enabled in this deployment"
  value       = var.enabled
}

output "endpoints_security_group_id" {
  description = "Security group ID for the VPC endpoints (null when disabled)"
  value       = var.enabled ? aws_security_group.endpoints[0].id : null
}

output "interface_endpoint_ids" {
  description = "Map of AWS service name → interface endpoint ID"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "s3_endpoint_id" {
  description = "S3 gateway endpoint ID (null when disabled)"
  value       = var.enabled ? aws_vpc_endpoint.s3[0].id : null
}
