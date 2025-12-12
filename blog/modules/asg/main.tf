# ============================================================
# ASG MODULE - BLOG WordPress
# ============================================================

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "launch_template_id" {
  type = string
}

variable "asg_config" {
  type = object({
    min_size                  = number
    max_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
  })
}

resource "aws_autoscaling_group" "blog_asg" {
  name                      = "blog-${var.environment}-asg"
  min_size                  = var.asg_config.min_size
  max_size                  = var.asg_config.max_size
  desired_capacity          = var.asg_config.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_config.health_check_grace_period

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "blog-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.blog_asg.name
}
