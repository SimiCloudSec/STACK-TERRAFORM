# ============================================================
# ALB MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

resource "aws_lb" "blog_alb" {
  name               = "blog-wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "blog-wordpress-alb"
  }
}

output "alb_arn" {
  value = aws_lb.blog_alb.arn
}

output "alb_dns" {
  value = aws_lb.blog_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.blog_alb.zone_id
}
