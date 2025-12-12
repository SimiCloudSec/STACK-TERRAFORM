# =============================================================================
# OUTPUTS - CLIXX WordPress with Custom VPC
# =============================================================================

output "wordpress_url" {
  description = "WordPress site URL"
  value       = "http://${module.route53.fqdn}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.efs_id
}

# VPC Outputs
output "vpc_id" {
  description = "Custom VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB)"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EC2, RDS, EFS)"
  value       = local.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "public_nacl_id" {
  description = "Public NACL ID"
  value       = aws_network_acl.public.id
}

output "private_nacl_id" {
  description = "Private NACL ID"
  value       = aws_network_acl.private.id
}
