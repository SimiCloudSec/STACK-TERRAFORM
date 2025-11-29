variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "vpc_id" { type = string }
variable "environment" { type = string }

resource "aws_lb" "wordpress" {
  name               = "clixx-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
  tags               = { Name = "clixx-${var.environment}-alb" }
}

output "alb_arn" { value = aws_lb.wordpress.arn }
output "alb_dns" { value = aws_lb.wordpress.dns_name }
output "alb_zone_id" { value = aws_lb.wordpress.zone_id }
