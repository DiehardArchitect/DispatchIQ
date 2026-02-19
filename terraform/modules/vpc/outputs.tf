output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}
output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}
output "public_subnet_ids" {
  description = "IDs of public subnets."
  value       = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  description = "IDs of private subnets."
  value       = aws_subnet.private[*].id
}
output "availability_zones" {
  description = "AZs used by this VPC."
  value       = var.availability_zones
}
output "nat_gateway_ids" {
  description = "IDs of NAT Gateways."
  value       = aws_nat_gateway.main[*].id
}
output "flow_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs."
  value       = aws_cloudwatch_log_group.flow_log.name
}
