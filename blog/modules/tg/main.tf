# ============================================================
# TARGET GROUP MODULE - BLOG WordPress
# ============================================================

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

resource "aws_lb_target_group" "blog_tg" {
  name     = "blog-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health.html"
    matcher             = "200"
  }

  tags = {
    Name = "blog-wordpress-tg"
  }
}

output "tg_arn" {
  value = aws_lb_target_group.blog_tg.arn
}
