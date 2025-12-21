variable "vpc_id" { type = string }
variable "environment" { type = string }

resource "aws_lb_target_group" "wordpress" {
  name     = "clixx-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200,301,302"
  }

  tags = { Name = "clixx-${var.environment}-tg" }
}

output "tg_arn" { value = aws_lb_target_group.wordpress.arn }
