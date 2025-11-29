# ============================================================
# ROUTE53 MODULE - BLOG WordPress
# ============================================================

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "environment" {
  description = "Environment (dev/test/uat/prod)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Zone ID"
  type        = string
}

# Creates: dev.blog.stack-simi.com
resource "aws_route53_record" "blog" {
  zone_id = var.hosted_zone_id
  name    = "${var.environment}.blog.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

output "fqdn" {
  value = aws_route53_record.blog.fqdn
}
