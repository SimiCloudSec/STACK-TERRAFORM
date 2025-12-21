variable "vpc_id" { type = string }
variable "alb_sg_id" { type = string }
variable "environment" { type = string }
variable "sg_ec2_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "ec2_sg" {
  name        = "clixx-${var.environment}-ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  dynamic "ingress" {
    for_each = var.sg_ec2_config
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-ec2-sg" }
}

output "sg_id" { value = aws_security_group.ec2_sg.id }
