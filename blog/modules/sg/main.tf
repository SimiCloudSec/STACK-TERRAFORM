# ============================================================
# SECURITY GROUP MODULE - BLOG WordPress
# ============================================================

variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "sg_alb_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "sg_ec2_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "sg_rds_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

variable "sg_efs_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "blog-${var.environment}-alb-sg"
  description = "Security group for Blog ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_alb_config
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

  tags = {
    Name = "blog-${var.environment}-alb-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "blog-${var.environment}-ec2-sg"
  description = "Security group for Blog EC2"
  vpc_id      = var.vpc_id

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

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-${var.environment}-ec2-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "blog-${var.environment}-rds-sg"
  description = "Security group for Blog RDS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_rds_config
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [aws_security_group.ec2_sg.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-${var.environment}-rds-sg"
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sg" {
  name        = "blog-${var.environment}-efs-sg"
  description = "Security group for Blog EFS"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_efs_config
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [aws_security_group.ec2_sg.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-${var.environment}-efs-sg"
  }
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "efs_sg_id" {
  value = aws_security_group.efs_sg.id
}
