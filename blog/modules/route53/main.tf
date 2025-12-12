# ============================================================
# ROUTE53 MODULE - BLOG WordPress
# ============================================================

variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
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
