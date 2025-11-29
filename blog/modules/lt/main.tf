# ============================================================
# LAUNCH TEMPLATE MODULE - BLOG WordPress
# ============================================================

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "ec2_sg_id" {
  description = "EC2 Security Group ID"
  type        = string
}

variable "efs_id" {
  description = "EFS ID"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_pass" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "site_url" {
  description = "WordPress site URL"
  type        = string
}

resource "aws_launch_template" "blog_lt" {
  name_prefix   = "blog-wordpress-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(templatefile("${path.root}/scripts/blog_bootstrap.sh", {
    efs_id   = var.efs_id
    db_host  = var.db_host
    db_name  = var.db_name
    db_user  = var.db_user
    db_pass  = var.db_pass
    site_url = var.site_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "blog-wordpress-instance"
    }
  }
}

output "lt_id" {
  value = aws_launch_template.blog_lt.id
}
