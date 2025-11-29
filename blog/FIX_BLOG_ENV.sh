#!/bin/bash
# Quick fix to add environment support (dev.blog.stack-simi.com)

echo "Fixing BLOG for environment support..."

# Update variables.tf - add environment variable
cat >> variables.tf << 'VAREOF'

variable "environment" {
  description = "Environment (dev/test/uat/prod)"
  type        = string
  default     = "dev"
}
VAREOF

# Update terraform.tfvars - add environment
cat >> terraform.tfvars << 'TFVARSEOF'

# Environment
environment = "dev"
TFVARSEOF

# Fix Route53 module
cat > modules/route53/main.tf << 'ROUTE53EOF'
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
ROUTE53EOF

# Update main.tf - add environment to route53 module
sed -i 's/module "route53" {/module "route53" {\n  environment    = var.environment/g' main.tf 2>/dev/null || \
gsed -i 's/module "route53" {/module "route53" {\n  environment    = var.environment/g' main.tf 2>/dev/null || \
echo "Note: Please manually add 'environment = var.environment' to the route53 module in main.tf"

echo ""
echo "✅ Fix complete!"
echo ""
echo "Your blog URL will be: http://dev.blog.stack-simi.com"
echo ""
echo "Run:"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
