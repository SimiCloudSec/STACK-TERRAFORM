# ============================================================
# AUTO SCALING GROUP MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN"
  type        = string
}

variable "launch_template_id" {
  description = "Launch template ID"
  type        = string
}

variable "min_size" {
  description = "Minimum size"
  type        = number
}

variable "max_size" {
  description = "Maximum size"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity"
  type        = number
}

resource "aws_autoscaling_group" "blog_asg" {
  name                      = "blog-wordpress-asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "blog-wordpress-asg-instance"
    propagate_at_launch = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.blog_asg.name
}
