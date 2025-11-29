# ============================================================
# OUTPUTS - BLOG WordPress Infrastructure
# ============================================================

output "blog_url" {
  description = "Blog URL"
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

output "key_pair_name" {
  description = "EC2 Key Pair name"
  value       = module.keypair.key_name
}

output "private_key_file" {
  description = "Private key file location"
  value       = module.keypair.private_key_path
}
