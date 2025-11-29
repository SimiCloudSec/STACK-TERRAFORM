variable "subnet_ids" { type = list(string) }
variable "target_group_arn" { type = string }
variable "launch_template_id" { type = string }
variable "environment" { type = string }
variable "asg_config" { type = map(number) }

resource "aws_autoscaling_group" "wordpress" {
  name                      = "clixx-${var.environment}-asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_config["health_check_grace_period"]
  min_size                  = var.asg_config["min_size"]
  max_size                  = var.asg_config["max_size"]
  desired_capacity          = var.asg_config["desired_capacity"]

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "clixx-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}
