output "website_url" { value = "http://${var.environment}.blog.${var.domain_name}" }
output "alb_dns_name" { value = aws_lb.wordpress.dns_name }
output "rds_endpoint" { value = aws_db_instance.wordpress.endpoint }
output "efs_id" { value = aws_efs_file_system.wordpress.id }
output "vpc_id" { value = aws_vpc.main.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
