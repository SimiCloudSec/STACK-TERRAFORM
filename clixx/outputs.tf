output "wordpress_url" {
  value = "http://${module.route53.fqdn}"
}

output "alb_dns_name" {
  value = module.alb.alb_dns
}

output "custom_domain" {
  value = module.route53.fqdn
}

output "efs_id" {
  value = module.efs.efs_id
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "environment" {
  value = var.environment
}
