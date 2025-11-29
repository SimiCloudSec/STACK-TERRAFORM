# ============================================================
# EFS MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "EFS Security Group ID"
  type        = string
}

resource "aws_efs_file_system" "blog_efs" {
  creation_token = "blog-wordpress-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "blog-wordpress-efs"
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
