# ============================================================
# LAUNCH TEMPLATE MODULE - BLOG WordPress
# ============================================================

variable "environment" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ec2_config" {
  type = object({
    instance_type     = string
    volume_size       = number
    volume_type       = string
    key_name          = string
    enable_monitoring = bool
  })
}

variable "ec2_sg_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "efs_id" {
  type = string
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_pass" {
  type      = string
  sensitive = true
}

variable "site_url" {
  type = string
}

resource "aws_launch_template" "blog_lt" {
  name_prefix   = "blog-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.ec2_config.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.ec2_sg_id]

  monitoring {
    enabled = var.ec2_config.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ec2_config.volume_size
      volume_type = var.ec2_config.volume_type
    }
  }

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
      Name = "blog-${var.environment}-instance"
    }
  }
}

output "lt_id" {
  value = aws_launch_template.blog_lt.id
}
