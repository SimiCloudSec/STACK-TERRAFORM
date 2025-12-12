# ============================================================
# EFS MODULE - BLOG WordPress
# ============================================================

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "efs_sg_id" {
  type = string
}

variable "efs_config" {
  type = object({
    encrypted        = bool
    throughput_mode  = string
    performance_mode = string
  })
}

resource "aws_efs_file_system" "blog_efs" {
  creation_token   = "blog-${var.environment}-efs"
  encrypted        = var.efs_config.encrypted
  throughput_mode  = var.efs_config.throughput_mode
  performance_mode = var.efs_config.performance_mode

  tags = {
    Name = "blog-${var.environment}-efs"
  }
}

resource "aws_efs_mount_target" "blog_efs_mt" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.blog_efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

output "efs_id" {
  value = aws_efs_file_system.blog_efs.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.blog_efs.dns_name
}
