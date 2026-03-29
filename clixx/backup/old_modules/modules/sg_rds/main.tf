variable "vpc_id" { type = string }
variable "ec2_sg_id" { type = string }
variable "environment" { type = string }
variable "sg_rds_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

resource "aws_security_group" "rds_sg" {
  name        = "clixx-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_rds_config
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [var.ec2_sg_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-rds-sg" }
}

output "sg_id" { value = aws_security_group.rds_sg.id }
