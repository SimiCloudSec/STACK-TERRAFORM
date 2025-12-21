# =============================================================================
# OUTPUTS - CliXX WordPress
# Author: Simi Talabi
# =============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private Web App Subnet IDs"
  value       = aws_subnet.private_webapp[*].id
}

output "private_mysql_subnet_ids" {
  description = "Private MySQL Subnet IDs"
  value       = aws_subnet.private_mysql[*].id
}

output "private_oracle_subnet_ids" {
  description = "Private Oracle Subnet IDs"
  value       = aws_subnet.private_oracle[*].id
}

output "private_javadb_subnet_ids" {
  description = "Private Java DB Subnet IDs"
  value       = aws_subnet.private_javadb[*].id
}

output "private_javaapp_subnet_ids" {
  description = "Private Java App Subnet IDs"
  value       = aws_subnet.private_javaapp[*].id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "alb_dns_name" {
  description = "ALB DNS Name"
  value       = aws_lb.wordpress.dns_name
}

output "website_url" {
  description = "WordPress Website URL"
  value       = "http://${var.environment}.clixx.${var.domain_name}"
}

output "rds_endpoint" {
  description = "RDS Endpoint"
  value       = aws_db_instance.wordpress.endpoint
}

output "efs_id" {
  description = "EFS File System ID"
  value       = aws_efs_file_system.wordpress.id
}
